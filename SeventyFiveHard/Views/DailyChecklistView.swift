//
//  DailyChecklistView.swift
//  SeventyFiveHard
//

import SwiftUI
import SwiftData

struct DailyChecklistView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query(sort: \DayProgress.dayNumber) private var allProgress: [DayProgress]

    @State private var showingCamera = false
    @State private var showingFailure = false
    @State private var failedDayNumber: Int = 0

    private var currentDayNumber: Int {
        settings.first?.getCurrentDayNumber() ?? 1
    }

    private var todayProgress: DayProgress? {
        allProgress.first { $0.dayNumber == currentDayNumber }
    }

    /// Checks if any previous day was incomplete (missed)
    private func checkForMissedDays() -> Int? {
        // Only check days before today
        for dayNum in 1..<currentDayNumber {
            let progress = allProgress.first { $0.dayNumber == dayNum }
            // If no progress record exists or day is incomplete, it's a failure
            if progress == nil || !progress!.isComplete {
                return dayNum
            }
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Day header
                    dayHeader

                    // Progress ring
                    progressRing

                    // Task checklist
                    taskChecklist

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("75 Hard")
            .onAppear {
                ensureTodayProgressExists()
                // Check for missed days
                if let missedDay = checkForMissedDays() {
                    failedDayNumber = missedDay
                    showingFailure = true
                }
            }
            .fullScreenCover(isPresented: $showingFailure) {
                FailureView(failedDay: failedDayNumber) {
                    restartChallenge()
                }
            }
        }
    }

    private func restartChallenge() {
        // Delete all progress records
        for progress in allProgress {
            modelContext.delete(progress)
        }
        // Reset start date to today
        settings.first?.restartChallenge()
        // Create new Day 1
        let newDay1 = DayProgress(dayNumber: 1)
        modelContext.insert(newDay1)
        showingFailure = false
    }

    private var dayHeader: some View {
        VStack(spacing: 8) {
            Text("Day \(currentDayNumber)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("of 75")
                .font(.title3)
                .foregroundStyle(.secondary)

            if let endTime = settings.first?.formattedDayEndTime() {
                Text("Day ends at \(endTime)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.top)
    }

    private var progressRing: some View {
        let completed = todayProgress?.completedTasksCount ?? 0
        let total = DayProgress.totalTasks
        let progress = Double(completed) / Double(total)

        return ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    todayProgress?.isComplete == true ? Color.green : Color.orange,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)

            VStack {
                Text("\(completed)/\(total)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("Tasks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 120, height: 120)
        .padding()
    }

    private var taskChecklist: some View {
        VStack(spacing: 12) {
            TaskRow(
                icon: "figure.run",
                title: "45-Minute Workout",
                subtitle: "Any workout for 45 minutes",
                isCompleted: todayProgress?.workout1Completed ?? false,
                onComplete: { todayProgress?.workout1Completed = true }
            )

            TaskRow(
                icon: "sun.max.fill",
                title: "Outdoor Workout",
                subtitle: "45 minutes outside",
                isCompleted: todayProgress?.workout2OutdoorCompleted ?? false,
                onComplete: { todayProgress?.workout2OutdoorCompleted = true }
            )

            TaskRow(
                icon: "camera.fill",
                title: "Progress Picture",
                subtitle: "Take a daily photo",
                isCompleted: todayProgress?.progressPictureTaken ?? false,
                onComplete: { showingCamera = true }
            )

            TaskRow(
                icon: "book.fill",
                title: "Read 10 Pages",
                subtitle: "Non-fiction reading",
                isCompleted: todayProgress?.readingCompleted ?? false,
                onComplete: { todayProgress?.readingCompleted = true }
            )

            TaskRow(
                icon: "drop.fill",
                title: "Drink 1 Gallon",
                subtitle: "Water intake",
                isCompleted: todayProgress?.waterCompleted ?? false,
                onComplete: { todayProgress?.waterCompleted = true }
            )

            TaskRow(
                icon: "fork.knife",
                title: "Follow Diet",
                subtitle: "Stick to your diet plan",
                isCompleted: todayProgress?.dietFollowed ?? false,
                onComplete: { todayProgress?.dietFollowed = true }
            )

            TaskRow(
                icon: "xmark.circle.fill",
                title: "No Cheats or Alcohol",
                subtitle: "Stay disciplined",
                isCompleted: todayProgress?.noCheatMealsOrAlcohol ?? false,
                onComplete: { todayProgress?.noCheatMealsOrAlcohol = true }
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .sheet(isPresented: $showingCamera) {
            CameraView(dayProgress: todayProgress)
        }
    }

    private func ensureTodayProgressExists() {
        if todayProgress == nil {
            let newProgress = DayProgress(dayNumber: currentDayNumber)
            modelContext.insert(newProgress)
        }
    }
}

struct TaskRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isCompleted: Bool
    let onComplete: () -> Void

    var body: some View {
        Button(action: {
            if !isCompleted {
                withAnimation(.spring(response: 0.3)) {
                    onComplete()
                }
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : .orange)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(isCompleted ? .secondary : .primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(isCompleted ? .green : Color(.systemGray3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCompleted ? Color.green.opacity(0.1) : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .disabled(isCompleted)
    }
}

struct FailureView: View {
    let failedDay: Int
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.red)

            Text("Challenge Failed")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("You didn't complete all tasks on Day \(failedDay).")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("In 75 Hard, if you miss a day, you must start over from Day 1. No exceptions.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 16) {
                Button(action: onRestart) {
                    Text("Restart Challenge")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .cornerRadius(12)
                }

                Text("Your progress will be reset to Day 1")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
}

#Preview {
    DailyChecklistView()
        .modelContainer(for: [UserSettings.self, DayProgress.self], inMemory: true)
}

#Preview("Failure View") {
    FailureView(failedDay: 3) { }
}
