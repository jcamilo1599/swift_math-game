//
//  DailyView.swift
//  MathGame — Presentation/Pages
//

import SwiftUI
import SwiftData

struct DailyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let player: Player
    @State private var viewModel = DailyViewModel()

    var alreadyCompletedToday: Bool {
        guard let last = player.lastDailyCompletedOn else { return false }
        return Calendar.current.isDateInToday(last)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            FeedbackOverlay(kind: viewModel.feedback)

            if alreadyCompletedToday && !viewModel.isComplete {
                // User opened Daily but already finished it today: show summary.
                DailyAlreadyDoneView(
                    streak: player.currentStreak,
                    onClose: { dismiss() }
                )
                .padding(AppTheme.Spacing.xl)
            } else if viewModel.isComplete {
                DailyResultView(
                    score: viewModel.score,
                    stars: viewModel.earnedStars,
                    perfect: viewModel.isPerfect,
                    newStreak: player.currentStreak,
                    onClose: { dismiss() }
                )
                .padding(AppTheme.Spacing.xl)
                .onAppear { commit() }
            } else {
                gameplayBody
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            ToolbarItem(placement: .principal) {
                Text("daily.title")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(Color.appBackground, for: .navigationBar)
    }

    @ViewBuilder
    private var gameplayBody: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            ProgressView(value: viewModel.progressFraction)
                .progressViewStyle(.linear)
                .tint(Color.appAccent)
                .padding(.horizontal, AppTheme.Spacing.l)

            HStack {
                Text("daily.q.\(viewModel.currentIndex + 1).\(10)")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                ScorePill(score: viewModel.score)
            }
            .padding(.horizontal, AppTheme.Spacing.l)

            QuestionCard(prompt: viewModel.currentQuestion?.prompt ?? "")
                .padding(.horizontal, AppTheme.Spacing.l)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(viewModel.currentQuestion?.choices ?? [], id: \.self) { choice in
                    Button { viewModel.selectAnswer(choice) } label: {
                        AnswerButtonView(
                            number: choice,
                            accent: Color.appAccent,
                            state: stateFor(choice),
                            animateValue: viewModel.animationBump
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.l)
        }
    }

    private func stateFor(_ choice: Int) -> AnswerState {
        guard let selected = viewModel.selectedChoice else { return .idle }
        if choice == selected {
            return viewModel.lastAnswerWasCorrect == true ? .correct : .wrong
        }
        if let correct = viewModel.currentQuestion?.answer, choice == correct && viewModel.lastAnswerWasCorrect == false {
            return .correct
        }
        return .dimmed
    }

    private func commit() {
        let engine = ProgressionEngine(context: modelContext, player: player)
        viewModel.commitResults(into: engine)
    }
}

// MARK: - Result screen

struct DailyResultView: View {
    let score: Int
    let stars: Int
    let perfect: Bool
    let newStreak: Int
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            StarRow(earned: stars, size: 56)

            Text(perfect ? "daily.result.perfect" : "daily.result.complete")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                Text("daily.result.score")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(score)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }

            HStack(spacing: 6) {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text("daily.result.streak.\(newStreak)")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color.white.opacity(0.06), in: Capsule())

            Button(action: onClose) {
                Text("daily.result.done")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appAccent, in: Capsule())
            }
            .buttonStyle(.plain)

            ShareLink(item: shareText) {
                Label("daily.result.share", systemImage: "square.and.arrow.up")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(28)
        .frame(maxWidth: 420)
        .neoCardStyle(tint: Color.appAccent)
    }

    private var shareText: String {
        let starsString = String(repeating: "★", count: stars) + String(repeating: "☆", count: 3 - stars)
        return String(localized: "daily.share.template.\(score).\(starsString).\(newStreak)")
    }
}

struct DailyAlreadyDoneView: View {
    let streak: Int
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.appSuccess)
            Text("daily.already_done.title")
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("daily.already_done.body.\(streak)")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button(action: onClose) {
                Text("daily.already_done.back")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appAccent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(28)
        .frame(maxWidth: 420)
        .neoCardStyle()
    }
}
