# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# WorkManager / Room fixes for AndroidX
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class androidx.sqlite.** { *; }
-keep class androidx.arch.core.** { *; }
-keep class androidx.lifecycle.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.play.core.**

# General AndroidX
-keep class androidx.startup.** { *; }

# Google ML Kit and GMS
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.play.** { *; }

# Fix R8 missing classes for SLF4J and iText (pdf_manipulator)
-dontwarn org.slf4j.**
-keep class com.itextpdf.** { *; }
-dontwarn com.itextpdf.**
