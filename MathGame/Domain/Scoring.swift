//
//  Scoring.swift
//  MathGame — Domain
//

import Foundation

/// XP curve and level math. Both are pure functions so they're trivially testable
/// and share between iOS, watchOS and Mac targets.
enum XPCurve {

    /// XP required to reach `level + 1` from level `level`.
    /// Curve: 100 * level^1.5 (level 1→2 = 100, 2→3 ≈ 283, 5→6 = 1118, 10→11 ≈ 3162).
    static func xpForNextLevel(from level: Int) -> Int {
        let l = max(1, Double(level))
        return Int((100.0 * pow(l, 1.5)).rounded())
    }

    /// Cumulative XP needed to reach `level`. Level 1 = 0 XP.
    static func cumulativeXP(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        var total = 0
        for l in 1..<level {
            total += xpForNextLevel(from: l)
        }
        return total
    }

    /// Derive level from a cumulative XP total.
    static func level(forXP xp: Int) -> Int {
        guard xp > 0 else { return 1 }
        var level = 1
        var remaining = xp
        while remaining >= xpForNextLevel(from: level) {
            remaining -= xpForNextLevel(from: level)
            level += 1
            if level > 200 { break } // hard cap; absurdly high already
        }
        return level
    }

    /// Progress within the current level, returning (xpInLevel, xpToNext) for a UI bar.
    static func progress(forXP xp: Int) -> (current: Int, next: Int) {
        let level = level(forXP: xp)
        let into = xp - cumulativeXP(forLevel: level)
        let need = xpForNextLevel(from: level)
        return (into, need)
    }
}

/// Per-answer scoring & XP awards.
enum ScoringSystem {

    /// Points for a correct answer in a given mode, factoring difficulty + current streak.
    static func points(correct: Bool, mode: GameMode, difficulty: Difficulty, sessionStreak: Int) -> Int {
        guard correct else { return 0 }
        let base = 10
        let streakBonus = min(sessionStreak / 3, 5) * 2 // up to +10 for streak.
        let modeBonus: Int
        switch mode {
        case .timeAttack, .survival, .sequence: modeBonus = 5
        case .mixed: modeBonus = 3
        default: modeBonus = 0
        }
        return Int(Double(base + streakBonus + modeBonus) * difficulty.xpMultiplier)
    }

    /// XP awarded; usually mirrors points, with a Daily multiplier when applicable.
    static func xp(correct: Bool, mode: GameMode, difficulty: Difficulty, sessionStreak: Int, isDaily: Bool) -> Int {
        let p = points(correct: correct, mode: mode, difficulty: difficulty, sessionStreak: sessionStreak)
        return isDaily ? Int(Double(p) * 1.5) : p
    }
}
