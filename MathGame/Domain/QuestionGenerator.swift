//
//  QuestionGenerator.swift
//  MathGame — Domain
//
//  Pure, deterministic question generation. Same seed ⇒ same sequence,
//  which is what the Daily Challenge uses to give every player the same
//  10 questions per calendar day.
//

import Foundation

/// Seeded splitmix64-ish PRNG. Standalone so the Domain has no Foundation-Random dependency
/// and produces identical sequences across iOS/iPadOS/watchOS/Mac Catalyst.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid the degenerate state == 0.
        self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func int(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &self)
    }
}

enum QuestionGenerator {

    /// Generate a single question for the given mode and difficulty.
    /// The optional `rng` lets the Daily Challenge use a deterministic seed.
    static func generate(
        mode: GameMode,
        difficulty: Difficulty = .normal,
        rng: inout SeededRandom
    ) -> Question {
        switch mode {
        case .addition:
            return additionQuestion(difficulty: difficulty, rng: &rng)
        case .subtraction:
            return subtractionQuestion(difficulty: difficulty, rng: &rng)
        case .multiplication:
            return multiplicationQuestion(difficulty: difficulty, rng: &rng)
        case .division:
            return divisionQuestion(difficulty: difficulty, rng: &rng)
        case .power:
            return powerQuestion(difficulty: difficulty, rng: &rng)
        case .root:
            return rootQuestion(difficulty: difficulty, rng: &rng)
        case .timeAttack, .mixed:
            // Random sub-mode each question (excluding sequence which has its own UI hint).
            let pool: [GameMode] = [.addition, .subtraction, .multiplication, .division]
            let pick = pool[rng.int(in: 0...(pool.count - 1))]
            return generate(mode: pick, difficulty: difficulty, rng: &rng)
        case .survival:
            // Same pool as mixed but harder bias kept inside each sub-generator.
            let pool: [GameMode] = [.addition, .subtraction, .multiplication, .division, .power]
            let pick = pool[rng.int(in: 0...(pool.count - 1))]
            return generate(mode: pick, difficulty: difficulty, rng: &rng)
        case .sequence:
            return sequenceQuestion(difficulty: difficulty, rng: &rng)
        }
    }

    /// Convenience that uses a system-random seed.
    static func generate(mode: GameMode, difficulty: Difficulty = .normal) -> Question {
        var rng = SeededRandom(seed: UInt64.random(in: 1...UInt64.max))
        return generate(mode: mode, difficulty: difficulty, rng: &rng)
    }

    // MARK: - Per-mode generators

    private static func range(_ d: Difficulty, low: Int, mid: Int, high: Int, insane: Int) -> ClosedRange<Int> {
        let upper: Int
        switch d {
        case .easy: upper = low
        case .normal: upper = mid
        case .hard: upper = high
        case .insane: upper = insane
        }
        return 1...upper
    }

    private static func additionQuestion(difficulty: Difficulty, rng: inout SeededRandom) -> Question {
        let r = range(difficulty, low: 10, mid: 20, high: 50, insane: 99)
        let a = rng.int(in: r)
        let b = rng.int(in: r)
        let ans = a + b
        return Question(prompt: "\(a) + \(b)", answer: ans, choices: makeChoices(for: ans, rng: &rng), mode: .addition)
    }

    private static func subtractionQuestion(difficulty: Difficulty, rng: inout SeededRandom) -> Question {
        let r = range(difficulty, low: 10, mid: 20, high: 50, insane: 99)
        let ans = rng.int(in: r)
        let b = rng.int(in: r)
        // Render a+b - b to guarantee non-negative answer = original `ans`.
        return Question(prompt: "\(ans + b) − \(b)", answer: ans, choices: makeChoices(for: ans, rng: &rng), mode: .subtraction)
    }

    private static func multiplicationQuestion(difficulty: Difficulty, rng: inout SeededRandom) -> Question {
        let r = range(difficulty, low: 5, mid: 10, high: 12, insane: 20)
        let a = rng.int(in: 2...r.upperBound)
        let b = rng.int(in: 2...r.upperBound)
        let ans = a * b
        return Question(prompt: "\(a) × \(b)", answer: ans, choices: makeChoices(for: ans, rng: &rng), mode: .multiplication)
    }

    private static func divisionQuestion(difficulty: Difficulty, rng: inout SeededRandom) -> Question {
        let r = range(difficulty, low: 5, mid: 10, high: 12, insane: 15)
        let ans = rng.int(in: 2...r.upperBound)
        let b = rng.int(in: 2...r.upperBound)
        let product = ans * b
        return Question(prompt: "\(product) ÷ \(b)", answer: ans, choices: makeChoices(for: ans, rng: &rng), mode: .division)
    }

    private static func powerQuestion(difficulty: Difficulty, rng: inout SeededRandom) -> Question {
        let r = range(difficulty, low: 6, mid: 10, high: 15, insane: 25)
        let base = rng.int(in: 2...r.upperBound)
        let ans = base * base
        return Question(prompt: "\(base)²", answer: ans, choices: makeChoices(for: ans, rng: &rng), mode: .power)
    }

    private static func rootQuestion(difficulty: Difficulty, rng: inout SeededRandom) -> Question {
        let r = range(difficulty, low: 6, mid: 12, high: 18, insane: 25)
        let root = rng.int(in: 2...r.upperBound)
        let square = root * root
        return Question(prompt: "√\(square)", answer: root, choices: makeChoices(for: root, rng: &rng), mode: .root)
    }

    /// Sequence: arithmetic, geometric, or square progression — show 4 terms, ask the 5th.
    private static func sequenceQuestion(difficulty: Difficulty, rng: inout SeededRandom) -> Question {
        let kind = rng.int(in: 0...2) // 0: arithmetic, 1: geometric, 2: squares
        switch kind {
        case 0:
            let start = rng.int(in: 1...20)
            let step = rng.int(in: 2...(difficulty == .insane ? 9 : 5))
            let terms = (0..<4).map { start + step * $0 }
            let ans = start + step * 4
            let prompt = terms.map(String.init).joined(separator: ", ") + ", ?"
            return Question(prompt: prompt, answer: ans, choices: makeChoices(for: ans, rng: &rng), mode: .sequence)
        case 1:
            let start = rng.int(in: 1...4)
            let ratio = rng.int(in: 2...(difficulty == .insane ? 4 : 3))
            var terms: [Int] = []
            var v = start
            for _ in 0..<4 { terms.append(v); v *= ratio }
            let ans = v
            let prompt = terms.map(String.init).joined(separator: ", ") + ", ?"
            return Question(prompt: prompt, answer: ans, choices: makeChoices(for: ans, rng: &rng), mode: .sequence)
        default:
            let start = rng.int(in: 1...8)
            let terms = (0..<4).map { (start + $0) * (start + $0) }
            let ans = (start + 4) * (start + 4)
            let prompt = terms.map(String.init).joined(separator: ", ") + ", ?"
            return Question(prompt: prompt, answer: ans, choices: makeChoices(for: ans, rng: &rng), mode: .sequence)
        }
    }

    // MARK: - Choice generator

    /// Always returns 4 unique non-negative integers including `correct`, shuffled deterministically.
    static func makeChoices(for correct: Int, rng: inout SeededRandom) -> [Int] {
        var options = Set<Int>([correct])
        // Pick a tight spread proportional to the magnitude (so a question about 144 doesn't
        // get foils like 1, 2, 3 which trivialize the choice).
        let spread = max(4, min(20, correct / 4 + 4))
        var safety = 0
        while options.count < 4 && safety < 200 {
            let offset = rng.int(in: -spread...spread)
            let wrong = correct + offset
            if wrong != correct && wrong >= 0 {
                options.insert(wrong)
            }
            safety += 1
        }
        // Fallback if we couldn't find enough close options (very small `correct`).
        var i = 1
        while options.count < 4 {
            options.insert(correct + i)
            i += 1
        }
        var arr = Array(options)
        // Deterministic Fisher–Yates with our seeded RNG.
        for k in stride(from: arr.count - 1, through: 1, by: -1) {
            let j = rng.int(in: 0...k)
            arr.swapAt(k, j)
        }
        return arr
    }
}
