//
//  GameViewModel.swift
//  MathGame — Presentation/ViewModels
//
//  Drives a single play session of any mode (classic, time attack, survival,
//  mixed, sequence). Holds the question stream, score, lives/timer, and
//  emits side-effects (audio/haptics/progression) through injected services.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class GameViewModel {

    // MARK: - Configuration

    let mode: GameMode
    let difficulty: Difficulty
    private let isDaily: Bool
    private let livesConfig: LivesConfig

    // MARK: - State

    private(set) var question: Question?
    private(set) var score: Int = 0
    private(set) var lives: Int
    private(set) var timeRemaining: Int = 0
    private(set) var sessionStreak: Int = 0
    private(set) var correctAnswers: Int = 0
    private(set) var isGameOver: Bool = false
    var feedback: FeedbackOverlay.Kind = .none
    private(set) var lastAnswerWasCorrect: Bool?
    private(set) var selectedChoice: Int?
    private(set) var animationBump: Int = 0

    // MARK: - Internal

    private var rng: SeededRandom
    private var timerTask: Task<Void, Never>?
    private var transitionTask: Task<Void, Never>?

    // MARK: - Init

    init(mode: GameMode, difficulty: Difficulty = .normal, isDaily: Bool = false, seed: UInt64? = nil) {
        self.mode = mode
        self.difficulty = difficulty
        self.isDaily = isDaily
        self.livesConfig = (mode == .survival) ? .survival : (mode.isTimed ? .unlimited : .standard)
        self.lives = livesConfig.starting
        self.rng = SeededRandom(seed: seed ?? UInt64.random(in: 1...UInt64.max))
        self.timeRemaining = mode.timerSeconds
        nextQuestion()
        if mode.isTimed { startTimer() }
    }

    deinit {
        // Task is detached so capturing self is unnecessary here.
        // Cancellation is best-effort; the Task already checks isCancelled.
    }

    // MARK: - Question lifecycle

    func nextQuestion() {
        question = QuestionGenerator.generate(mode: mode, difficulty: difficulty, rng: &rng)
        feedback = .none
        lastAnswerWasCorrect = nil
        selectedChoice = nil
        animationBump &+= 1
    }

    func selectAnswer(_ choice: Int) {
        guard !isGameOver, let q = question, lastAnswerWasCorrect == nil else { return }
        selectedChoice = choice
        let correct = choice == q.answer

        if correct {
            sessionStreak += 1
            correctAnswers += 1
            let pts = ScoringSystem.points(correct: true, mode: mode, difficulty: difficulty, sessionStreak: sessionStreak)
            score += pts
            feedback = .correct
            lastAnswerWasCorrect = true
            HapticEngine.shared.play(.success)
            AudioEngine.shared.play(.correct)
        } else {
            sessionStreak = 0
            feedback = .wrong
            lastAnswerWasCorrect = false
            if !mode.isTimed {
                lives -= 1
            }
            HapticEngine.shared.play(.error)
            AudioEngine.shared.play(.wrong)
            if lives <= 0 && !mode.isTimed {
                endGame()
                return
            }
        }

        transitionTask?.cancel()
        transitionTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 600_000_000)
            await MainActor.run {
                guard let self else { return }
                if self.isGameOver { return }
                self.nextQuestion()
            }
        }
    }

    // MARK: - Timer (time attack)

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !(Task.isCancelled) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    guard let self, !self.isGameOver else { return }
                    self.timeRemaining = max(0, self.timeRemaining - 1)
                    if self.timeRemaining <= 5 && self.timeRemaining > 0 {
                        AudioEngine.shared.play(.timeTick)
                    }
                    if self.timeRemaining == 0 {
                        self.endGame()
                    }
                }
            }
        }
    }

    // MARK: - End

    func endGame() {
        guard !isGameOver else { return }
        isGameOver = true
        timerTask?.cancel()
        transitionTask?.cancel()
        AudioEngine.shared.play(.gameOver)
        HapticEngine.shared.play(.warning)
    }

    func reset() {
        score = 0
        lives = livesConfig.starting
        timeRemaining = mode.timerSeconds
        sessionStreak = 0
        correctAnswers = 0
        isGameOver = false
        feedback = .none
        lastAnswerWasCorrect = nil
        selectedChoice = nil
        nextQuestion()
        if mode.isTimed { startTimer() }
    }

    // MARK: - Persistence handoff

    /// Call from the view when the game ends, passing a configured engine.
    func commitResults(into engine: ProgressionEngine) {
        engine.awardXP(Int(Double(score) * (isDaily ? 1.5 : 1.0)))
        engine.recordRunResult(mode: mode, score: score, correctAnswers: correctAnswers)
        engine.save()
        GameCenterService.shared.submitScore(score, for: mode)
        reportUnlockedAchievements(engine.player)
    }

    private func reportUnlockedAchievements(_ player: Player) {
        let gc = GameCenterService.shared
        for entry in player.achievements {
            gc.reportAchievement(key: entry.key, percentComplete: entry.fraction * 100)
        }
    }
}
