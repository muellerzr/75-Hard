//
//  DayProgress.swift
//  SeventyFiveHard
//

import Foundation
import SwiftData

@Model
final class DayProgress {
    var dayNumber: Int
    var date: Date

    // Task completions
    var workout1Completed: Bool
    var workout2OutdoorCompleted: Bool
    var progressPictureTaken: Bool
    var readingCompleted: Bool
    var waterCompleted: Bool
    var dietFollowed: Bool
    var noCheatMealsOrAlcohol: Bool

    // Photo asset identifier for retrieving from photo library
    var photoAssetIdentifier: String?

    init(dayNumber: Int, date: Date = Date()) {
        self.dayNumber = dayNumber
        self.date = date
        self.workout1Completed = false
        self.workout2OutdoorCompleted = false
        self.progressPictureTaken = false
        self.readingCompleted = false
        self.waterCompleted = false
        self.dietFollowed = false
        self.noCheatMealsOrAlcohol = false
        self.photoAssetIdentifier = nil
    }

    var isComplete: Bool {
        workout1Completed &&
        workout2OutdoorCompleted &&
        progressPictureTaken &&
        readingCompleted &&
        waterCompleted &&
        dietFollowed &&
        noCheatMealsOrAlcohol
    }

    var completedTasksCount: Int {
        var count = 0
        if workout1Completed { count += 1 }
        if workout2OutdoorCompleted { count += 1 }
        if progressPictureTaken { count += 1 }
        if readingCompleted { count += 1 }
        if waterCompleted { count += 1 }
        if dietFollowed { count += 1 }
        if noCheatMealsOrAlcohol { count += 1 }
        return count
    }

    static let totalTasks = 7
}
