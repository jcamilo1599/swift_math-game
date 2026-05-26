//
//  WatchHomeView.swift
//  MathGameWatch
//

import SwiftUI

struct WatchHomeView: View {
    @State private var goPlay = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "function")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.yellow)
                Text("Math Game")
                    .font(.system(.title3, design: .rounded, weight: .heavy))

                NavigationLink {
                    WatchGameView()
                } label: {
                    Label("60s Math", systemImage: "timer")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
            }
            .padding()
        }
    }
}
