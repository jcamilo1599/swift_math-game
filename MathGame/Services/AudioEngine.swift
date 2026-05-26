//
//  AudioEngine.swift
//  MathGame — Services
//
//  Pre-loads and plays short SFX. The actual .caf files are added in MIGRATION.md
//  (App Store-bound asset; not committable here). Missing files degrade gracefully.
//

import Foundation
import AVFoundation

enum SFX: String, CaseIterable {
    case correct
    case wrong
    case levelUp = "level_up"
    case streakMilestone = "streak_milestone"
    case dailyComplete = "daily_complete"
    case tap
    case navigation
    case achievement
    case timeTick = "time_tick"
    case gameOver = "game_over"

    var resourceName: String { rawValue }
}

@MainActor
final class AudioEngine: ObservableObject {

    static let shared = AudioEngine()

    @Published var enabled: Bool = true

    private var players: [SFX: AVAudioPlayer] = [:]

    private init() {
        configureSession()
        preload()
    }

    private func configureSession() {
        #if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
        // Use the ambient category so we don't fight background music apps.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true, options: [])
        #endif
    }

    private func preload() {
        for sfx in SFX.allCases {
            if let url = Bundle.main.url(forResource: sfx.resourceName, withExtension: "caf")
                ?? Bundle.main.url(forResource: sfx.resourceName, withExtension: "m4a")
                ?? Bundle.main.url(forResource: sfx.resourceName, withExtension: "wav") {
                if let p = try? AVAudioPlayer(contentsOf: url) {
                    p.prepareToPlay()
                    p.volume = volume(for: sfx)
                    players[sfx] = p
                }
            }
        }
    }

    func play(_ sfx: SFX) {
        guard enabled else { return }
        guard let p = players[sfx] else { return }
        if p.isPlaying { p.currentTime = 0 }
        p.play()
    }

    func setEnabled(_ value: Bool) {
        enabled = value
        if !value {
            players.values.forEach { $0.stop() }
        }
    }

    private func volume(for sfx: SFX) -> Float {
        switch sfx {
        case .tap, .navigation: return 0.4
        case .timeTick: return 0.5
        case .correct, .wrong: return 0.8
        default: return 0.9
        }
    }
}
