# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

iOS/iPadOS SwiftUI app — a multiple-choice math game. **v2.0.0** is a major rebuild centered on a **Daily Challenge + streak/XP progression** retention loop, with ten game modes, Game Center, SwiftData persistence, audio/haptics, and a multi-platform reach (iPhone, iPad, plus watchOS and Mac Catalyst code that still needs targets created — see `MIGRATION.md`).

Target iOS 17.4+, Swift 5 language mode (built with Xcode 26 toolchain — `@Observable` and SwiftData are used). iPhone + iPad. Bundle IDs: `com.faacil.MathGame` (Release) and `com.faacil.MathGame-debug` (Debug). Localized in **en, es, fr, pt-BR** via `MathGame/Localizable.xcstrings`.

No tests, no SPM/CocoaPods/fastlane — just the Xcode project.

## Build & run

```bash
# Build for the iOS Simulator (no signing needed)
xcodebuild -project MathGame.xcodeproj -scheme MathGame \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build/ build

# Install & launch on a booted simulator
xcrun simctl boot "iPhone 17"; open -a Simulator
APP=$(find build/Build/Products/Debug-iphonesimulator -maxdepth 1 -name "MathGame.app")
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.faacil.MathGame-debug

# Clean
xcodebuild -project MathGame.xcodeproj -scheme MathGame clean
```

Day-to-day: `open MathGame.xcodeproj` and ⌘R.

## Architecture (v2)

Layered, `@Observable` MVVM with a pure Domain core reusable across platforms. Under `MathGame/`:

- `MathGameApp.swift` — `@main`; installs the SwiftData `.modelContainer`, warms up singletons, kicks off Game Center auth.
- `Domain/` — **pure Swift, no SwiftUI**. `Models.swift` (GameMode, Difficulty, Question, LivesConfig), `QuestionGenerator.swift` (+ `SeededRandom` for deterministic dailies), `Scoring.swift` (XP curve + scoring). This folder is what watchOS/Mac share.
- `Data/` — `PersistenceModels.swift` (SwiftData `@Model`: Player, BestScore, AchievementProgress, DailyChallengeRun), `PersistenceController.swift`, `ProgressionEngine.swift` (applies gameplay events to Player + achievements), `DailyChallengeService.swift` (deterministic daily by date seed), `AchievementCatalog.swift` (20 achievements), `GameCenterService.swift`, `NotificationScheduler.swift`.
- `Services/` — `AudioEngine.swift` (AVFoundation; `.caf` assets are added manually per MIGRATION), `HapticEngine.swift` (CoreHaptics + UIKit fallback).
- `Presentation/Theme/AppTheme.swift` — the single source of theme truth (`Color.app…`, `NeoCard`, animations). Vistas usan `Color.appBackground` etc. (fallbacks embebidos), no asset catalog directo.
- `Presentation/Atoms` (`AnswerButtonView`, `Atoms.swift`: HeartRow/StreakBadge/XPBar/ScorePill/TimerPill/StarRow), `Presentation/Molecules` (QuestionCard, FeedbackOverlay, ModeCard, DailyCard, SectionHeader).
- `Presentation/Pages` — `ContentView` (adaptive: NavigationStack on compact, NavigationSplitView on regular/iPad/Mac), `CalculationView` (in-session, drives `GameViewModel`), `DailyView`, `ProfileView`, `StatsView` (Swift Charts), `AchievementsView`, `OnboardingView`, `SettingsView`.
- `Presentation/ViewModels` — `GameViewModel`, `DailyViewModel`, `ProfileViewModel` (all `@MainActor @Observable`).
- `Enums/CalculationType.swift` — legacy 6-mode enum kept for the `GameMode.classicCalculation` bridge.

### Key invariants
- **Choices**: `QuestionGenerator.makeChoices` always returns 4 unique non-negative ints incl. the answer. Subtraction renders `a+b − b`; division renders `d1*d2 ÷ d2`; both guarantee small non-negative integer answers. Don't break these.
- **Daily determinism**: `DailyChallengeService` seeds an FNV-1a hash of `yyyy-MM-dd` → same 10 questions for everyone that calendar day. Needed for comparable leaderboards.
- **Streak**: only the Daily Challenge moves the streak (`ProgressionEngine.recordDailyCompletion`), reset if a calendar day is skipped.

## Adding files to the Xcode target

The project (objectVersion 56, Xcode-15-era format) does **not** use file-system-synchronized groups, so new `.swift` files must be registered in `project.pbxproj`. There's a helper: `scripts/inject_pbxproj.py` reading `scripts/pbx_plan.json` (PBXBuildFile + PBXFileReference + PBXGroup + Sources phase, deterministic UUIDs, idempotent). After running it, `plutil -lint MathGame.xcodeproj/project.pbxproj` should say OK. Or just add files via the Xcode UI.

## watchOS & Mac

`MathGameWatch/` holds watchOS code (app + 60s game + complication) but is **not in any target yet** — SourceKit will show errors for it until you create the Watch target and share `Domain/`. Mac is Catalyst (a capability toggle). Full steps in `MIGRATION.md`.

## Before shipping
See `MIGRATION.md` (manual steps: audio assets, Game Center IDs, Watch/Mac targets, capabilities, screenshots, submit) and `APP_STORE.md` (all store copy in 4 languages). Plan/roadmap context in `docs/v2.0.0-plan.md`.
