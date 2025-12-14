//
//  ProgressHistoryView.swift
//  SeventyFiveHard
//

import SwiftUI
import SwiftData
import Photos

struct ProgressHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayProgress.dayNumber) private var allProgress: [DayProgress]
    @Query private var settings: [UserSettings]

    @State private var selectedDay: Int? = nil
    @State private var selectedDayImage: UIImage? = nil
    @State private var showingPhotoDetail = false

    private var currentDayNumber: Int {
        settings.first?.getCurrentDayNumber() ?? 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current day display
                    currentDayHeader

                    // Calendar grid
                    calendarSection

                    Text("Tap a completed day to view its photo")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Journey")
            .sheet(isPresented: $showingPhotoDetail) {
                PhotoDetailView(dayNumber: selectedDay ?? 1, image: selectedDayImage)
            }
        }
    }

    private var currentDayHeader: some View {
        VStack(spacing: 8) {
            Text("Day")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("\(currentDayNumber)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)

            Text("of 75")
                .font(.title3)
                .foregroundStyle(.secondary)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * CGFloat(currentDayNumber - 1) / 75.0, height: 12)
                }
            }
            .frame(height: 12)
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(1...75, id: \.self) { day in
                    DayCell(
                        day: day,
                        progress: allProgress.first { $0.dayNumber == day },
                        isCurrentDay: day == currentDayNumber,
                        isFutureDay: day > currentDayNumber
                    )
                    .onTapGesture {
                        if day <= currentDayNumber, let progress = allProgress.first(where: { $0.dayNumber == day }), progress.progressPictureTaken {
                            selectedDay = day
                            loadPhotoForDay(day)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }

    private func loadPhotoForDay(_ day: Int) {
        guard let progress = allProgress.first(where: { $0.dayNumber == day }),
              let assetId = progress.photoAssetIdentifier else {
            selectedDayImage = nil
            showingPhotoDetail = true
            return
        }

        // Request read permission
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    selectedDayImage = nil
                    showingPhotoDetail = true
                }
                return
            }

            // Fetch the specific asset by identifier
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)

            guard let asset = assets.firstObject else {
                DispatchQueue.main.async {
                    selectedDayImage = nil
                    showingPhotoDetail = true
                }
                return
            }

            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true

            var loadedImage: UIImage?
            manager.requestImage(for: asset, targetSize: CGSize(width: 1024, height: 1024), contentMode: .aspectFit, options: options) { image, _ in
                loadedImage = image
            }

            DispatchQueue.main.async {
                selectedDayImage = loadedImage
                showingPhotoDetail = true
            }
        }
    }
}

struct PhotoDetailView: View {
    let dayNumber: Int
    let image: UIImage?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No photo found")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Day \(dayNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct DayCell: View {
    let day: Int
    let progress: DayProgress?
    let isCurrentDay: Bool
    let isFutureDay: Bool

    var body: some View {
        ZStack {
            if isCurrentDay {
                Circle()
                    .stroke(Color.orange, lineWidth: 2)
            }

            Circle()
                .fill(backgroundColor)

            Text("\(day)")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(textColor)
        }
        .frame(height: 36)
    }

    private var backgroundColor: Color {
        if isFutureDay {
            return Color(.systemGray5)
        }
        if let progress = progress, progress.isComplete {
            return .green
        }
        if isCurrentDay {
            return Color(.systemBackground)
        }
        return Color(.systemGray4)
    }

    private var textColor: Color {
        if isFutureDay {
            return .secondary
        }
        if let progress = progress, progress.isComplete {
            return .white
        }
        return .primary
    }
}

#Preview {
    ProgressHistoryView()
        .modelContainer(for: [UserSettings.self, DayProgress.self], inMemory: true)
}
