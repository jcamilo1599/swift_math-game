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
            .frame(width: 130, height: 130)
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(Color.white)
            .background(.orange)
            .clipShape(Circle())
            .padding()
    }
}

#Preview {
    AnswerButtonView(number: 10000)
}
