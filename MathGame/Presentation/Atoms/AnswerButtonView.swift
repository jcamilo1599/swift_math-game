//
//  AnswerButtonView.swift
//  MathGame — Presentation/Atoms
//

import SwiftUI

enum AnswerState {
    case idle
    case correct
    case wrong
    case dimmed
}

struct AnswerButtonView: View {
    let number: Int
    var accent: Color = .appPrimary
    var state: AnswerState = .idle
    var animateValue: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text("\(number)")
            .font(.system(size: 36, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .frame(maxWidth: .infinity, maxHeight: AppTheme.Buttons.height)
            .foregroundStyle(.white)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.20), lineWidth: 1)
            )
            .shadow(color: accent.opacity(state == .idle ? 0.35 : 0.15), radius: 10, x: 0, y: 5)
            .scaleEffect(scale)
            .opacity(state == .dimmed ? 0.4 : 1)
            .animation(reduceMotion ? .none : .appSnappy, value: state)
            .animation(reduceMotion ? .none : .appSnappy, value: animateValue)
            .accessibilityLabel(Text("a11y.answer.\(number)"))
    }

    private var background: some View {
        let base: [Color]
        switch state {
        case .idle, .dimmed:
            base = [accent.opacity(0.85), accent.opacity(0.6)]
        case .correct:
            base = [Color.appSuccess.opacity(0.9), Color.appSuccess.opacity(0.7)]
        case .wrong:
            base = [Color.appDanger.opacity(0.9), Color.appDanger.opacity(0.7)]
        }
        return LinearGradient(colors: base, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var scale: CGFloat {
        switch state {
        case .correct: 1.05
        case .wrong: 0.95
        default: 1.0
        }
    }
}

#Preview {
    HStack {
        AnswerButtonView(number: 42)
        AnswerButtonView(number: 13, accent: .red, state: .wrong)
        AnswerButtonView(number: 7, state: .correct)
    }
    .padding()
    .background(Color.appBackground)
}
