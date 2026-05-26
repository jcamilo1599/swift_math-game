//
//  Molecules.swift
//  MathGame — Presentation
//
//  Compound views composed of multiple atoms.
//

import SwiftUI

// MARK: - Question card

struct QuestionCard: View {
    let prompt: String
    let promptKey: LocalizedStringKey?

    init(prompt: String, promptKey: LocalizedStringKey? = nil) {
        self.prompt = prompt
        self.promptKey = promptKey
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 18) {
            Text("ui.solve.this")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .textCase(.uppercase)
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))
            Text(prompt)
                .font(.system(size: 60, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.4)
                .multilineTextAlignment(.center)
                .shadow(color: .white.opacity(0.2), radius: 10, x: 0, y: 0)
                .contentTransition(reduceMotion ? .identity : .opacity)
                .id(prompt)
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, minHeight: 220)
        .neoCardStyle()
    }
}

// MARK: - Feedback overlay

struct FeedbackOverlay: View {
    enum Kind { case none, correct, wrong }
    let kind: Kind

    var body: some View {
        Rectangle()
            .fill(color)
            .ignoresSafeArea()
            .animation(.easeOut(duration: 0.25), value: kind)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var color: Color {
        switch kind {
        case .none: .clear
        case .correct: Color.appSuccess.opacity(0.18)
        case .wrong: Color.appDanger.opacity(0.22)
        }
    }
}

// MARK: - Mode card (used on the home menu)

struct ModeCard: View {
    let mode: GameMode
    let bestScore: Int?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: mode.sfSymbol)
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(accent)
                .frame(width: 64, height: 64)
                .background(accent.opacity(0.18), in: Circle())
            Text(LocalizedStringKey(mode.titleKey))
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            if let best = bestScore, best > 0 {
                Text("ui.best.\(best)")
                    .font(.system(.caption, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                Text("ui.tap.to.play")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 160)
        .padding(.vertical, 16)
        .neoCardStyle(tint: accent)
        .accessibilityElement(children: .combine)
    }

    private var accent: Color { .modeAccent(for: mode.accentIndex) }
}

// MARK: - Daily card (hero on home)

struct DailyCard: View {
    let completedToday: Bool
    let currentStreak: Int
    let countdownText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label {
                    Text("ui.daily.title")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                } icon: {
                    Image(systemName: "sun.max.fill").foregroundStyle(Color.appAccent)
                }
                Spacer()
                StreakBadge(streak: currentStreak)
            }
            Text(completedToday ? "ui.daily.subtitle.done" : "ui.daily.subtitle.todo")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            HStack {
                Image(systemName: completedToday ? "checkmark.seal.fill" : "play.fill")
                Text(completedToday ? "ui.daily.next.\(countdownText)" : "ui.daily.cta")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(completedToday ? Color.appPrimary.opacity(0.3) : Color.appAccent, in: Capsule())
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neoCardStyle(tint: Color.appAccent)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let titleKey: LocalizedStringKey
    var body: some View {
        Text(titleKey)
            .font(.system(.caption, design: .rounded, weight: .heavy))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(.white.opacity(0.55))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}
