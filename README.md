# 🔥 Nitya Abhyas

A cross-platform daily streak / habit tracker. One Flutter codebase for the app,
plus a native home-screen **widget** on each platform that shows your streaks and
— on iOS 17+ and all modern Android — lets you tick a habit off **without opening
the app**.

The three home-screen modes you asked for:

| Mode | What it is | Where it lives |
|------|-----------|----------------|
| **App (mandatory)** | Full UI: add/edit habits, history, streaks | tap the app icon |
| **Display widget** (optional) | Glanceable streak counts, read-only | small/medium widget |
| **Interactive widget** (optional) | Tap the circle to mark today done | same widget, iOS 17+ / Android |

The app and both widgets read/write the **same** JSON (`habits_json`) through a
shared store, so everything stays in sync.

---

## Project layout

```
lib/
  main.dart                     app entry + widget interactivity callback
  models/habit.dart             Habit model + streak math + (de)serialization
  data/habit_store.dart         single source of truth; persists + syncs widgets
  screens/home_screen.dart      today list, tap-to-toggle
  screens/edit_habit_screen.dart  add / edit / delete
ios/StreakWidget/StreakWidget.swift          iOS WidgetKit widget (drop into the extension target)
android/app/src/main/kotlin/.../NityaWidgetProvider.kt   Android widget provider
android/app/src/main/res/...                 widget layout + icons + metadata
android/app/src/main/AndroidManifest_snippet.xml   what to paste into the manifest
```

## Step 0 — generate the platform scaffolding

This repo is the **source you drop into a Flutter project**. On a machine with
Flutter installed:

```bash
flutter create . --org com.morbansi --project-name nitya
flutter pub get
```

`flutter create .` generates the `android/`, `ios/`, etc. wrappers without
overwriting the `lib/` and widget files in this repo. Then copy/keep the widget
files in place (they're already in the right paths).

## Step 1 — Android (≈5 min)flutter doctor

1. Open `android/app/src/main/AndroidManifest.xml` and paste in the contents of
   `AndroidManifest_snippet.xml` (inside `<application>`).
2. Make sure the package in `NityaWidgetProvider.kt` matches your `--org`
   (here `com.morbansi.nitya`).
3. `flutter run` on an Android device/emulator. Long-press the home screen ▸
   Widgets ▸ Nitya Abhyas.

Android supports the tappable checkmark out of the box.

## Step 2 — iOS (≈15 min, needs a Mac + Xcode)

1. `open ios/Runner.xcworkspace`.
2. **File ▸ New ▸ Target ▸ Widget Extension**, name it `StreakWidget`
   (uncheck "Include Configuration Intent").
3. Replace the generated `StreakWidget.swift` with the one in `ios/StreakWidget/`.
4. **Signing & Capabilities** ▸ add **App Groups** to BOTH the `Runner` target
   and the `StreakWidget` target, using id `group.com.morbansi.nitya`
   (must match `HabitStore.iosAppGroupId` in Dart).
5. Add the `home_widget` pod to the widget target — see the package README's
   Podfile snippet — so `HomeWidgetBackgroundWorker` resolves.
6. `flutter run` on an iOS 17+ device. Add the widget from the home screen.

> If you change the App Group id, change it in three places: the Dart constant,
> the Swift `appGroupId`, and both Xcode capabilities.

## Notes / gotchas

- **iOS widget refreshes are budgeted** by WidgetKit — updates after a tap are
  usually quick but not guaranteed-instant. Fine for a once-a-day streak.
- Below **iOS 17** the widget still shows streaks; the tap just opens the app
  instead of toggling (graceful fallback).
- Everything is **local-first** — no server. To sync across devices later, swap
  the storage layer for iCloud / a tiny backend; nothing else needs to change.
- Default seed habits live in `HabitStore._seedDefaults()` — delete or edit.

## Versions

Built against `home_widget ^0.7.0`. The iOS interactive API
(`HomeWidgetBackgroundWorker.run`) tracks that package; if you bump the version,
check its README in case the call signature moved.
