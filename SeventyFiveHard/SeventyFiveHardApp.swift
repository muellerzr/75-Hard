//
//  SeventyFiveHardApp.swift
//  SeventyFiveHard
//
//  75 Hard Challenge Tracker - Fully Offline
//

import SwiftUI
import SwiftData

@main
struct SeventyFiveHardApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserSettings.self,
            DayProgress.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
