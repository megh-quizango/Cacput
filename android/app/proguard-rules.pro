# Preserve source file and line numbers for Firebase Crashlytics stack traces.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep app entrypoint and generated Flutter plugin registrant.
-keep class com.creativemedia.capcut.MainActivity { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
