//
//  AchievementCatalog.swift
//  MathGame — Data
//
//  Static catalog of achievements. The Player has @Model AchievementProgress entries
//  keyed by `Achievement.key`. The mapping to Game Center IDs lives in MIGRATION.md.
//

import Foundation

struct Achievement: Identifiable, Hashable {
    let key: String
    let titleKey: String
    let descriptionKey: String
    let target: Int
    let sfSymbol: String

    var id: String { key }
}

enum AchievementCatalog {

    static let all: [Achievement] = [
        // First-time milestones
        .init(key: "first_win", titleKey: "ach.first_win.title", descriptionKey: "ach.first_win.desc", target: 1, sfSymbol: "star.fill"),
        .init(key: "first_daily", titleKey: "ach.first_daily.title", descriptionKey: "ach.first_daily.desc", target: 1, sfSymbol: "calendar.badge.checkmark"),
        .init(key: "perfect_daily", titleKey: "ach.perfect_daily.title", descriptionKey: "ach.perfect_daily.desc", target: 1, sfSymbol: "checkmark.seal.fill"),

        // Streaks
        .init(key: "streak_3", titleKey: "ach.streak_3.title", descriptionKey: "ach.streak_3.desc", target: 3, sfSymbol: "flame"),
        .init(key: "streak_7", titleKey: "ach.streak_7.title", descriptionKey: "ach.streak_7.desc", target: 7, sfSymbol: "flame.fill"),
        .init(key: "streak_30", titleKey: "ach.streak_30.title", descriptionKey: "ach.streak_30.desc", target: 30, sfSymbol: "flame.fill"),
        .init(key: "streak_100", titleKey: "ach.streak_100.title", descriptionKey: "ach.streak_100.desc", target: 100, sfSymbol: "trophy.fill"),

        // Volume
        .init(key: "correct_100", titleKey: "ach.correct_100.title", descriptionKey: "ach.correct_100.desc", target: 100, sfSymbol: "checkmark.circle"),
        .init(key: "correct_1000", titleKey: "ach.correct_1000.title", descriptionKey: "ach.correct_1000.desc", target: 1000, sfSymbol: "checkmark.circle.fill"),
        .init(key: "correct_10000", titleKey: "ach.correct_10000.title", descriptionKey: "ach.correct_10000.desc", target: 10000, sfSymbol: "infinity"),

        // Per-mode mastery (best score ≥ 500)
        .init(key: "master_addition", titleKey: "ach.master_addition.title", descriptionKey: "ach.master_addition.desc", target: 500, sfSymbol: "plus.circle.fill"),
        .init(key: "master_subtraction", titleKey: "ach.master_subtraction.title", descriptionKey: "ach.master_subtraction.desc", target: 500, sfSymbol: "minus.circle.fill"),
        .init(key: "master_multiplication", titleKey: "ach.master_multiplication.title", descriptionKey: "ach.master_multiplication.desc", target: 500, sfSymbol: "multiply.circle.fill"),
        .init(key: "master_division", titleKey: "ach.master_division.title", descriptionKey: "ach.master_division.desc", target: 500, sfSymbol: "divide.circle.fill"),
        .init(key: "master_power", titleKey: "ach.master_power.title", descriptionKey: "ach.master_power.desc", target: 500, sfSymbol: "bolt.circle.fill"),
        .init(key: "master_root", titleKey: "ach.master_root.title", descriptionKey: "ach.master_root.desc", target: 500, sfSymbol: "x.squareroot"),

        // Survival / Time Attack milestones
        .init(key: "survival_50", titleKey: "ach.survival_50.title", descriptionKey: "ach.survival_50.desc", target: 50, sfSymbol: "heart.fill"),
        .init(key: "timeattack_30", titleKey: "ach.timeattack_30.title", descriptionKey: "ach.timeattack_30.desc", target: 30, sfSymbol: "timer"),

        // Level
        .init(key: "level_10", titleKey: "ach.level_10.title", descriptionKey: "ach.level_10.desc", target: 10, sfSymbol: "10.circle.fill"),
        .init(key: "level_25", titleKey: "ach.level_25.title", descriptionKey: "ach.level_25.desc", target: 25, sfSymbol: "25.circle.fill"),
    ]

    static func find(_ key: String) -> Achievement? { all.first(where: { $0.key == key }) }
}
