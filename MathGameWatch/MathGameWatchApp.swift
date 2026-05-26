//
//  MathGameWatchApp.swift
//  MathGameWatch — watchOS companion
//
//  This file lives outside the iOS app target. To bring the watchOS app online:
//  1. In Xcode, File > New > Target > watchOS Watch App (named "MathGameWatch").
//  2. Add this file (and Watch/*) to that target.
//  3. Add the iOS-side Domain/ folder to the new target too (Models.swift,
//     QuestionGenerator.swift, Scoring.swift), so the Watch app shares logic.
//  4. Configure WatchKit App Companion App Bundle ID in target settings to
//     `com.faacil.MathGame` (or `-debug`).
//
//  See MIGRATION.md for the full procedure.
//

import SwiftUI

@main
struct MathGameWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}
