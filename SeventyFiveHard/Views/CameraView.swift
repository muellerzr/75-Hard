//
//  CameraView.swift
//  SeventyFiveHard
//

import SwiftUI
import Photos

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    var dayProgress: DayProgress?

    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var showingSaveSuccess = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .cornerRadius(16)
                        .padding()

                    Button(action: savePhoto) {
                        Label("Save to 75 Hard Album", systemImage: "square.and.arrow.down")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Button(action: { capturedImage = nil }) {
                        Text("Retake")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.orange)

                    Text("Day \(dayProgress?.dayNumber ?? 1) Progress Photo")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Take a photo to track your physical progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()

                    VStack(spacing: 16) {
                        Button(action: { showingCamera = true }) {
                            Label("Take Photo", systemImage: "camera")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.orange)
                                .cornerRadius(12)
                        }

                        Button(action: { showingImagePicker = true }) {
                            Label("Choose from Library", systemImage: "photo.on.rectangle")
                                .font(.headline)
                                .foregroundStyle(.orange)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Progress Picture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePickerCamera(image: $capturedImage)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerLibrary(image: $capturedImage)
            }
            .alert("Photo Saved!", isPresented: $showingSaveSuccess) {
                Button("Done") {
                    dayProgress?.progressPictureTaken = true
                    dismiss()
                }
            } message: {
                Text("Your progress photo has been saved to the 75 Hard album in your photo library.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }

    private func savePhoto() {
        guard let image = capturedImage else { return }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    errorMessage = "Please allow photo library access in Settings to save progress photos."
                    showingError = true
                }
                return
            }

            saveImageToAlbum(image)
        }
    }

    private func saveImageToAlbum(_ image: UIImage) {
        let albumName = "75 Hard"

        // Find or create the album
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        if let album = collections.firstObject {
            // Album exists, save to it
            saveImage(image, to: album)
        } else {
            // Create album
            var albumPlaceholder: PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }) { success, error in
                if success, let placeholder = albumPlaceholder {
                    let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                    if let album = fetchResult.firstObject {
                        saveImage(image, to: album)
                    }
                } else {
                    DispatchQueue.main.async {
                        errorMessage = "Could not create photo album: \(error?.localizedDescription ?? "Unknown error")"
                        showingError = true
                    }
                }
            }
        }
    }

    private func saveImage(_ image: UIImage, to album: PHAssetCollection) {
        var assetIdentifier: String?

        PHPhotoLibrary.shared().performChanges({
            let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            guard let placeholder = assetRequest.placeholderForCreatedAsset,
                  let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else {
                return
            }
            assetIdentifier = placeholder.localIdentifier
            let enumeration: NSArray = [placeholder]
            albumChangeRequest.addAssets(enumeration)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    dayProgress?.photoAssetIdentifier = assetIdentifier
                    showingSaveSuccess = true
                } else {
                    errorMessage = "Could not save photo: \(error?.localizedDescription ?? "Unknown error")"
                    showingError = true
                }
            }
        }
    }
}

// Camera picker
struct ImagePickerCamera: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerCamera

        init(_ parent: ImagePickerCamera) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Library picker
struct ImagePickerLibrary: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerLibrary

        init(_ parent: ImagePickerLibrary) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    CameraView(dayProgress: nil)
}
