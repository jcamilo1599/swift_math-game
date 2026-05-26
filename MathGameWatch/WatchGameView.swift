//
//  WatchGameView.swift
//  MathGameWatch
//
//  60-second mental-math sprint. Adds + subtracts only (kid-of-the-watch-friendly).
//  Uses the shared Domain/ types — make sure Models.swift, QuestionGenerator.swift,
//  Scoring.swift are added to this target too.
//

import SwiftUI
import WatchKit

@MainActor
@Observable
final class WatchGameModel {
    private(set) var question: Question?
    private(set) var score: Int = 0
    private(set) var correctCount: Int = 0
    private(set) var seconds: Int = 60
    private(set) var isOver: Bool = false
    private(set) var sessionStreak: Int = 0
    var feedback: Bool? = nil

    private var rng = SeededRandom(seed: UInt64.random(in: 1...UInt64.max))
    private var task: Task<Void, Never>?

    init() {
        next()
        start()
    }

    private func start() {
        task = Task { [weak self] in
            while !(Task.isCancelled) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    guard let self, !self.isOver else { return }
                    self.seconds = max(0, self.seconds - 1)
                    if self.seconds == 0 { self.isOver = true }
                }
            }
        }
    }

    func answer(_ choice: Int) {
        guard !isOver, let q = question else { return }
        if choice == q.answer {
            sessionStreak += 1
            correctCount += 1
            score += ScoringSystem.points(correct: true, mode: q.mode, difficulty: .normal, sessionStreak: sessionStreak)
            feedback = true
            WKInterfaceDevice.current().play(.success)
        } else {
            sessionStreak = 0
            feedback = false
            WKInterfaceDevice.current().play(.failure)
        }
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            await MainActor.run {
                guard !self.isOver else { return }
                self.next()
                self.feedback = nil
            }
        }
    }

    private func next() {
        let pool: [GameMode] = [.addition, .subtraction]
        let mode = pool.randomElement() ?? .addition
        question = QuestionGenerator.generate(mode: mode, difficulty: .normal, rng: &rng)
    }
}

struct WatchGameView: View {
    @State private var model = WatchGameModel()

    var body: some View {
        ZStack {
            if model.isOver {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill").font(.title2).foregroundStyle(.yellow)
                    Text("Time's up!")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                    Text("\(model.score)")
                        .font(.system(.title, design: .rounded, weight: .black))
                        .monospacedDigit()
                    Text("\(model.correctCount) correct")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 6) {
                    HStack {
                        Text("⏱ \(model.seconds)").monospacedDigit()
                        Spacer()
                        Text("⭐ \(model.score)").monospacedDigit()
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    Text(model.question?.prompt ?? "")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .padding(.vertical, 4)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                        ForEach(model.question?.choices ?? [], id: \.self) { c in
                            Button("\(c)") { model.answer(c) }
                                .font(.system(.headline, design: .rounded, weight: .heavy))
                                .tint(.yellow)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}
