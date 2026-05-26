//
//  GameCenterService.swift
//  MathGame — Data
//
//  Thin wrapper around GameKit. The leaderboard / achievement IDs themselves are
//  registered in App Store Connect — see MIGRATION.md.
//

import Foundation
#if canImport(GameKit)
import GameKit
#endif

@MainActor
final class GameCenterService: ObservableObject {

    static let shared = GameCenterService()

    /// Prefix for IDs registered in App Store Connect. Change once at release.
    static let leaderboardPrefix = "com.faacil.MathGame.leaderboard"
    static let achievementPrefix = "com.faacil.MathGame.achievement"

    @Published private(set) var isAuthenticated = false
    @Published private(set) var displayName = ""

    private init() {}

    func authenticate() {
        #if canImport(GameKit) && !targetEnvironment(macCatalyst)
        let player = GKLocalPlayer.local
        player.authenticateHandler = { [weak self] _, error in
            Task { @MainActor in
                guard let self else { return }
                self.isAuthenticated = player.isAuthenticated && error == nil
                self.displayName = player.displayName
            }
        }
        #else
        // Game Center on Catalyst follows the same API; only skip if GameKit unavailable.
        let player = GKLocalPlayer.local
        player.authenticateHandler = { [weak self] _, error in
            Task { @MainActor in
                guard let self else { return }
                self.isAuthenticated = player.isAuthenticated && error == nil
                self.displayName = player.displayName
            }
        }
        #endif
    }

    func submitScore(_ score: Int, for mode: GameMode) {
        guard isAuthenticated else { return }
        #if canImport(GameKit)
        let id = "\(Self.leaderboardPrefix).\(mode.leaderboardSuffix)"
        Task {
            try? await GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [id]
            )
        }
        #endif
    }

    func submitDailyScore(_ score: Int) {
        guard isAuthenticated else { return }
        #if canImport(GameKit)
        let id = "\(Self.leaderboardPrefix).daily"
        Task {
            try? await GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [id]
            )
        }
        #endif
    }

    func reportAchievement(key: String, percentComplete: Double) {
        guard isAuthenticated else { return }
        #if canImport(GameKit)
        let id = "\(Self.achievementPrefix).\(key)"
        let ach = GKAchievement(identifier: id)
        ach.percentComplete = max(0, min(100, percentComplete))
        ach.showsCompletionBanner = percentComplete >= 100
        GKAchievement.report([ach]) { _ in }
        #endif
    }
}
