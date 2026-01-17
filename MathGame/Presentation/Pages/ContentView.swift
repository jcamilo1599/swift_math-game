//
//  ContentView.swift
//  MathGame
//
//  Created by Juan Camilo Marín Ochoa on 14/03/24.
//

import SwiftUI

struct ContentView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Math Challenge")
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        Text("Choose your mode")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            MenuCard(title: "Addition", icon: "plus", color: .blue, type: .addition)
                            MenuCard(title: "Subtraction", icon: "minus", color: .red, type: .subtraction)
                            MenuCard(title: "Multiplication", icon: "multiply", color: .orange, type: .multiplication)
                            MenuCard(title: "Division", icon: "divide", color: .purple, type: .division)
                            MenuCard(title: "Square", icon: "bolt.fill", color: .green, type: .power)
                            MenuCard(title: "Square Root", icon: "x.squareroot", color: .cyan, type: .root)
                        }
                        .padding()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct MenuCard: View {
    let title: String
    let icon: String
    let color: Color
    let type: CalculationType
    
    var body: some View {
        NavigationLink(destination: CalculationView(action: type)) {
            VStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(color)
                    .frame(width: 70, height: 70)
                    .background(color.opacity(0.2))
                    .clipShape(Circle())
                
                Text(LocalizedStringKey(title))
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(Color.appSurface)
            .cornerRadius(20)
            .shadow(color: color.opacity(0.3), radius: 8, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ContentView()
}
