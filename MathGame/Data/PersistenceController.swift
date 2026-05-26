//
//  PersistenceController.swift
//  MathGame — Data
//

import Foundation
import SwiftData

@MainActor
enum PersistenceController {

    static let shared: ModelContainer = {
        let schema = Schema([
            Player.self,
            BestScore.self,
            AchievementProgress.self,
            DailyChallengeRun.self,
        ])
        let config = ModelConfiguration("MathGameStore", schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // First-run migration failure (e.g. user updates from v1 with no store) — wipe and retry once.
            let inMemory = ModelConfiguration("MathGameMemory", schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [inMemory])
            } catch {
                fatalError("Failed to create even in-memory SwiftData container: \(error)")
            }
        }
    }()

    /// Returns the singleton Player record, creating it on first launch.
    static func loadOrCreatePlayer(in context: ModelContext) -> Player {
        let descriptor = FetchDescriptor<Player>(predicate: #Predicate { $0.slot == 0 })
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let player = Player()
        context.insert(player)
        try? context.save()
        return player
    }
}

/// Tiny in-memory container used by SwiftUI Previews so they don't pollute the real store.
@MainActor
enum PreviewPersistence {
    static let container: ModelContainer = {
        let schema = Schema([
            Player.self,
            BestScore.self,
            AchievementProgress.self,
            DailyChallengeRun.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    static func samplePlayer() -> Player {
        let p = Player(totalXP: 480, coins: 25, currentStreak: 4, longestStreak: 12, didCompleteOnboarding: true)
        let ctx = ModelContext(container)
        ctx.insert(p)
        return p
    }
}
