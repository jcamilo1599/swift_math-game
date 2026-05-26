//
//  StatsView.swift
//  MathGame — Presentation/Pages
//

import SwiftUI
import Charts

struct StatsView: View {
    let player: Player

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
                Text("stats.heading")
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)

                if player.dailyRuns.isEmpty {
                    Text("stats.empty")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(40)
                        .neoCardStyle()
                } else {
                    dailyChart
                    starsBreakdown
                }
            }
            .padding(AppTheme.Spacing.l)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("nav.stats")
        .toolbarBackground(Color.appBackground, for: .navigationBar)
    }

    private var sortedRuns: [DailyChallengeRun] {
        player.dailyRuns.sorted { $0.completedAt < $1.completedAt }.suffix(14).map { $0 }
    }

    @ViewBuilder
    private var dailyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(titleKey: "stats.daily.last14")
            Chart(sortedRuns, id: \.dayKey) { run in
                BarMark(
                    x: .value("Day", run.completedAt, unit: .day),
                    y: .value("Score", run.score)
                )
                .foregroundStyle(Color.appAccent.gradient)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(16)
            .neoCardStyle()
        }
    }

    private var starsBreakdown: some View {
        let runs = player.dailyRuns
        let perfect = runs.filter { $0.perfect }.count
        let threeStar = runs.filter { $0.stars == 3 }.count
        let twoStar = runs.filter { $0.stars == 2 }.count
        let oneStar = runs.filter { $0.stars == 1 }.count
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(titleKey: "stats.dailies")
            VStack(spacing: 8) {
                statRow(titleKey: "stats.perfect", value: perfect)
                statRow(titleKey: "stats.three_star", value: threeStar)
                statRow(titleKey: "stats.two_star", value: twoStar)
                statRow(titleKey: "stats.one_star", value: oneStar)
            }
            .padding(20)
            .neoCardStyle()
        }
    }

    private func statRow(titleKey: LocalizedStringKey, value: Int) -> some View {
        HStack {
            Text(titleKey)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text("\(value)")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
    }
}
