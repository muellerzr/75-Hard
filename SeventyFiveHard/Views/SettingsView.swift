//
//  SettingsView.swift
//  SeventyFiveHard
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query(sort: \DayProgress.dayNumber) private var allProgress: [DayProgress]

    @State private var showingResetAlert = false
    @State private var showingDayEndPicker = false
    @State private var tempHour: Int = 0
    @State private var tempMinute: Int = 0

    private var userSettings: UserSettings? {
        settings.first
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Challenge Info") {
                    if let settings = userSettings {
                        HStack {
                            Text("Start Date")
                            Spacer()
                            Text(settings.startDate, style: .date)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Day Ends At")
                            Spacer()
                            Button(settings.formattedDayEndTime()) {
                                tempHour = settings.dayEndHour
                                tempMinute = settings.dayEndMinute
                                showingDayEndPicker = true
                            }
                            .foregroundStyle(.orange)
                        }

                        HStack {
                            Text("Current Day")
                            Spacer()
                            Text("Day \(settings.getCurrentDayNumber())")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Statistics") {
                    let completedDays = allProgress.filter { $0.isComplete }.count
                    let totalTasks = allProgress.reduce(0) { $0 + $1.completedTasksCount }

                    HStack {
                        Text("Days Completed")
                        Spacer()
                        Text("\(completedDays) / 75")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Total Tasks Completed")
                        Spacer()
                        Text("\(totalTasks)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Progress Photos")
                        Spacer()
                        Text("\(allProgress.filter { $0.progressPictureTaken }.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundStyle(.green)
                        Text("Fully Offline")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset Challenge")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Challenge?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetChallenge()
                }
            } message: {
                Text("This will delete all your progress and start over. This cannot be undone.")
            }
            .sheet(isPresented: $showingDayEndPicker) {
                dayEndPickerSheet
            }
        }
    }

    private var dayEndPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("When does your day end?")
                    .font(.headline)

                HStack(spacing: 0) {
                    Picker("Hour", selection: $tempHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)

                    Text(":")
                        .font(.title)
                        .fontWeight(.bold)

                    Picker("Minute", selection: $tempMinute) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)

                    Text(tempHour < 12 ? "AM" : "PM")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(width: 50)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Day End Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingDayEndPicker = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        userSettings?.dayEndHour = tempHour
                        userSettings?.dayEndMinute = tempMinute
                        showingDayEndPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func formatHour(_ hour: Int) -> String {
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return "\(displayHour)"
    }

    private func resetChallenge() {
        // Delete all progress
        for progress in allProgress {
            modelContext.delete(progress)
        }

        // Delete settings to trigger onboarding
        for setting in settings {
            modelContext.delete(setting)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserSettings.self, DayProgress.self], inMemory: true)
}
