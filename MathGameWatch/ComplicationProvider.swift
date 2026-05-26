//
//  ComplicationProvider.swift
//  MathGameWatch
//
//  WidgetKit complications surfacing the current streak. Wire this up after creating
//  the Watch app target in Xcode (see MIGRATION.md).
//

import WidgetKit
import SwiftUI

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, streak: 5)
    }
    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(StreakEntry(date: .now, streak: readSharedStreak()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = StreakEntry(date: .now, streak: readSharedStreak())
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900))))
    }

    /// Stub: real implementation reads from an App Group UserDefaults shared with the iOS app.
    /// See MIGRATION.md for the App Group ID to use.
    private func readSharedStreak() -> Int {
        let groupID = "group.com.faacil.MathGame"
        return UserDefaults(suiteName: groupID)?.integer(forKey: "currentStreak") ?? 0
    }
}

struct StreakComplicationEntryView: View {
    let entry: StreakEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                Circle().stroke(Color.orange.opacity(0.4), lineWidth: 2)
                VStack(spacing: -2) {
                    Image(systemName: "flame.fill").foregroundStyle(.orange).font(.system(size: 10))
                    Text("\(entry.streak)").font(.system(.title3, design: .rounded, weight: .black)).monospacedDigit()
                }
            }
        case .accessoryInline:
            Text("🔥 \(entry.streak)-day streak")
        case .accessoryCorner:
            Text("\(entry.streak)")
                .font(.system(.title2, design: .rounded, weight: .black))
                .monospacedDigit()
                .widgetCurvesContent()
                .widgetLabel("Streak")
        default:
            Text("Streak: \(entry.streak)")
        }
    }
}

@main
struct MathGameComplications: WidgetBundle {
    var body: some Widget {
        StreakComplication()
    }
}

struct StreakComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "math.streak", provider: StreakProvider()) { entry in
            StreakComplicationEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Math Streak")
        .description("Your current Daily Challenge streak.")
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryCorner])
    }
}
