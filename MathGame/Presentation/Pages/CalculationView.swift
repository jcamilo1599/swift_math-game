//
//  CalculationView.swift
//  MathGame
//
//  Created by Juan Camilo Marín Ochoa on 17/03/24.
//

import SwiftUI

struct CalculationView: View {
    @StateObject private var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    
    init(action: CalculationType) {
        _viewModel = StateObject(wrappedValue: GameViewModel(operation: action))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                // Feedback Overlay
                viewModel.feedbackColor
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.2), value: viewModel.feedbackColor)
                
                let isLandscape = geometry.size.width > geometry.size.height
                
                VStack {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(0..<3) { index in
                                Image(systemName: "heart.fill")
                                    .foregroundColor(index < viewModel.lives ? .red : .gray.opacity(0.3))
                            }
                        }
                        Spacer()
                        Text("Score: \(viewModel.score)")
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundColor(.appAccent)
                    }
                    .padding()
                    
                    if isLandscape {
                        HStack(spacing: 20) {
                            // Question Card (Left Side)
                            VStack(spacing: 20) {
                                Text("Solve this")
                                    .font(.caption)
                                    .textCase(.uppercase)
                                    .foregroundColor(.gray)
                                
                                Text(viewModel.currentQuestion)
                                    .font(.system(size: 60, weight: .heavy, design: .default))
                                    .foregroundColor(.white)
                                    .shadow(color: .white.opacity(0.2), radius: 10, x: 0, y: 0)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                            .background(Color.appSurface)
                            .cornerRadius(30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(LinearGradient(colors: [.white.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                            )
                            .padding(.leading)
                            .padding(.bottom)
                            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            // Answers Grid (Right Side)
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                    ForEach(viewModel.choices, id: \.self) { choice in
                                        Button {
                                            viewModel.selectAnswer(choice)
                                        } label: {
                                            AnswerButtonView(number: choice)
                                        }
                                    }
                                }
                                .padding(.trailing)
                                .padding(.bottom)
                            }
                        }
                    } else {
                        // Portrait Layout
                        Spacer()
                        
                        // Question Card
                        VStack(spacing: 20) {
                            Text("Solve this")
                                .font(.caption)
                                .textCase(.uppercase)
                                .foregroundColor(.gray)
                            
                            Text(viewModel.currentQuestion)
                                .font(.system(size: 60, weight: .heavy, design: .default))
                                .foregroundColor(.white)
                                .shadow(color: .white.opacity(0.2), radius: 10, x: 0, y: 0)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .background(Color.appSurface)
                        .cornerRadius(30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(LinearGradient(colors: [.white.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        Spacer()
                        
                        // Answers Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.choices, id: \.self) { choice in
                                Button {
                                    viewModel.selectAnswer(choice)
                                } label: {
                                    AnswerButtonView(number: choice)
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
                .blur(radius: viewModel.isGameOver ? 10 : 0)
                
                // Game Over Modal
                if viewModel.isGameOver {
                    GameOverView(score: viewModel.score) {
                        viewModel.resetGame()
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// Subview for Game Over to keep main view clean
struct GameOverView: View {
    let score: Int
    let action: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 25) {
            Text("GAME OVER")
                .font(.system(size: 40, weight: .black))
                .foregroundColor(.red)
            
            VStack {
                Text("Final Score")
                    .foregroundColor(.gray)
                Text("\(score)")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Button(action: action) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(width: 200, height: 50)
                    .background(Color.appAccent)
                    .cornerRadius(25)
            }
            
            Button(action: { dismiss() }) {
                Text("Main Menu")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .padding(40)
        .background(Color.appSurface)
        .cornerRadius(30)
        .shadow(radius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.appAccent, lineWidth: 2)
        )
    }
}

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
        case .power:
            let base = Int.random(in: 2...10)
            correctAnswer = base * base
            currentQuestion = "\(base)²"
        case .root:
            let root = Int.random(in: 2...15)
            let square = root * root
            correctAnswer = root
            currentQuestion = "√\(square)"
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

#Preview {
    CalculationView(action: .addition)
}
