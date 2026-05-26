//
//  CalculationView.swift
//  MathGame — Presentation/Pages
//
//  The in-session view. Drives any mode through GameViewModel.
//

import SwiftUI
import SwiftData

struct CalculationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let mode: GameMode
    let player: Player
    @State private var viewModel: GameViewModel

    init(mode: GameMode, player: Player) {
        self.mode = mode
        self.player = player
        _viewModel = State(initialValue: GameViewModel(mode: mode, difficulty: .normal, isDaily: false))
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            ZStack {
                Color.appBackground.ignoresSafeArea()
                FeedbackOverlay(kind: viewModel.feedback)

                VStack(spacing: AppTheme.Spacing.m) {
                    header

                    if isLandscape {
                        HStack(spacing: AppTheme.Spacing.l) {
                            questionPane
                            answersPane
                        }
                        .padding(.horizontal, AppTheme.Spacing.l)
                        .padding(.bottom, AppTheme.Spacing.l)
                    } else {
                        questionPane
                            .padding(.horizontal, AppTheme.Spacing.l)
                        Spacer(minLength: AppTheme.Spacing.m)
                        answersPane
                            .padding(.horizontal, AppTheme.Spacing.l)
                            .padding(.bottom, AppTheme.Spacing.l)
                    }
                }
                .blur(radius: viewModel.isGameOver ? 12 : 0)
                .disabled(viewModel.isGameOver)

                if viewModel.isGameOver {
                    GameOverView(
                        score: viewModel.score,
                        correct: viewModel.correctAnswers,
                        onRetry: {
                            viewModel.reset()
                        },
                        onExit: {
                            commit()
                            dismiss()
                        }
                    )
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationBarBackButtonHidden()
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: viewModel.isGameOver) { _, isOver in
                if isOver { commit() }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                commit()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .accessibilityLabel(Text("a11y.close"))

            Spacer()

            if mode.isTimed {
                TimerPill(seconds: viewModel.timeRemaining)
            } else {
                HeartRow(livesRemaining: viewModel.lives, maxLives: max(3, viewModel.lives))
            }

            Spacer()

            ScorePill(score: viewModel.score)
        }
        .padding(.horizontal, AppTheme.Spacing.l)
        .padding(.top, AppTheme.Spacing.s)
    }

    private var questionPane: some View {
        QuestionCard(prompt: viewModel.question?.prompt ?? "")
            .frame(maxWidth: .infinity)
    }

    private var answersPane: some View {
        let choices = viewModel.question?.choices ?? []
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            ForEach(Array(choices.enumerated()), id: \.element) { index, choice in
                Button {
                    viewModel.selectAnswer(choice)
                } label: {
                    AnswerButtonView(
                        number: choice,
                        accent: .modeAccent(for: mode.accentIndex),
                        state: stateForChoice(choice),
                        animateValue: viewModel.animationBump
                    )
                }
                .buttonStyle(.plain)
                // Positional shortcuts 1–4 for hardware keyboards (iPad/Mac Catalyst).
                .keyboardShortcut(keyForIndex(index), modifiers: [])
            }
        }
    }

    private func keyForIndex(_ index: Int) -> KeyEquivalent {
        switch index {
        case 0: "1"
        case 1: "2"
        case 2: "3"
        default: "4"
        }
    }

    private func stateForChoice(_ choice: Int) -> AnswerState {
        guard let selected = viewModel.selectedChoice else { return .idle }
        if choice == selected {
            return viewModel.lastAnswerWasCorrect == true ? .correct : .wrong
        }
        if let correct = viewModel.question?.answer, choice == correct && viewModel.lastAnswerWasCorrect == false {
            return .correct
        }
        return .dimmed
    }

    private func commit() {
        let engine = ProgressionEngine(context: modelContext, player: player)
        viewModel.commitResults(into: engine)
    }
}

// MARK: - Game Over

struct GameOverView: View {
    let score: Int
    let correct: Int
    let onRetry: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("game.over")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(Color.appDanger)

            VStack(spacing: 4) {
                Text("game.over.final_score")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(score)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("game.over.correct.\(correct)")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Button(action: onRetry) {
                Label("game.over.try_again", systemImage: "arrow.clockwise")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appAccent, in: Capsule())
            }
            .buttonStyle(.plain)

            Button(action: onExit) {
                Text("game.over.main_menu")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(30)
        .frame(maxWidth: 360)
        .neoCardStyle(tint: Color.appAccent)
    }
}
