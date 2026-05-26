//
//  ContentView.swift
//  MathGame — Presentation/Pages
//
//  Home screen. Adaptive: NavigationStack on iPhone, NavigationSplitView on iPad/Mac.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var hSize
    @Query private var players: [Player]

    @State private var path: [AppRoute] = []
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

    var body: some View {
        Group {
            if hSize == .regular {
                splitLayout
            } else {
                stackLayout
            }
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

    // MARK: - Layouts

    /// Single source of truth for navigation. The sidebar's selection reads/writes
    /// the last element of `path`, so selecting an item pushes its destination and
    /// `dismiss()` inside a pushed view pops back to home — on both iPhone and iPad.
    private var selectionBinding: Binding<AppRoute?> {
        Binding(
            get: { path.last },
            set: { newValue in
                if let v = newValue { path = [v] } else { path = [] }
            }
        )
    }

    private var stackLayout: some View {
        NavigationStack(path: $path) {
            homeScroll(horizontalPadding: AppTheme.Spacing.l, constrained: false)
                .navigationDestination(for: AppRoute.self, destination: destination)
                .toolbar(content: toolbarContent)
        }
    }

    @ViewBuilder
    private var splitLayout: some View {
        NavigationSplitView {
            sidebar
                .toolbar { ToolbarItem(placement: .principal) { brandLogo } }
        } detail: {
            NavigationStack(path: $path) {
                homeScroll(horizontalPadding: AppTheme.Spacing.xl, constrained: true)
                    .navigationDestination(for: AppRoute.self, destination: destination)
                    .toolbar(content: toolbarContent)
            }
        }
    }

    private func homeScroll(horizontalPadding: CGFloat, constrained: Bool) -> some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                homeContent
                    .frame(maxWidth: constrained ? 880 : .infinity)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
    }

    // MARK: - Sidebar (iPad/Mac)

    private var sidebar: some View {
        List(selection: selectionBinding) {
            Section {
                Label("nav.daily", systemImage: "sun.max.fill").tag(AppRoute.daily)
            }
            Section("nav.classic") {
                ForEach(GameMode.classic) { mode in
                    Label(LocalizedStringKey(mode.titleKey), systemImage: mode.sfSymbol)
                        .tag(AppRoute.mode(mode))
                }
            }
            Section("nav.more") {
                ForEach(GameMode.advanced) { mode in
                    Label(LocalizedStringKey(mode.titleKey), systemImage: mode.sfSymbol)
                        .tag(AppRoute.mode(mode))
                }
            }
            Section {
                Label("nav.profile", systemImage: "person.fill").tag(AppRoute.profile)
                Label("nav.stats", systemImage: "chart.bar.fill").tag(AppRoute.stats)
                Label("nav.achievements", systemImage: "trophy.fill").tag(AppRoute.achievements)
                Label("nav.settings", systemImage: "gear").tag(AppRoute.settings)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("app.name")
    }

    // MARK: - Home content (both layouts)

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
        LazyVGrid(columns: [GridItem(.flexible(), spacing: AppTheme.Spacing.m), GridItem(.flexible(), spacing: AppTheme.Spacing.m)], spacing: AppTheme.Spacing.m) {
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
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 12) {
                NavigationLink(value: AppRoute.achievements) {
                    Image(systemName: "trophy.fill").foregroundStyle(Color.appAccent)
                }
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gear").foregroundStyle(.white)
                }
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

    private var brandLogo: some View {
        HStack(spacing: 8) {
            Image(systemName: "function").foregroundStyle(Color.appAccent)
            Text("app.name").font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
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
