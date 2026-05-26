//
//  NotificationScheduler.swift
//  MathGame — Data
//
//  Local notifications: streak-reminder at 19:00 local time if the user has a
//  current streak and hasn't completed today's Daily yet. We never spam — only
//  one pending notification at a time.
//

import Foundation
import UserNotifications

@MainActor
enum NotificationScheduler {

    static let streakReminderID = "math.streak.reminder"

    /// Asks for permission. Call only after the user has finished onboarding
    /// AND played at least one Daily — never on first launch.
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Schedule today's streak reminder. Idempotent — re-running cancels and re-schedules.
    static func scheduleStreakReminder(currentStreak: Int, alreadyCompletedToday: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [streakReminderID])
        guard currentStreak > 0, !alreadyCompletedToday else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.streak.title")
        content.body = String(localized: "notification.streak.body.\(currentStreak)")
        content.sound = .default

        // Daily reminder at 19:00 local.
        var components = DateComponents()
        components.hour = 19
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let req = UNNotificationRequest(identifier: streakReminderID, content: content, trigger: trigger)
        center.add(req) { _ in }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
