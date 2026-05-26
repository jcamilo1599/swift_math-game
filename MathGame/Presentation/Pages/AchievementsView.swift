//
//  AchievementsView.swift
//  MathGame — Presentation/Pages
//

import SwiftUI

struct AchievementsView: View {
    let player: Player

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(AchievementCatalog.all) { def in
                    let entry = player.achievements.first(where: { $0.key == def.key })
                        ?? AchievementProgress(key: def.key, target: def.target)
                    AchievementRow(definition: def, progress: entry)
                }
            }
            .padding(AppTheme.Spacing.l)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("nav.achievements")
        .toolbarBackground(Color.appBackground, for: .navigationBar)
    }
}
