//
//  UserSettings.swift
//  SeventyFiveHard
//

import Foundation
import SwiftData

@Model
final class UserSettings {
    var startDate: Date
    var dayEndHour: Int // 0-23, hour when the day "ends" (e.g., 1 for 1am)
    var dayEndMinute: Int // 0-59
    var hasCompletedOnboarding: Bool

    init(startDate: Date = Date(), dayEndHour: Int = 0, dayEndMinute: Int = 0, hasCompletedOnboarding: Bool = false) {
        self.startDate = startDate
        self.dayEndHour = dayEndHour
        self.dayEndMinute = dayEndMinute
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    /// Returns the current challenge day number (1-75) based on start date and day end time
    func getCurrentDayNumber() -> Int {
        let calendar = Calendar.current
        let now = Date()

        // Create the day end time for today
        var adjustedNow = now
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        // If current time is before the day end time, we're still on "yesterday"
        if currentHour < dayEndHour || (currentHour == dayEndHour && currentMinute < dayEndMinute) {
            adjustedNow = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        }

        // Calculate days since start
        let startOfStartDay = calendar.startOfDay(for: startDate)
        let startOfCurrentDay = calendar.startOfDay(for: adjustedNow)

        let components = calendar.dateComponents([.day], from: startOfStartDay, to: startOfCurrentDay)
        let dayNumber = (components.day ?? 0) + 1

        return max(1, min(dayNumber, 75))
    }

    /// Returns formatted day end time string
    func formattedDayEndTime() -> String {
        let hour = dayEndHour % 12 == 0 ? 12 : dayEndHour % 12
        let period = dayEndHour < 12 ? "AM" : "PM"
        if dayEndMinute == 0 {
            return "\(hour):00 \(period)"
        }
        return String(format: "%d:%02d %@", hour, dayEndMinute, period)
    }

    /// Resets the challenge to start fresh from today
    func restartChallenge() {
        startDate = Date()
    }
}
