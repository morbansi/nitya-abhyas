import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'data/habit_store.dart';
import 'screens/home_screen.dart';

/// Background callback invoked by home_widget when a widget button is tapped.
///
/// Runs in a separate isolate, so it must be top-level/static and annotated
/// with @pragma('vm:entry-point') so the engine can find it. The widget sends
/// a uri like: streak://toggle?id=<habitId>
@pragma('vm:entry-point')
Future<void> widgetInteractivityCallback(Uri? uri) async {
  if (uri == null) return;
  if (uri.host == 'toggle') {
    final id = uri.queryParameters['id'];
    if (id != null) {
      await HomeWidget.setAppGroupId(HabitStore.iosAppGroupId);
      await HabitStore.instance.toggleFromWidget(id);
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidget.setAppGroupId(HabitStore.iosAppGroupId);
  await HomeWidget.registerInteractivityCallback(widgetInteractivityCallback);
  await HabitStore.instance.init();
  runApp(const NityaApp());
}

class NityaApp extends StatelessWidget {
  const NityaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nitya Abhyas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF6B35),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E0F13),
      ),
      home: const HomeScreen(),
    );
  }
}
