//
//  OnboardingView.swift
//  MathGame — Presentation/Pages
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page: Int = 0

    private let pages: [OnboardingPage] = [
        .init(
            icon: "function",
            titleKey: "onboarding.1.title",
            bodyKey: "onboarding.1.body",
            accent: .appPrimary
        ),
        .init(
            icon: "sun.max.fill",
            titleKey: "onboarding.2.title",
            bodyKey: "onboarding.2.body",
            accent: .appAccent
        ),
        .init(
            icon: "flame.fill",
            titleKey: "onboarding.3.title",
            bodyKey: "onboarding.3.body",
            accent: .orange
        ),
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                        OnboardingPageView(page: p).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { idx in
                        Capsule()
                            .fill(idx == page ? Color.appAccent : Color.white.opacity(0.2))
                            .frame(width: idx == page ? 22 : 8, height: 8)
                            .animation(.appSpring, value: page)
                    }
                }
                .padding(.bottom, 18)

                Button {
                    if page < pages.count - 1 {
                        withAnimation(.appSpring) { page += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "onboarding.next" : "onboarding.start")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appAccent, in: Capsule())
                        .padding(.horizontal, AppTheme.Spacing.xl)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let titleKey: LocalizedStringKey
    let bodyKey: LocalizedStringKey
    let accent: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(page.accent.opacity(0.18)).frame(width: 200, height: 200)
                Image(systemName: page.icon)
                    .font(.system(size: 90))
                    .foregroundStyle(page.accent)
            }
            Text(page.titleKey)
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(page.bodyKey)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
}
