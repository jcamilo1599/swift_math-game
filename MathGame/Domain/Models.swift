//
//  Models.swift
//  MathGame — Domain
//
//  Pure-Swift domain models. No SwiftUI, no Foundation-heavy types.
//  Reusable across iOS, iPadOS, watchOS and Mac Catalyst targets.
//

import Foundation

// MARK: - GameMode

enum GameMode: String, CaseIterable, Identifiable, Codable, Hashable {
    case addition
    case subtraction
    case multiplication
    case division
    case power
    case root
    case timeAttack
    case survival
    case mixed
    case sequence

    var id: String { rawValue }

    /// Modes shown in the classic grid on the home screen.
    static let classic: [GameMode] = [
        .addition, .subtraction, .multiplication, .division, .power, .root,
    ]

    /// Modes shown in the "More modes" section.
    static let advanced: [GameMode] = [
        .timeAttack, .survival, .mixed, .sequence,
    ]

    var titleKey: String {
        switch self {
        case .addition: "mode.addition"
        case .subtraction: "mode.subtraction"
        case .multiplication: "mode.multiplication"
        case .division: "mode.division"
        case .power: "mode.power"
        case .root: "mode.root"
        case .timeAttack: "mode.timeAttack"
        case .survival: "mode.survival"
        case .mixed: "mode.mixed"
        case .sequence: "mode.sequence"
        }
    }

    var subtitleKey: String {
        switch self {
        case .addition: "mode.addition.subtitle"
        case .subtraction: "mode.subtraction.subtitle"
        case .multiplication: "mode.multiplication.subtitle"
        case .division: "mode.division.subtitle"
        case .power: "mode.power.subtitle"
        case .root: "mode.root.subtitle"
        case .timeAttack: "mode.timeAttack.subtitle"
        case .survival: "mode.survival.subtitle"
        case .mixed: "mode.mixed.subtitle"
        case .sequence: "mode.sequence.subtitle"
        }
    }

    var sfSymbol: String {
        switch self {
        case .addition: "plus"
        case .subtraction: "minus"
        case .multiplication: "multiply"
        case .division: "divide"
        case .power: "bolt.fill"
        case .root: "x.squareroot"
        case .timeAttack: "timer"
        case .survival: "heart.fill"
        case .mixed: "shuffle"
        case .sequence: "arrow.right.to.line"
        }
    }

    /// Stable accent index 0-5; the theme palette maps this to a color.
    var accentIndex: Int {
        switch self {
        case .addition: 0
        case .subtraction: 1
        case .multiplication: 2
        case .division: 3
        case .power: 4
        case .root: 5
        case .timeAttack: 1
        case .survival: 4
        case .mixed: 2
        case .sequence: 0
        }
    }

    /// Bridge to the legacy `CalculationType` for the 6 classic modes; nil for advanced modes.
    var classicCalculation: CalculationType? {
        switch self {
        case .addition: .addition
        case .subtraction: .subtraction
        case .multiplication: .multiplication
        case .division: .division
        case .power: .power
        case .root: .root
        default: nil
        }
    }

    /// Game Center leaderboard suffix; combined with the base ID in MIGRATION.md.
    var leaderboardSuffix: String { rawValue }

    /// Whether this mode is time-boxed (no lives), e.g. Time Attack.
    var isTimed: Bool { self == .timeAttack }

    /// Default seconds for timed modes; ignored otherwise.
    var timerSeconds: Int {
        switch self {
        case .timeAttack: 60
        default: 0
        }
    }
}

// MARK: - Difficulty

enum Difficulty: Int, CaseIterable, Codable {
    case easy = 0
    case normal = 1
    case hard = 2
    case insane = 3

    var titleKey: String {
        switch self {
        case .easy: "difficulty.easy"
        case .normal: "difficulty.normal"
        case .hard: "difficulty.hard"
        case .insane: "difficulty.insane"
        }
    }

    /// XP multiplier per correct answer.
    var xpMultiplier: Double {
        switch self {
        case .easy: 0.5
        case .normal: 1.0
        case .hard: 1.5
        case .insane: 2.5
        }
    }
}

// MARK: - Question

struct Question: Hashable {
    let prompt: String              // What the user sees on screen, e.g. "7 + 5".
    let answer: Int                 // Correct answer (always a non-negative integer ≤ 9999).
    let choices: [Int]              // Exactly 4, contains `answer`, all unique, all ≥ 0, shuffled.
    let mode: GameMode
}

// MARK: - Lives

struct LivesConfig {
    let starting: Int
    static let standard = LivesConfig(starting: 3)
    static let survival = LivesConfig(starting: 1)
    static let unlimited = LivesConfig(starting: Int.max)
}
