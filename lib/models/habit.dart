import 'dart:convert';

/// A single habit the user wants to keep a daily streak on.
///
/// Completions are stored as a set of "yyyy-mm-dd" day keys. Storing day keys
/// (not timestamps) keeps streak math timezone-stable and trivial to dedupe.
class Habit {
  Habit({
    required this.id,
    required this.name,
    this.emoji = '🔥',
    this.colorValue = 0xFFFF6B35,
    Set<String>? completedDays,
  }) : completedDays = completedDays ?? <String>{};

  final String id;
  String name;
  String emoji;
  int colorValue;
  final Set<String> completedDays;

  // ---- day-key helpers ----------------------------------------------------

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String todayKey() => dayKey(DateTime.now());

  bool get isDoneToday => completedDays.contains(todayKey());

  /// Toggle today's completion. Returns the new "done" state.
  bool toggleToday() {
    final key = todayKey();
    if (completedDays.contains(key)) {
      completedDays.remove(key);
      return false;
    }
    completedDays.add(key);
    return true;
  }

  /// Current consecutive-day streak ending today (or yesterday, so the streak
  /// isn't shown as broken until a full day has been missed).
  int get currentStreak {
    if (completedDays.isEmpty) return 0;
    var cursor = DateTime.now();
    // If today isn't done yet, the streak can still be alive from yesterday.
    if (!completedDays.contains(dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!completedDays.contains(dayKey(cursor))) return 0;
    }
    var count = 0;
    while (completedDays.contains(dayKey(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// Longest streak ever recorded.
  int get longestStreak {
    if (completedDays.isEmpty) return 0;
    final days = completedDays.map(DateTime.parse).toList()..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      if (gap == 1) {
        run++;
        if (run > best) best = run;
      } else if (gap > 1) {
        run = 1;
      }
    }
    return best;
  }

  // ---- serialization -------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'color': colorValue,
        'days': completedDays.toList(),
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: (j['emoji'] as String?) ?? '🔥',
        colorValue: (j['color'] as int?) ?? 0xFFFF6B35,
        completedDays:
            ((j['days'] as List?)?.cast<String>() ?? const []).toSet(),
      );

  static String encodeList(List<Habit> habits) =>
      jsonEncode(habits.map((h) => h.toJson()).toList());

  static List<Habit> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(Habit.fromJson).toList();
  }
}
