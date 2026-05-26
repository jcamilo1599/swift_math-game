//
//  MathGameApp.swift
//  MathGame
//

import SwiftUI
import SwiftData

@main
struct MathGameApp: App {

    init() {
        // Warm up the singletons so the first tap doesn't pay the cost.
        _ = AudioEngine.shared
        _ = HapticEngine.shared
        // Game Center authentication: best-effort, non-blocking.
        GameCenterService.shared.authenticate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(PersistenceController.shared)
        .commands {
            CommandGroup(replacing: .newItem) {
                // Disable "New" on macOS; we have our own navigation.
            }
        }
    }
}
