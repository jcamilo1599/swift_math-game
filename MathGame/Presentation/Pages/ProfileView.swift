//
//  ProfileView.swift
//  MathGame — Presentation/Pages
//

import SwiftUI

struct ProfileView: View {
    let player: Player
    @State private var viewModel: ProfileViewModel

    init(player: Player) {
        self.player = player
        _viewModel = State(initialValue: ProfileViewModel(player: player))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.l) {
                avatarHeader
                xpCard
                statsGrid
                recentAchievements
            }
            .padding(AppTheme.Spacing.l)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("nav.profile")
        .toolbarBackground(Color.appBackground, for: .navigationBar)
    }

    private var avatarHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.appPrimary, Color.appAccent], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                Text("\(viewModel.level)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            Text("profile.level.\(viewModel.level)")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
        }
    }

    private var xpCard: some View {
        VStack(spacing: 12) {
            XPBar(level: viewModel.level, current: viewModel.xpProgress.current, next: viewModel.xpProgress.next)
            HStack {
                Label("profile.coins.\(viewModel.coins)", systemImage: "circle.hexagongrid.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.appAccent)
                Spacer()
                Label("profile.daily_completed.\(viewModel.dailyCompletedCount)", systemImage: "calendar.badge.checkmark")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(20).neoCardStyle()
    }

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(titleKey: "profile.stats")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatTile(titleKey: "profile.current_streak", value: "\(viewModel.streak)", icon: "flame.fill", tint: .orange)
                StatTile(titleKey: "profile.longest_streak", value: "\(viewModel.longestStreak)", icon: "flame", tint: Color.appAccent)
                StatTile(titleKey: "profile.correct", value: "\(viewModel.totalCorrect)", icon: "checkmark.circle.fill", tint: Color.appSuccess)
                StatTile(titleKey: "profile.unlocked", value: "\(viewModel.unlockedAchievements.count)", icon: "trophy.fill", tint: Color.appAccent)
            }

            SectionHeader(titleKey: "profile.best_scores")
            VStack(spacing: 8) {
                if viewModel.bestScoreEntries.isEmpty {
                    Text("profile.no_scores")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .neoCardStyle()
                } else {
                    ForEach(viewModel.bestScoreEntries, id: \.mode) { entry in
                        HStack {
                            Image(systemName: entry.mode.sfSymbol)
                                .foregroundStyle(Color.modeAccent(for: entry.mode.accentIndex))
                                .frame(width: 28)
                            Text(LocalizedStringKey(entry.mode.titleKey))
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(entry.score)")
                                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                                .monospacedDigit()
                                .foregroundStyle(Color.appAccent)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Color.appSurface.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
    }

    private var recentAchievements: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(titleKey: "profile.recent_achievements")
            if viewModel.unlockedAchievements.isEmpty {
                Text("profile.no_achievements")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .neoCardStyle()
            } else {
                ForEach(viewModel.unlockedAchievements.prefix(5), id: \.key) { entry in
                    if let def = AchievementCatalog.find(entry.key) {
                        AchievementRow(definition: def, progress: entry)
                    }
                }
            }
        }
    }
}

struct StatTile: View {
    let titleKey: LocalizedStringKey
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(titleKey)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neoCardStyle()
    }
}

struct AchievementRow: View {
    let definition: Achievement
    let progress: AchievementProgress

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: definition.sfSymbol)
                .font(.title2)
                .foregroundStyle(progress.isUnlocked ? Color.appAccent : Color.white.opacity(0.3))
                .frame(width: 44, height: 44)
                .background((progress.isUnlocked ? Color.appAccent : Color.white).opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(definition.titleKey))
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(definition.descriptionKey))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                ProgressView(value: progress.fraction)
                    .tint(progress.isUnlocked ? Color.appSuccess : Color.appPrimary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.appSurface.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
