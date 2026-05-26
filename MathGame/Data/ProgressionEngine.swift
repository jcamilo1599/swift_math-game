//
//  ProgressionEngine.swift
//  MathGame — Data
//
//  Coordinates Player + Achievement updates from gameplay events. Keep this
//  layer free of SwiftUI so it works the same on iPhone, iPad, Watch and Mac.
//

import Foundation
import SwiftData

@MainActor
final class ProgressionEngine {

    let context: ModelContext
    let player: Player

    init(context: ModelContext, player: Player) {
        self.context = context
        self.player = player
    }

    // MARK: - XP & coins

    /// Award XP and update achievements that depend on level.
    func awardXP(_ amount: Int) {
        guard amount > 0 else { return }
        let previousLevel = player.level
        player.totalXP += amount
        let newLevel = player.level
        if newLevel > previousLevel {
            // Coins as a level-up reward (soft currency for future cosmetics).
            player.coins += (newLevel - previousLevel) * 10
            updateAchievement(key: "level_10", progress: newLevel)
            updateAchievement(key: "level_25", progress: newLevel)
        }
    }

    func awardCoins(_ amount: Int) {
        guard amount > 0 else { return }
        player.coins += amount
    }

    // MARK: - Streak (driven only by completing the Daily Challenge)

    /// Call when the user completes today's Daily. Returns whether the streak grew this call.
    @discardableResult
    func recordDailyCompletion(perfect: Bool, score: Int, on date: Date = .now) -> Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: date)
        let dayKey = ISO8601DateFormatter.dayKeyFormatter.string(from: today)

        // De-dupe: don't allow recording the same day twice.
        if let last = player.lastDailyCompletedOn, cal.isDate(last, inSameDayAs: today) {
            return false
        }

        // Streak math.
        let grew: Bool
        if let last = player.lastDailyCompletedOn {
            let lastDay = cal.startOfDay(for: last)
            if let diff = cal.dateComponents([.day], from: lastDay, to: today).day {
                if diff == 1 {
                    player.currentStreak += 1
                    grew = true
                } else if diff == 0 {
                    grew = false
                } else {
                    player.currentStreak = 1
                    grew = true
                }
            } else {
                player.currentStreak = 1
                grew = true
            }
        } else {
            player.currentStreak = 1
            grew = true
        }

        player.longestStreak = max(player.longestStreak, player.currentStreak)
        player.lastDailyCompletedOn = today

        // Persist a DailyChallengeRun.
        let stars = score >= 200 ? 3 : (score >= 100 ? 2 : (score > 0 ? 1 : 0))
        let run = DailyChallengeRun(dayKey: dayKey, score: score, stars: stars, completedAt: date, perfect: perfect)
        context.insert(run)
        player.dailyRuns.append(run)

        // Achievements driven by this event.
        updateAchievement(key: "first_daily", progress: 1)
        if perfect { updateAchievement(key: "perfect_daily", progress: 1) }
        updateAchievement(key: "streak_3", progress: player.currentStreak)
        updateAchievement(key: "streak_7", progress: player.currentStreak)
        updateAchievement(key: "streak_30", progress: player.currentStreak)
        updateAchievement(key: "streak_100", progress: player.currentStreak)

        return grew
    }

    // MARK: - Per-mode best score

    func recordRunResult(mode: GameMode, score: Int, correctAnswers: Int) {
        // Update best score.
        let key = mode.rawValue
        if let existing = player.bestScores.first(where: { $0.modeKey == key }) {
            if score > existing.score {
                existing.score = score
                existing.date = .now
            }
        } else {
            let bs = BestScore(modeKey: key, score: score, date: .now)
            context.insert(bs)
            player.bestScores.append(bs)
        }

        // Generic volume achievements.
        updateAchievement(key: "first_win", progress: 1)
        bumpAchievement(key: "correct_100", by: correctAnswers)
        bumpAchievement(key: "correct_1000", by: correctAnswers)
        bumpAchievement(key: "correct_10000", by: correctAnswers)

        // Per-mode mastery.
        switch mode {
        case .addition: updateAchievement(key: "master_addition", progress: score)
        case .subtraction: updateAchievement(key: "master_subtraction", progress: score)
        case .multiplication: updateAchievement(key: "master_multiplication", progress: score)
        case .division: updateAchievement(key: "master_division", progress: score)
        case .power: updateAchievement(key: "master_power", progress: score)
        case .root: updateAchievement(key: "master_root", progress: score)
        case .survival: updateAchievement(key: "survival_50", progress: correctAnswers)
        case .timeAttack: updateAchievement(key: "timeattack_30", progress: correctAnswers)
        case .mixed, .sequence: break
        }
    }

    // MARK: - Achievements helpers

    private func updateAchievement(key: String, progress: Int) {
        guard let definition = AchievementCatalog.find(key) else { return }
        let entry = findOrCreate(achievementKey: key, target: definition.target)
        let newProgress = max(entry.progress, progress)
        entry.progress = min(newProgress, definition.target)
        if entry.progress >= definition.target && entry.unlockedAt == nil {
            entry.unlockedAt = .now
        }
    }

    private func bumpAchievement(key: String, by delta: Int) {
        guard delta > 0, let definition = AchievementCatalog.find(key) else { return }
        let entry = findOrCreate(achievementKey: key, target: definition.target)
        entry.progress = min(entry.progress + delta, definition.target)
        if entry.progress >= definition.target && entry.unlockedAt == nil {
            entry.unlockedAt = .now
        }
    }

    private func findOrCreate(achievementKey: String, target: Int) -> AchievementProgress {
        if let existing = player.achievements.first(where: { $0.key == achievementKey }) {
            return existing
        }
        let entry = AchievementProgress(key: achievementKey, target: target)
        context.insert(entry)
        player.achievements.append(entry)
        return entry
    }

    func save() {
        try? context.save()
    }
}

extension ISO8601DateFormatter {
    static let dayKeyFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()
}
