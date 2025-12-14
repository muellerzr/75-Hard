//
//  MainTabView.swift
//  SeventyFiveHard
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DailyChecklistView()
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle.fill")
                }

            ProgressHistoryView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.orange)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [UserSettings.self, DayProgress.self], inMemory: true)
}
