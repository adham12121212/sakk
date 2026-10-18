# R8 rules for release builds. Flutter's Gradle plugin adds this file to the
# release build type next to proguard-android-optimize.txt and its own rules.
#
# Dart code (Supabase, JSON models, cubits) isn't touched by R8: it's compiled
# ahead of time into libapp.so. Its names are obfuscated by
# `flutter build --obfuscate` instead; JSON keys are strings and survive.
# Most plugins ship their own consumer rules; the ones below cover the
# libraries that use reflection or serialization and have broken release
# builds before.

# Readable Crashlytics stack traces (upload the mapping file to Firebase).
-keepattributes SourceFile,LineNumberTable,*Annotation*,Signature,InnerClasses,EnclosingMethod
-keep public class * extends java.lang.Exception

# Google Sign-In through Credential Manager (google_sign_in 7): the Play
# Services provider is loaded by reflection.
-if class androidx.credentials.CredentialManager
-keep class androidx.credentials.playservices.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }

# flutter_local_notifications saves scheduled notifications with Gson; R8
# stripping their fields makes reminders vanish after a reboot.
-keep class com.dexterous.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

# RevenueCat (purchases_flutter): the SDK ships consumer rules; keep the
# hybrid layer the Flutter plugin maps CustomerInfo and offerings through.
-keep class com.revenuecat.purchases.hybridcommon.** { *; }

# local_auth (androidx.biometric) and the home screen widget provider are
# referenced from the manifest or the plugin, which R8 keeps on its own.
-keep class com.sakk.app.WarrantyWidgetProvider { *; }

# Flutter's engine references Play Core for deferred components, which this
# app doesn't use.
-dontwarn com.google.android.play.core.**
