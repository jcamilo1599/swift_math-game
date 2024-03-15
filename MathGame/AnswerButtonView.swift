//
//  AnswerButtonView.swift
//  MathGame
//
//  Created by Juan Camilo Marín Ochoa on 14/03/24.
//

import SwiftUI

struct AnswerButtonView: View {
    var number : Int
    
    var body: some View {
        Text("\(number)")
            .frame(width: 110, height: 110)
            .font(.system(size: 30, weight: .bold))
            .foregroundColor(Color.white)
            .background(Color.orange)
            .clipShape(Circle())
            .padding()
    }
}

#Preview {
    AnswerButtonView(number: 1000)
}
