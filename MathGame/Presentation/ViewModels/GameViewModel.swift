import Foundation
import SwiftUI

class GameViewModel: ObservableObject {
    @Published var currentQuestion: String = ""
    @Published var choices: [Int] = []
    @Published var score: Int = 0
    @Published var lives: Int = 3
    @Published var isGameOver: Bool = false
    @Published var feedbackColor: Color = .clear
    
    private var correctAnswer: Int = 0
    private var selectedOperation: CalculationType
    
    init(operation: CalculationType) {
        self.selectedOperation = operation
        generateQuestion()
    }
    
    func generateQuestion() {
        let num1 = Int.random(in: 1...20)
        let num2 = Int.random(in: 1...20)
        
        switch selectedOperation {
        case .addition:
            correctAnswer = num1 + num2
            currentQuestion = "\(num1) + \(num2)"
        case .subtraction:
            correctAnswer = num1
            // Ensure positive results for simplicity
            currentQuestion = "\(num1 + num2) - \(num2)"
        case .multiplication:
            // Smaller numbers for multiplication to keep it playable
            let m1 = Int.random(in: 2...10)
            let m2 = Int.random(in: 2...10)
            correctAnswer = m1 * m2
            currentQuestion = "\(m1) × \(m2)"
        case .division:
            let d1 = Int.random(in: 2...10)
            let d2 = Int.random(in: 2...10)
            let product = d1 * d2
            correctAnswer = d1
            currentQuestion = "\(product) ÷ \(d2)"
        }
        
        generateChoices()
    }
    
    private func generateChoices() {
        var options = Set<Int>()
        options.insert(correctAnswer)
        
        while options.count < 4 {
            let offset = Int.random(in: -10...10)
            let wrongAnswer = correctAnswer + offset
            if wrongAnswer != correctAnswer && wrongAnswer >= 0 {
                options.insert(wrongAnswer)
            }
        }
        
        choices = Array(options).shuffled()
    }
    
    func selectAnswer(_ answer: Int) {
        if answer == correctAnswer {
            score += 10
            withAnimation {
                feedbackColor = .green.opacity(0.5)
            }
            // Delay for feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.feedbackColor = .clear
                self.generateQuestion()
            }
        } else {
            lives -= 1
            withAnimation {
                feedbackColor = .red.opacity(0.5)
            }
            if lives <= 0 {
                isGameOver = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.feedbackColor = .clear
                    self.generateQuestion()
                }
            }
        }
    }
    
    func resetGame() {
        score = 0
        lives = 3
        isGameOver = false
        generateQuestion()
    }
}
