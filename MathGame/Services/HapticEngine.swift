//
//  HapticEngine.swift
//  MathGame — Services
//
//  CoreHaptics on iPhone with UIImpactFeedbackGenerator fallback (iPad without
//  TapticEngine, Mac, Simulator). On watchOS, WKInterfaceDevice.play is used.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreHaptics)
import CoreHaptics
#endif

enum HapticEvent {
    case tap
    case success
    case error
    case warning
    case milestone
    case victory
}

@MainActor
final class HapticEngine: ObservableObject {

    static let shared = HapticEngine()

    @Published var enabled: Bool = true

    #if canImport(CoreHaptics)
    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    #endif

    private init() {
        startEngine()
    }

    func setEnabled(_ value: Bool) {
        enabled = value
        if value {
            startEngine()
        }
    }

    func play(_ event: HapticEvent) {
        guard enabled else { return }
        #if canImport(CoreHaptics)
        if supportsHaptics {
            playCoreHaptics(event)
            return
        }
        #endif
        #if canImport(UIKit)
        playUIKit(event)
        #endif
    }

    // MARK: - Engine lifecycle

    private func startEngine() {
        #if canImport(CoreHaptics)
        guard supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.stoppedHandler = { [weak self] _ in
                // Restart on next play.
                self?.engine = nil
            }
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            engine = nil
        }
        #endif
    }

    #if canImport(CoreHaptics)
    private func playCoreHaptics(_ event: HapticEvent) {
        let pattern: CHHapticPattern
        do {
            pattern = try buildPattern(for: event)
        } catch {
            playUIKitFallback(event)
            return
        }
        do {
            if engine == nil { startEngine() }
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            playUIKitFallback(event)
        }
    }

    private func buildPattern(for event: HapticEvent) throws -> CHHapticPattern {
        switch event {
        case .tap:
            return try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.5),
                    .init(parameterID: .hapticSharpness, value: 0.6),
                ], relativeTime: 0)
            ], parameters: [])
        case .success:
            return try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.7),
                    .init(parameterID: .hapticSharpness, value: 0.8),
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    .init(parameterID: .hapticIntensity, value: 1.0),
                    .init(parameterID: .hapticSharpness, value: 1.0),
                ], relativeTime: 0.08),
            ], parameters: [])
        case .error:
            return try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    .init(parameterID: .hapticIntensity, value: 1.0),
                    .init(parameterID: .hapticSharpness, value: 0.2),
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.7),
                    .init(parameterID: .hapticSharpness, value: 0.2),
                ], relativeTime: 0.12),
            ], parameters: [])
        case .warning:
            return try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.6),
                    .init(parameterID: .hapticSharpness, value: 0.4),
                ], relativeTime: 0)
            ], parameters: [])
        case .milestone:
            return try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.8),
                    .init(parameterID: .hapticSharpness, value: 0.7),
                ], relativeTime: 0, duration: 0.25)
            ], parameters: [])
        case .victory:
            return try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    .init(parameterID: .hapticIntensity, value: 1.0),
                    .init(parameterID: .hapticSharpness, value: 0.8),
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    .init(parameterID: .hapticIntensity, value: 1.0),
                    .init(parameterID: .hapticSharpness, value: 0.8),
                ], relativeTime: 0.12),
                CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    .init(parameterID: .hapticIntensity, value: 1.0),
                    .init(parameterID: .hapticSharpness, value: 1.0),
                ], relativeTime: 0.28, duration: 0.4),
            ], parameters: [])
        }
    }

    private func playUIKitFallback(_ event: HapticEvent) {
        #if canImport(UIKit)
        playUIKit(event)
        #endif
    }
    #endif

    #if canImport(UIKit)
    private func playUIKit(_ event: HapticEvent) {
        switch event {
        case .tap:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .milestone:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .victory:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    #endif
}
