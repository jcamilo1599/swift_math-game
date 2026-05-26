//
//  DailyChallengeService.swift
//  MathGame — Data
//
//  Daily Challenge generation. Same day ⇒ same 10 questions ⇒ scoreboards comparable.
//

import Foundation

struct DailyChallenge: Hashable {
    let dayKey: String       // yyyy-MM-dd in user's calendar
    let questions: [Question]
}

enum DailyChallengeService {

    static let questionCount = 10

    /// Build today's challenge deterministically. Seed = epoch-day so timezones
    /// matter (each user's calendar day defines their challenge), but every device
    /// of the same user on the same day yields the same sequence.
    static func challenge(for date: Date = .now, calendar: Calendar = .current) -> DailyChallenge {
        let dayKey = dayKey(for: date, calendar: calendar)
        let seed = seed(for: dayKey)
        var rng = SeededRandom(seed: seed)

        // Mode rotation over the 10 questions; difficulty ramps mid-way.
        let pool: [GameMode] = [.addition, .subtraction, .multiplication, .division, .power, .root]
        var questions: [Question] = []
        for i in 0..<questionCount {
            let mode = pool[rng.int(in: 0...(pool.count - 1))]
            let difficulty: Difficulty
            switch i {
            case 0..<3: difficulty = .easy
            case 3..<7: difficulty = .normal
            case 7..<9: difficulty = .hard
            default: difficulty = .insane
            }
            questions.append(QuestionGenerator.generate(mode: mode, difficulty: difficulty, rng: &rng))
        }

        return DailyChallenge(dayKey: dayKey, questions: questions)
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    static func seed(for dayKey: String) -> UInt64 {
        // FNV-1a hash of the dayKey, stable across platforms.
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in dayKey.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100_0000_01b3
        }
        return hash == 0 ? 1 : hash
    }

    /// Seconds until next local midnight, for countdown UI.
    static func secondsUntilNextChallenge(now: Date = .now, calendar: Calendar = .current) -> TimeInterval {
        let nextMidnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime) ?? now.addingTimeInterval(86_400)
        return nextMidnight.timeIntervalSince(now)
    }
}
