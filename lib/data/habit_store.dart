import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/habit.dart';

/// The one place that reads/writes habit data and keeps the native home-screen
/// widgets in sync. Both the app UI and the widget read the SAME json string
/// (key: "habits_json") out of the shared store that home_widget manages.
///
/// iOS: data lives in the App Group container's UserDefaults.
/// Android: data lives in HomeWidgetPlugin's SharedPreferences.
class HabitStore extends ChangeNotifier {
  HabitStore._();
  static final HabitStore instance = HabitStore._();

  /// Must match the App Group id you configure in Xcode (Runner + widget).
  static const String iosAppGroupId = 'group.com.morbansi.nitya';

  /// Keys shared with the native widgets.
  static const String kHabitsJson = 'habits_json';

  /// Native widget provider/extension names (used by HomeWidget.updateWidget).
  static const String androidWidgetName = 'NityaWidgetProvider';
  static const String iosWidgetKind = 'NityaWidget';

  final List<Habit> habits = [];

  Future<void> init() async {
    await HomeWidget.setAppGroupId(iosAppGroupId);
    await _load();
    if (habits.isEmpty) _seedDefaults();
    await _persistAndSync();
  }

  Future<void> _load() async {
    final raw = await HomeWidget.getWidgetData<String>(kHabitsJson);
    habits
      ..clear()
      ..addAll(Habit.decodeList(raw));
  }

  void _seedDefaults() {
    habits.addAll([
      Habit(id: _id(), name: 'Workout', emoji: '🏋️', colorValue: 0xFFEF476F),
      Habit(id: _id(), name: 'Read 20 min', emoji: '📚', colorValue: 0xFF118AB2),
      Habit(id: _id(), name: 'Meditate', emoji: '🧘', colorValue: 0xFF06D6A0),
    ]);
  }

  // ---- mutations -----------------------------------------------------------

  Future<void> toggleToday(String habitId) async {
    final h = habits.firstWhere((e) => e.id == habitId);
    h.toggleToday();
    await _persistAndSync();
  }

  Future<void> addHabit(String name, String emoji, int color) async {
    habits.add(Habit(id: _id(), name: name, emoji: emoji, colorValue: color));
    await _persistAndSync();
  }

  Future<void> updateHabit(String id, String name, String emoji, int color) async {
    final h = habits.firstWhere((e) => e.id == id);
    h
      ..name = name
      ..emoji = emoji
      ..colorValue = color;
    await _persistAndSync();
  }

  Future<void> deleteHabit(String id) async {
    habits.removeWhere((e) => e.id == id);
    await _persistAndSync();
  }

  /// Called from the background interactivity callback when a widget checkbox
  /// is tapped. Reloads from storage first so we don't clobber app-side edits.
  Future<void> toggleFromWidget(String habitId) async {
    await _load();
    final idx = habits.indexWhere((e) => e.id == habitId);
    if (idx == -1) return;
    habits[idx].toggleToday();
    await _persistAndSync();
  }

  // ---- persistence + widget sync ------------------------------------------

  Future<void> _persistAndSync() async {
    await HomeWidget.saveWidgetData<String>(kHabitsJson, Habit.encodeList(habits));
    await HomeWidget.updateWidget(
      name: androidWidgetName,
      iOSName: iosWidgetKind,
    );
    notifyListeners();
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
}
