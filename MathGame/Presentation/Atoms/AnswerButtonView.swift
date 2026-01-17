//
//  AnswerButtonView.swift
//  MathGame
//
//  Created by Juan Camilo Marín Ochoa on 14/03/24.
//

import SwiftUI

struct AnswerButtonView: View {
    var number: Int
    
    var body: some View {
        Text("\(number)")
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity, maxHeight: 80)
            .background(
                LinearGradient(
                    colors: [Color.appPrimary.opacity(0.8), Color.appPrimary.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Color.appPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    AnswerButtonView(number: 100)
        .padding()
        .background(Color.black)
}
