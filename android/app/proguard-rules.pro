# R8/ProGuard keep rules for the release build.
#
# The Flutter Gradle plugin already applies Flutter's own engine/plugin rules;
# these cover the one plugin here that reaches classes by reflection.

# flutter_local_notifications serialises scheduled-notification payloads with
# Gson, which R8 would otherwise strip/obfuscate — causing crashes when an
# adhan notification is scheduled or fires. Keep the plugin + Gson intact.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Gson relies on generic type tokens surviving shrinking.
-keep class * extends com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken

# Silence warnings for annotations pulled in transitively by Gson.
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
