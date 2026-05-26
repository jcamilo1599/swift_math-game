//
//  DailyViewModel.swift
//  MathGame — Presentation/ViewModels
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class DailyViewModel {

    private(set) var challenge: DailyChallenge
    private(set) var currentIndex: Int = 0
    private(set) var score: Int = 0
    private(set) var correctCount: Int = 0
    private(set) var sessionStreak: Int = 0
    private(set) var isComplete: Bool = false
    var feedback: FeedbackOverlay.Kind = .none
    private(set) var lastAnswerWasCorrect: Bool?
    private(set) var selectedChoice: Int?
    private(set) var animationBump: Int = 0

    private var transitionTask: Task<Void, Never>?

    var currentQuestion: Question? {
        guard currentIndex < challenge.questions.count else { return nil }
        return challenge.questions[currentIndex]
    }

    var progressFraction: Double {
        Double(currentIndex) / Double(max(challenge.questions.count, 1))
    }

    var earnedStars: Int {
        if isComplete && correctCount == challenge.questions.count { return 3 }
        if score >= 200 { return 3 }
        if score >= 100 { return 2 }
        if score > 0 { return 1 }
        return 0
    }

    var isPerfect: Bool { correctCount == challenge.questions.count }

    init(challenge: DailyChallenge = DailyChallengeService.challenge()) {
        self.challenge = challenge
    }

    func selectAnswer(_ choice: Int) {
        guard let q = currentQuestion, lastAnswerWasCorrect == nil else { return }
        selectedChoice = choice
        let correct = choice == q.answer
        if correct {
            sessionStreak += 1
            correctCount += 1
            score += ScoringSystem.points(correct: true, mode: q.mode, difficulty: .normal, sessionStreak: sessionStreak)
            feedback = .correct
            lastAnswerWasCorrect = true
            HapticEngine.shared.play(.success)
            AudioEngine.shared.play(.correct)
        } else {
            sessionStreak = 0
            feedback = .wrong
            lastAnswerWasCorrect = false
            HapticEngine.shared.play(.error)
            AudioEngine.shared.play(.wrong)
        }
        transitionTask?.cancel()
        transitionTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run {
                guard let self else { return }
                self.advance()
            }
        }
    }

    private func advance() {
        if currentIndex + 1 >= challenge.questions.count {
            isComplete = true
            AudioEngine.shared.play(.dailyComplete)
            HapticEngine.shared.play(.victory)
            return
        }
        currentIndex += 1
        feedback = .none
        lastAnswerWasCorrect = nil
        selectedChoice = nil
        animationBump &+= 1
    }

    func commitResults(into engine: ProgressionEngine) {
        engine.awardXP(Int(Double(score) * 1.5))
        engine.recordDailyCompletion(perfect: isPerfect, score: score)
        engine.save()
        GameCenterService.shared.submitDailyScore(score)
        for entry in engine.player.achievements {
            GameCenterService.shared.reportAchievement(key: entry.key, percentComplete: entry.fraction * 100)
        }
        // Refresh streak reminder if the user opted into notifications.
        if engine.player.notificationsEnabled {
            NotificationScheduler.scheduleStreakReminder(
                currentStreak: engine.player.currentStreak,
                alreadyCompletedToday: true
            )
        }
    }
}
