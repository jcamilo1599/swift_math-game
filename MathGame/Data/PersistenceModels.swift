//
//  PersistenceModels.swift
//  MathGame — Data
//
//  SwiftData @Model types persisted on-device. The Player singleton is the
//  single source of truth for XP, streak, coins, etc.
//

import Foundation
import SwiftData

@Model
final class Player {
    /// There is exactly one Player record on disk; this guards against duplicates.
    @Attribute(.unique) var slot: Int

    var totalXP: Int
    var coins: Int

    var currentStreak: Int
    var longestStreak: Int
    /// Calendar day (start of day in user's current timezone) of the last completed Daily.
    var lastDailyCompletedOn: Date?

    /// Bitmask of unlocked theme IDs by string, e.g. ["default", "neon", "sunset"].
    var unlockedThemes: [String]
    var preferredTheme: String

    /// When true, the user has finished onboarding and we don't show it again.
    var didCompleteOnboarding: Bool

    /// Settings the user controls (mirrored in @AppStorage too, but persisted here for cross-device sync later).
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var notificationsEnabled: Bool

    @Relationship(deleteRule: .cascade)
    var bestScores: [BestScore] = []

    @Relationship(deleteRule: .cascade)
    var achievements: [AchievementProgress] = []

    @Relationship(deleteRule: .cascade)
    var dailyRuns: [DailyChallengeRun] = []

    init(
        slot: Int = 0,
        totalXP: Int = 0,
        coins: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastDailyCompletedOn: Date? = nil,
        unlockedThemes: [String] = ["default"],
        preferredTheme: String = "default",
        didCompleteOnboarding: Bool = false,
        soundEnabled: Bool = true,
        hapticsEnabled: Bool = true,
        notificationsEnabled: Bool = false
    ) {
        self.slot = slot
        self.totalXP = totalXP
        self.coins = coins
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastDailyCompletedOn = lastDailyCompletedOn
        self.unlockedThemes = unlockedThemes
        self.preferredTheme = preferredTheme
        self.didCompleteOnboarding = didCompleteOnboarding
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.notificationsEnabled = notificationsEnabled
    }

    // MARK: - Derived

    var level: Int { XPCurve.level(forXP: totalXP) }

    var xpProgress: (current: Int, next: Int) { XPCurve.progress(forXP: totalXP) }

    var fractionToNextLevel: Double {
        let p = xpProgress
        guard p.next > 0 else { return 0 }
        return min(1.0, Double(p.current) / Double(p.next))
    }
}

@Model
final class BestScore {
    @Attribute(.unique) var modeKey: String
    var score: Int
    var date: Date

    init(modeKey: String, score: Int, date: Date) {
        self.modeKey = modeKey
        self.score = score
        self.date = date
    }
}

@Model
final class AchievementProgress {
    @Attribute(.unique) var key: String
    var progress: Int
    var target: Int
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }
    var fraction: Double { target > 0 ? min(1.0, Double(progress) / Double(target)) : 0 }

    init(key: String, progress: Int = 0, target: Int, unlockedAt: Date? = nil) {
        self.key = key
        self.progress = progress
        self.target = target
        self.unlockedAt = unlockedAt
    }
}

@Model
final class DailyChallengeRun {
    /// `yyyy-MM-dd` in the user's current calendar; unique per day per slot.
    @Attribute(.unique) var dayKey: String
    var score: Int
    var stars: Int                   // 0...3
    var completedAt: Date
    var perfect: Bool

    init(dayKey: String, score: Int, stars: Int, completedAt: Date, perfect: Bool) {
        self.dayKey = dayKey
        self.score = score
        self.stars = stars
        self.completedAt = completedAt
        self.perfect = perfect
    }
}
