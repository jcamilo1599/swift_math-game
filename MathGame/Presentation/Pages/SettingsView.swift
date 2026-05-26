//
//  SettingsView.swift
//  MathGame — Presentation/Pages
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    let player: Player

    var body: some View {
        Form {
            Section("settings.audio_haptics") {
                Toggle("settings.sound", isOn: Binding(
                    get: { player.soundEnabled },
                    set: { newValue in
                        player.soundEnabled = newValue
                        AudioEngine.shared.setEnabled(newValue)
                        try? modelContext.save()
                    }
                ))
                Toggle("settings.haptics", isOn: Binding(
                    get: { player.hapticsEnabled },
                    set: { newValue in
                        player.hapticsEnabled = newValue
                        HapticEngine.shared.setEnabled(newValue)
                        try? modelContext.save()
                    }
                ))
            }

            Section("settings.notifications") {
                Toggle("settings.streak_reminder", isOn: Binding(
                    get: { player.notificationsEnabled },
                    set: { newValue in
                        player.notificationsEnabled = newValue
                        try? modelContext.save()
                        if newValue {
                            Task {
                                let granted = await NotificationScheduler.requestAuthorization()
                                if granted {
                                    NotificationScheduler.scheduleStreakReminder(
                                        currentStreak: player.currentStreak,
                                        alreadyCompletedToday: Calendar.current.isDateInToday(player.lastDailyCompletedOn ?? .distantPast)
                                    )
                                }
                            }
                        } else {
                            NotificationScheduler.cancelAll()
                        }
                    }
                ))
            }

            Section("settings.about") {
                LabeledContent("settings.version", value: AppInfo.versionString)
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    Label("settings.privacy", systemImage: "hand.raised")
                }
                Link(destination: URL(string: "mailto:support@example.com")!) {
                    Label("settings.support", systemImage: "envelope")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("nav.settings")
        .toolbarBackground(Color.appBackground, for: .navigationBar)
    }
}

enum AppInfo {
    static var versionString: String {
        let dict = Bundle.main.infoDictionary
        let v = dict?["CFBundleShortVersionString"] as? String ?? "?"
        let b = dict?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}
