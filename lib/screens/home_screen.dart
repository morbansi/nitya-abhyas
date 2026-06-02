import 'package:flutter/material.dart';

import '../data/habit_store.dart';
import '../models/habit.dart';
import 'edit_habit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final store = HabitStore.instance;

  @override
  void initState() {
    super.initState();
    store.addListener(_onChange);
  }

  @override
  void dispose() {
    store.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  int get _bestStreakToday =>
      store.habits.fold(0, (m, h) => h.currentStreak > m ? h.currentStreak : m);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: store.habits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _HabitCard(
                  habit: store.habits[i],
                  onToggle: () => store.toggleToday(store.habits[i].id),
                  onEdit: () => _edit(store.habits[i]),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add),
        label: const Text('New habit'),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '🔥 Best run: $_bestStreakToday day${_bestStreakToday == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(Habit? habit) async {
    final result = await Navigator.of(context).push<EditResult>(
      MaterialPageRoute(builder: (_) => EditHabitScreen(habit: habit)),
    );
    if (result == null) return;
    if (result.deleted && habit != null) {
      await store.deleteHabit(habit.id);
    } else if (habit == null) {
      await store.addHabit(result.name, result.emoji, result.color);
    } else {
      await store.updateHabit(habit.id, result.name, result.emoji, result.color);
    }
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.onToggle,
    required this.onEdit,
  });

  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    final done = habit.isDoneToday;
    return Material(
      color: const Color(0xFF181A20),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onToggle,
        onLongPress: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(habit.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '🔥 ${habit.currentStreak}  ·  best ${habit.longestStreak}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.white.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
              _CheckCircle(done: done, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done, required this.color});
  final bool done;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: done ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: done ? color : Colors.white.withOpacity(0.25),
          width: 2,
        ),
      ),
      child: done
          ? const Icon(Icons.check, size: 20, color: Colors.white)
          : null,
    );
  }
}
