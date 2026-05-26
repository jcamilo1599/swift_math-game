//
//  ContentView.swift
//  MathGame — Presentation/Pages
//
//  Home screen. A single NavigationStack for every size class — the natural,
//  reliable iOS pattern. On iPad the content is simply centered/width-limited.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var hSize
    @Query private var players: [Player]

    @State private var countdownText: String = ""

    enum AppRoute: Hashable {
        case daily
        case mode(GameMode)
        case profile
        case stats
        case achievements
        case settings
    }

    private var player: Player {
        players.first ?? PersistenceController.loadOrCreatePlayer(in: modelContext)
    }

    private var bestScoreLookup: [GameMode: Int] {
        Dictionary(uniqueKeysWithValues: player.bestScores.compactMap { bs in
            GameMode(rawValue: bs.modeKey).map { ($0, bs.score) }
        })
    }

    private var completedDailyToday: Bool {
        guard let last = player.lastDailyCompletedOn else { return false }
        return Calendar.current.isDateInToday(last)
    }

    /// On iPad/Mac (regular width) keep the content readable instead of stretching edge to edge.
    private var contentMaxWidth: CGFloat { hSize == .regular ? 760 : .infinity }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    homeContent
                        .frame(maxWidth: contentMaxWidth)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, AppTheme.Spacing.l)
                        .padding(.bottom, AppTheme.Spacing.xl)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AppRoute.self, destination: destination)
            .toolbar(content: toolbarContent)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: Binding(
            get: { !player.didCompleteOnboarding },
            set: { _ in }
        )) {
            OnboardingView { player.didCompleteOnboarding = true; try? modelContext.save() }
                .interactiveDismissDisabled()
        }
        .task(id: "countdown-tick") { await tickCountdown() }
    }

    // MARK: - Home content

    private var homeContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            header

            NavigationLink(value: AppRoute.daily) {
                DailyCard(
                    completedToday: completedDailyToday,
                    currentStreak: player.currentStreak,
                    countdownText: countdownText
                )
            }
            .buttonStyle(.plain)

            SectionHeader(titleKey: "nav.classic")
            modeGrid(modes: GameMode.classic)

            SectionHeader(titleKey: "nav.more")
            modeGrid(modes: GameMode.advanced)
        }
        .padding(.top, AppTheme.Spacing.l)
    }

    private func modeGrid(modes: [GameMode]) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: AppTheme.Spacing.m),
                      GridItem(.flexible(), spacing: AppTheme.Spacing.m)],
            spacing: AppTheme.Spacing.m
        ) {
            ForEach(modes) { mode in
                NavigationLink(value: AppRoute.mode(mode)) {
                    ModeCard(mode: mode, bestScore: bestScoreLookup[mode])
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("app.name")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("home.subtitle")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
            XPBar(level: player.level, current: player.xpProgress.current, next: player.xpProgress.next)
                .padding(.top, 8)
        }
    }

    // MARK: - Toolbar / destination

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            NavigationLink(value: AppRoute.profile) {
                Image(systemName: "person.crop.circle")
                    .foregroundStyle(.white)
            }
            .accessibilityLabel(Text("nav.profile"))
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 14) {
                NavigationLink(value: AppRoute.stats) {
                    Image(systemName: "chart.bar.fill").foregroundStyle(.white)
                }
                .accessibilityLabel(Text("nav.stats"))
                NavigationLink(value: AppRoute.achievements) {
                    Image(systemName: "trophy.fill").foregroundStyle(Color.appAccent)
                }
                .accessibilityLabel(Text("nav.achievements"))
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gear").foregroundStyle(.white)
                }
                .accessibilityLabel(Text("nav.settings"))
            }
        }
    }

    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        switch route {
        case .daily:
            DailyView(player: player)
        case .mode(let mode):
            CalculationView(mode: mode, player: player)
        case .profile:
            ProfileView(player: player)
        case .stats:
            StatsView(player: player)
        case .achievements:
            AchievementsView(player: player)
        case .settings:
            SettingsView(player: player)
        }
    }

    // MARK: - Countdown tick

    private func tickCountdown() async {
        while !Task.isCancelled {
            let s = Int(DailyChallengeService.secondsUntilNextChallenge())
            let h = s / 3600
            let m = (s % 3600) / 60
            let sec = s % 60
            countdownText = String(format: "%02d:%02d:%02d", h, m, sec)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewPersistence.container)
}
