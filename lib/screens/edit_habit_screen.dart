import 'package:flutter/material.dart';

import '../models/habit.dart';

class EditResult {
  EditResult({
    required this.name,
    required this.emoji,
    required this.color,
    this.deleted = false,
  });
  final String name;
  final String emoji;
  final int color;
  final bool deleted;
}

class EditHabitScreen extends StatefulWidget {
  const EditHabitScreen({super.key, this.habit});
  final Habit? habit;

  @override
  State<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<EditHabitScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.habit?.name ?? '');
  late String _emoji = widget.habit?.emoji ?? '🔥';
  late int _color = widget.habit?.colorValue ?? _palette.first;

  static const _emojis = [
    '🔥', '🏋️', '📚', '🧘', '💧', '🏃', '🥗', '😴', '💻', '🎸', '🧹', '🙏'
  ];
  static const _palette = [
    0xFFFF6B35, 0xFFEF476F, 0xFF118AB2, 0xFF06D6A0, 0xFFFFD166, 0xFF8338EC
  ];

  bool get _editing => widget.habit != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit habit' : 'New habit'),
        actions: [
          if (_editing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => Navigator.pop(
                context,
                EditResult(name: '', emoji: _emoji, color: _color, deleted: true),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            autofocus: !_editing,
            decoration: const InputDecoration(
              labelText: 'What do you want to do daily?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emojis.map((e) {
              final sel = e == _emoji;
              return GestureDetector(
                onTap: () => setState(() => _emoji = e),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel ? Color(_color).withOpacity(0.25) : const Color(0xFF181A20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? Color(_color) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 22)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: _palette.map((c) {
              final sel = c == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              final name = _name.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(
                context,
                EditResult(name: name, emoji: _emoji, color: _color),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_editing ? 'Save' : 'Add habit'),
            ),
          ),
        ],
      ),
    );
  }
}
