# ==============================================================================
# ProGuard / R8 Rules for Private Chat Hub
# ==============================================================================
# These rules prevent R8 from stripping classes needed at runtime.

# ------------------------------------------------------------------------------
# Flutter & Dart
# ------------------------------------------------------------------------------
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ------------------------------------------------------------------------------
# LiteRT-LM (on-device inference)
# ------------------------------------------------------------------------------
# Keep all LiteRT-LM API classes used via JNI / reflection
-keep class com.google.ai.edge.litertlm.** { *; }
-keepclassmembers class com.google.ai.edge.litertlm.** { *; }
-dontwarn com.google.ai.edge.litertlm.**

# Keep the native method bridges
-keepclasseswithmembernames class * {
    native <methods>;
}

# ------------------------------------------------------------------------------
# Kotlin Coroutines
# ------------------------------------------------------------------------------
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}
-dontwarn kotlinx.coroutines.**

# ------------------------------------------------------------------------------
# OkHttp / HTTP (used transitively by some plugins)
# ------------------------------------------------------------------------------
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# ------------------------------------------------------------------------------
# App Plugin (LiteRTPlugin)
# ------------------------------------------------------------------------------
-keep class com.cmwen.private_chat_hub.LiteRTPlugin { *; }
-keep class com.cmwen.private_chat_hub.MainActivity { *; }

# ------------------------------------------------------------------------------
# Flutter Local Notifications
# ------------------------------------------------------------------------------
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# ------------------------------------------------------------------------------
# Connectivity Plus
# ------------------------------------------------------------------------------
-dontwarn dev.fluttercommunity.plus.**

# ------------------------------------------------------------------------------
# General safety
# ------------------------------------------------------------------------------
# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
