//
//  CalculationView.swift
//  MathGame
//
//  Created by Juan Camilo Marín Ochoa on 17/03/24.
//

import SwiftUI

struct CalculationView: View {
    // Parámetros
    var title: String;
    var action: CalculationType;

    // Numeros para la operación
    @State private var firstNumber = 0
    @State private var secondNumber = 0
    
    // Lista de opciones
    @State private var choiceArray : [Int] = [0, 1, 2, 3]
    
    // Dificultad del juego
    @State private var difficulty = 1000
    
    // Cantidad de respuestas correctas sin fallar
    @State private var record = 0
    
    // Determina si la respuesta fue correcta o no
    @State private var isCorrect = false
    
    // Determina si es la primer pregunta o no
    @State private var isFirstAnswer = true
    
    // Valor de la respuesta correcta de la operación
    @State private var correctAnswer = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("\(firstNumber) \(getSign()) \(secondNumber)")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 20)
                
                HStack {
                    ForEach(0..<2) { index in
                        Button {
                            answerIsCorrect(answer: choiceArray[index])
                            generateAnswers()
                        } label: {
                            AnswerButtonView(number: choiceArray[index])
                        }
                    }
                }
                
                HStack {
                    ForEach(2..<4) { index in
                        Button {
                            answerIsCorrect(answer: choiceArray[index])
                            generateAnswers()
                        } label: {
                            AnswerButtonView(number: choiceArray[index])
                        }
                    }
                }
                
                if (!isFirstAnswer) {
                    Text(isCorrect ? "successMessage" : "failureMessage")
                        .foregroundColor(isCorrect ? .green : .red)
                        .font(.headline)
                        .bold()
                        .padding(.top, 20)
                }
            }
            .onAppear(perform: generateAnswers)
            .navigationTitle(NSLocalizedString(title, comment: ""))
            .navigationBarItems(
                trailing: Text("record \(String(record))")
                    .font(.headline)
                    .bold()
            )
        }
        
    }
    
    private func answerIsCorrect(answer: Int) {
        isCorrect = answer == correctAnswer;
        isFirstAnswer = false;
        
        if isCorrect {
            record += 1
        } else {
            record = 0
        }
    }
    
    private func generateAnswers() {
        var answerList = [Int]()
        
        switch action {
        case .addition: 
            firstNumber = Int.random(in: 0...(difficulty / 2))
            secondNumber = Int.random(in: 0...(difficulty / 2))
            correctAnswer = firstNumber + secondNumber
            
            for _ in 0...2 {
                answerList.append(Int.random(in: 0...difficulty))
            }
        case .subtraction:
            firstNumber = Int.random(in: 0...difficulty)
            secondNumber = Int.random(in: 0...difficulty)
            correctAnswer = firstNumber - secondNumber
            
            for _ in 0...2 {
                answerList.append(Int.random(in: -difficulty...difficulty))
            }
        case .division:
            firstNumber = Int.random(in: 0...difficulty)
            secondNumber = Int.random(in: 0...(difficulty / 10))
            correctAnswer = firstNumber / secondNumber
            
            for _ in 0...2 {
                answerList.append(Int.random(in: 0...difficulty))
            }
        case .multiplication:
            firstNumber = Int.random(in: 0...(difficulty / 10))
            secondNumber = Int.random(in: 0...(difficulty / 10))
            correctAnswer = firstNumber * secondNumber
            
            for _ in 0...2 {
                answerList.append(Int.random(in: 0...(difficulty * 10)))
            }
        }
        
        answerList.append(correctAnswer)
        choiceArray = answerList.shuffled()
    }
    
    private func getSign() -> String {
        let sign: String;

        switch action {
        case .addition: sign = "+";
        case .subtraction: sign = "-";
        case .division: sign = "÷";
        case .multiplication: sign = "×"
        }
        
        return sign;
    }
}

#Preview {
    CalculationView(
        title: "multiplication",
        action: CalculationType.multiplication
    )
}
