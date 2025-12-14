//
//  OnboardingView.swift
//  SeventyFiveHard
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedHour: Int = 0
    @State private var selectedMinute: Int = 0
    @State private var startDate: Date = Date()
    @State private var currentPage: Int = 0

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                // Welcome page
                welcomePage
                    .tag(0)

                // Rules page
                rulesPage
                    .tag(1)

                // Day end time page
                dayEndTimePage
                    .tag(2)

                // Start date page
                startDatePage
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            Text("75 Hard")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("The ultimate mental toughness program")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Text("Swipe to continue")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
                .frame(height: 50)
        }
        .padding()
    }

    private var rulesPage: some View {
        VStack(spacing: 20) {
            Text("Daily Requirements")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 40)

            VStack(alignment: .leading, spacing: 16) {
                ruleRow(icon: "figure.run", text: "45-minute workout")
                ruleRow(icon: "sun.max.fill", text: "45-minute outdoor workout")
                ruleRow(icon: "camera.fill", text: "Take a progress picture")
                ruleRow(icon: "book.fill", text: "Read 10 pages of non-fiction")
                ruleRow(icon: "drop.fill", text: "Drink 1 gallon of water")
                ruleRow(icon: "fork.knife", text: "Follow your diet")
                ruleRow(icon: "xmark.circle.fill", text: "No cheat meals or alcohol")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal)

            Spacer()

            Text("Complete ALL tasks for 75 days straight")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 50)
        }
    }

    private func ruleRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 30)

            Text(text)
                .font(.body)

            Spacer()
        }
    }

    private var dayEndTimePage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundStyle(.indigo)

            Text("When does your day end?")
                .font(.title2)
                .fontWeight(.bold)

            Text("If you set 1:00 AM, tasks from the previous calendar day can be completed until 1:00 AM")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            HStack(spacing: 0) {
                Picker("Hour", selection: $selectedHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100)

                Text(":")
                    .font(.title)
                    .fontWeight(.bold)

                Picker("Minute", selection: $selectedMinute) {
                    ForEach([0, 15, 30, 45], id: \.self) { minute in
                        Text(String(format: "%02d", minute)).tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)

                Text(selectedHour < 12 ? "AM" : "PM")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(width: 50)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)

            Spacer()
            Spacer()
        }
        .padding()
    }

    private var startDatePage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("When do you start?")
                .font(.title2)
                .fontWeight(.bold)

            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)

            Button(action: completeOnboarding) {
                Text("Begin 75 Hard")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)

            Spacer()
                .frame(height: 50)
        }
        .padding()
    }

    private func formatHour(_ hour: Int) -> String {
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return "\(displayHour)"
    }

    private func completeOnboarding() {
        let settings = UserSettings(
            startDate: startDate,
            dayEndHour: selectedHour,
            dayEndMinute: selectedMinute,
            hasCompletedOnboarding: true
        )
        modelContext.insert(settings)

        // Create day 1 progress
        let day1 = DayProgress(dayNumber: 1, date: startDate)
        modelContext.insert(day1)
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserSettings.self, DayProgress.self], inMemory: true)
}
