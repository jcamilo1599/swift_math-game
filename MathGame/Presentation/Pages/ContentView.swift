//
//  ContentView.swift
//  MathGame
//
//  Created by Juan Camilo Marín Ochoa on 14/03/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    CalculationView(
                        title: "addition",
                        action: CalculationType.addition
                    )
                } label: {
                    Text("addition")
                }
                
                NavigationLink {
                    CalculationView(
                        title: "subtraction",
                        action: CalculationType.subtraction
                    )
                } label: {
                    Text("subtraction")
                }
                
                NavigationLink {
                    CalculationView(
                        title: "division",
                        action: CalculationType.division
                    )
                } label: {
                    Text("division")
                }
                
                NavigationLink {
                    CalculationView(
                        title: "multiplication",
                        action: CalculationType.multiplication
                    )
                } label: {
                    Text("multiplication")
                }
            }
            .navigationTitle("appName")
        }
    }
}

#Preview {
    ContentView()
}
