//
//  Atoms.swift
//  MathGame — Presentation
//
//  Small reusable views.
//

import SwiftUI

// MARK: - Heart row (lives indicator)

struct HeartRow: View {
    let livesRemaining: Int
    let maxLives: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxLives, id: \.self) { idx in
                Image(systemName: idx < livesRemaining ? "heart.fill" : "heart")
                    .foregroundStyle(idx < livesRemaining ? Color.appDanger : Color.white.opacity(0.18))
                    .symbolEffect(.bounce, value: livesRemaining)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("a11y.lives.\(livesRemaining)"))
    }
}

// MARK: - Streak badge

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: streak >= 3 ? "flame.fill" : "flame")
                .foregroundStyle(streak >= 3 ? Color.orange : Color.white.opacity(0.5))
            Text("\(streak)")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.06), in: Capsule())
        .accessibilityLabel(Text("a11y.streak.\(streak)"))
    }
}

// MARK: - XP bar

struct XPBar: View {
    let level: Int
    let current: Int
    let next: Int
    @State private var animatedFraction: Double = 0

    var fraction: Double { next > 0 ? min(1.0, Double(current) / Double(next)) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("ui.level.\(level)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text(verbatim: "\(current) / \(next) XP")
                    .font(.system(.caption2, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.6))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [Color.appPrimary, Color.appAccent],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: max(4, geo.size.width * animatedFraction))
                }
            }
            .frame(height: 8)
            .onAppear {
                withAnimation(.appSpring) { animatedFraction = fraction }
            }
            .onChange(of: fraction) { _, newValue in
                withAnimation(.appSpring) { animatedFraction = newValue }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("a11y.xpbar.\(level).\(current).\(next)"))
    }
}

// MARK: - Score & timer pills

struct ScorePill: View {
    let score: Int
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill").foregroundStyle(Color.appAccent)
            Text("\(score)")
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Color.white.opacity(0.06), in: Capsule())
        .accessibilityLabel(Text("a11y.score.\(score)"))
    }
}

struct TimerPill: View {
    let seconds: Int
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer").foregroundStyle(seconds <= 5 ? Color.appDanger : Color.appPrimary)
            Text(timeString)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Color.white.opacity(0.06), in: Capsule())
        .accessibilityLabel(Text("a11y.timer.\(seconds)"))
    }
    private var timeString: String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Star row

struct StarRow: View {
    let earned: Int          // 0...3
    let size: CGFloat
    var body: some View {
        HStack(spacing: size / 4) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < earned ? "star.fill" : "star")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundStyle(i < earned ? Color.appAccent : Color.white.opacity(0.25))
                    .symbolEffect(.bounce, value: earned)
            }
        }
        .accessibilityLabel(Text("a11y.stars.\(earned)"))
    }
}
