//
//  ContentView.swift
//  MathGame
//
//  Created by Juan Camilo Marín Ochoa on 14/03/24.
//

import SwiftUI

struct ContentView: View {
    @State private var correctAnswer = 0
    @State private var choiceArray : [Int] = [0, 1, 2, 3]
    @State private var firstNumber = 0
    @State private var secondNumber = 0
    @State private var difficulty = 1000
    @State private var score = 0
    @State private var isCorrect = false
    @State private var isFirstAnswer = true
    
    var body: some View {
        NavigationView {
            VStack {
                Text("\(firstNumber) + \(secondNumber)")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 20)
                
                HStack {
                    ForEach(0..<2) {index in
                        Button {
                            answerIsCorrect(answer: choiceArray[index])
                            generateAnswers()
                        } label: {
                            AnswerButtonView(number: choiceArray[index])
                        }
                    }
                }
                
                HStack {
                    ForEach(2..<4) {index in
                        Button {
                            answerIsCorrect(answer: choiceArray[index])
                            generateAnswers()
                        } label: {
                            AnswerButtonView(number: choiceArray[index])
                        }
                    }
                }
                
                if (!isFirstAnswer) {
                    Text(isCorrect ? "successMessageKeepGoing" : "failureMessageContinue")
                        .foregroundColor(isCorrect ? .green : .red)
                        .font(.headline)
                        .bold()
                        .padding(.top, 20)
                }
            }
            .onAppear(perform: generateAnswers)
            .navigationTitle("appName")
            
            .navigationBarItems(
                trailing: Text("score \(String(score))")
                    .font(.headline)
                    .bold()
            )
        }
        
    }
    
    func answerIsCorrect(answer: Int){
        self.isCorrect = answer == correctAnswer;
        self.isFirstAnswer = false;
        
        if answer == correctAnswer {
            self.score += 1
        } else {
            self.score -= 1
        }
    }
    
    
    func generateAnswers(){
        firstNumber = Int.random(in: 0...(difficulty/2))
        secondNumber = Int.random(in: 0...(difficulty/2))
        var answerList = [Int]()
        
        correctAnswer = firstNumber + secondNumber
        
        for _ in 0...2 {
            answerList.append(Int.random(in: 0...difficulty))
        }
        
        answerList.append(correctAnswer)
        
        choiceArray = answerList.shuffled()
    }
}

#Preview {
    ContentView()
}
