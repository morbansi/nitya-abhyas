# home_widget uses WorkManager in release; R8 strips reflection-instantiated classes.
-keep class androidx.work.** { <init>(...); }
-keep class androidx.work.impl.** { *; }
-keep class androidx.startup.** { *; }

# Widget provider must stay discoverable by class name in release.
-keep class com.morbansi.nitya.NityaWidgetProvider { *; }
-keep class es.antonborri.home_widget.** { *; }
