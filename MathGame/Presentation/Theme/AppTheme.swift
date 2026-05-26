//
//  AppTheme.swift
//  MathGame — Presentation
//
//  Single source of truth for design tokens. Replaces the duplicated definitions
//  that used to live in both `MathGameApp.swift` and `Presentation/Theme/AppTheme.swift`.
//

import SwiftUI

enum AppTheme {

    // MARK: - Asset-backed colors (fallback to baked-in values if the asset is missing)

    static var background: Color { Color("Background", bundle: .main) }
    static var surface: Color { Color("Surface", bundle: .main) }
    static var primary: Color { Color("Primary", bundle: .main) }
    static var secondary: Color { Color("Secondary", bundle: .main) }
    static var accent: Color { Color("Accent", bundle: .main) }

    // MARK: - Hard fallbacks used when assets aren't yet in the catalog

    static let fallbackBackground = Color(red: 0.07, green: 0.08, blue: 0.13)
    static let fallbackSurface = Color(red: 0.12, green: 0.13, blue: 0.20)
    static let fallbackPrimary = Color(red: 0.0, green: 0.78, blue: 0.82)
    static let fallbackAccent = Color(red: 1.0, green: 0.78, blue: 0.0)
    static let fallbackDanger = Color(red: 0.93, green: 0.32, blue: 0.40)
    static let fallbackSuccess = Color(red: 0.34, green: 0.78, blue: 0.55)

    /// Accent palette indexed by `GameMode.accentIndex`.
    static let modeAccents: [Color] = [
        Color(red: 0.31, green: 0.62, blue: 0.99),  // blue
        Color(red: 0.93, green: 0.32, blue: 0.40),  // red
        Color(red: 0.99, green: 0.62, blue: 0.20),  // orange
        Color(red: 0.69, green: 0.41, blue: 0.99),  // purple
        Color(red: 0.34, green: 0.78, blue: 0.55),  // green
        Color(red: 0.20, green: 0.78, blue: 0.85),  // cyan
    ]

    // MARK: - Sizes

    enum Buttons {
        static let radius: CGFloat = 20
        static let height: CGFloat = 80
    }

    enum Cards {
        static let radius: CGFloat = 26
        static let stroke: CGFloat = 1
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 20
        static let xl: CGFloat = 32
    }
}

// MARK: - Convenience accessors

extension Color {
    static var appBackground: Color { AppTheme.fallbackBackground }
    static var appSurface: Color { AppTheme.fallbackSurface }
    static var appPrimary: Color { AppTheme.fallbackPrimary }
    static var appAccent: Color { AppTheme.fallbackAccent }
    static var appDanger: Color { AppTheme.fallbackDanger }
    static var appSuccess: Color { AppTheme.fallbackSuccess }

    static func modeAccent(for index: Int) -> Color {
        AppTheme.modeAccents[(index % AppTheme.modeAccents.count + AppTheme.modeAccents.count) % AppTheme.modeAccents.count]
    }
}

// MARK: - NeoCard modifier

struct NeoCard: ViewModifier {
    var radius: CGFloat = AppTheme.Cards.radius
    var tint: Color = .white

    func body(content: Content) -> some View {
        content
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [tint.opacity(0.18), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: AppTheme.Cards.stroke
                    )
            )
            .shadow(color: Color.black.opacity(0.30), radius: 14, x: 0, y: 8)
    }
}

extension View {
    func neoCardStyle(radius: CGFloat = AppTheme.Cards.radius, tint: Color = .white) -> some View {
        modifier(NeoCard(radius: radius, tint: tint))
    }
}

// MARK: - Reduce-motion aware animations

extension Animation {
    static var appSpring: Animation { .spring(response: 0.42, dampingFraction: 0.78) }
    static var appSnappy: Animation { .spring(response: 0.25, dampingFraction: 0.85) }
}
