// StreakWidget.swift
// iOS home-screen widget. Reads the SAME json the Flutter app writes (via the
// App Group), renders the streak, and — on iOS 17+ — lets you tick a habit off
// right on the home screen through an AppIntent that wakes a Dart callback.
//
// SETUP (done once in Xcode, can't be scripted):
//   1. File ▸ New ▸ Target ▸ Widget Extension, name it "StreakWidget".
//   2. Add BOTH the Runner target and the StreakWidget target to the App Group
//      "group.com.example.streak" (Signing & Capabilities ▸ App Groups).
//   3. Add the `home_widget` pod to the widget target (the package README shows
//      the Podfile snippet) so `HomeWidgetBackgroundWorker` is available.
//   4. Replace the generated StreakWidget.swift with this file.

import WidgetKit
import SwiftUI
import AppIntents

private let appGroupId = "group.com.morbansi.nitya"
private let habitsKey = "habits_json"

// MARK: - Model

struct WidgetHabit: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let colorValue: Int
    let doneToday: Bool
    let streak: Int
}

private func todayKey() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: Date())
}

private func loadHabits() -> [WidgetHabit] {
    guard
        let defaults = UserDefaults(suiteName: appGroupId),
        let raw = defaults.string(forKey: habitsKey),
        let data = raw.data(using: .utf8),
        let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return [] }

    let today = todayKey()
    return arr.map { j in
        let days = (j["days"] as? [String]) ?? []
        let streak = currentStreak(days: Set(days))
        return WidgetHabit(
            id: j["id"] as? String ?? "",
            name: j["name"] as? String ?? "",
            emoji: j["emoji"] as? String ?? "🔥",
            colorValue: j["color"] as? Int ?? 0xFFFF6B35,
            doneToday: days.contains(today),
            streak: streak
        )
    }
}

private func currentStreak(days: Set<String>) -> Int {
    if days.isEmpty { return 0 }
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
    var cursor = Date()
    if !days.contains(f.string(from: cursor)) {
        cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor)!
        if !days.contains(f.string(from: cursor)) { return 0 }
    }
    var count = 0
    while days.contains(f.string(from: cursor)) {
        count += 1
        cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor)!
    }
    return count
}

// MARK: - Interactive toggle (iOS 17+)

@available(iOS 17.0, *)
struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit"

    @Parameter(title: "id") var id: String
    init() {}
    init(id: String) { self.id = id }

    func perform() async throws -> some IntentResult {
        // Wakes the Dart `widgetInteractivityCallback` in the background.
        await HomeWidgetBackgroundWorker.run(
            url: URL(string: "streak://toggle?id=\(id)"),
            appGroup: appGroupId
        )
        return .result()
    }
}

// MARK: - Timeline

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: Date(), habits: []) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: Date(), habits: loadHabits()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // Refresh after midnight so "today" rolls over.
        let next = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        completion(Timeline(entries: [Entry(date: Date(), habits: loadHabits())],
                            policy: .after(next)))
    }
}

struct Entry: TimelineEntry {
    let date: Date
    let habits: [WidgetHabit]
}

// MARK: - Views

struct StreakWidgetEntryView: View {
    var entry: Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        let shown = Array(entry.habits.prefix(family == .systemSmall ? 3 : 5))
        VStack(alignment: .leading, spacing: 8) {
            Text("Nitya Abhyas").font(.headline)
            if shown.isEmpty {
                Text("Add a habit in the app").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(shown) { h in HabitRow(habit: h) }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct HabitRow: View {
    let habit: WidgetHabit
    var body: some View {
        HStack(spacing: 8) {
            Text(habit.emoji)
            VStack(alignment: .leading, spacing: 0) {
                Text(habit.name).font(.caption).lineLimit(1)
                Text("🔥 \(habit.streak)").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if #available(iOS 17.0, *) {
                Button(intent: ToggleHabitIntent(id: habit.id)) {
                    Image(systemName: habit.doneToday ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(Color(rgb: habit.colorValue))
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: habit.doneToday ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(Color(rgb: habit.colorValue))
            }
        }
    }
}

extension Color {
    init(rgb: Int) {
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255)
    }
}

// MARK: - Widget

@main
struct StreakWidget: Widget {
    let kind = "NityaWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StreakWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Nitya Abhyas")
        .description("Keep your daily streak alive from the home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
