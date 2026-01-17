//
//  MathGameApp.swift
//  MathGame
//
//  Created by Juan Camilo Marín Ochoa on 14/03/24.
//

import SwiftUI

struct AppTheme {
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let accent = Color("Accent")
    
    // Fallback colors if assets are missing
    static let fallbackBackground = Color(red: 0.1, green: 0.1, blue: 0.15) // Dark Blue/Grey
    static let fallbackSurface = Color(red: 0.15, green: 0.15, blue: 0.22)
    static let fallbackPrimary = Color(red: 0.0, green: 0.8, blue: 0.8) // Cyan
    static let fallbackAccent = Color(red: 1.0, green: 0.8, blue: 0.0) // Gold/Yellow
    
    struct Buttons {
        static let radius: CGFloat = 20
        static let height: CGFloat = 80
    }
}

extension Color {
    static var appBackground: Color { AppTheme.fallbackBackground }
    static var appSurface: Color { AppTheme.fallbackSurface }
    static var appPrimary: Color { AppTheme.fallbackPrimary }
    static var appAccent: Color { AppTheme.fallbackAccent }
}

struct NeoCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.appSurface)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient(colors: [.white.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
    }
}

extension View {
    func neoCardStyle() -> some View {
        self.modifier(NeoCard())
    }
}

@main
struct MathGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
