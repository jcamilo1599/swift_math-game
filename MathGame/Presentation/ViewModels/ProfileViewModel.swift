//
//  ProfileViewModel.swift
//  MathGame — Presentation/ViewModels
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class ProfileViewModel {

    let player: Player

    init(player: Player) {
        self.player = player
    }

    var level: Int { player.level }
    var xpProgress: (current: Int, next: Int) { player.xpProgress }
    var streak: Int { player.currentStreak }
    var longestStreak: Int { player.longestStreak }
    var coins: Int { player.coins }

    var totalCorrect: Int {
        // Approximate from the volume achievement (the most reliable counter).
        player.achievements.first(where: { $0.key == "correct_10000" })?.progress ?? 0
    }

    var dailyCompletedCount: Int { player.dailyRuns.count }

    var unlockedAchievements: [AchievementProgress] {
        player.achievements.filter { $0.isUnlocked }.sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
    }

    var bestScoreEntries: [(mode: GameMode, score: Int)] {
        player.bestScores
            .compactMap { bs -> (GameMode, Int)? in
                guard let mode = GameMode(rawValue: bs.modeKey) else { return nil }
                return (mode, bs.score)
            }
            .sorted { $0.1 > $1.1 }
    }
}
