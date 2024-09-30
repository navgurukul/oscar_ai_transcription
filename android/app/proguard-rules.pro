# Keep all the dependencies that might be causing issues
-keep class com.google.android.play.** { *; }
-keepclassmembers class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

-keep class com.google.common.collect.** { *; }
-dontwarn com.google.common.collect.**

-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

-keep class com.google.android.gms.** { *; }
-keep class com.google.api.** { *; }

-keep class com.google.j2objc.annotations.** { *; }
-dontwarn com.google.j2objc.annotations.**

-keepattributes *Annotation*
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.analytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**



# Preserve the classes and methods related to authentication and token handling
-keep class com.yourpackage.authentication.** { *; }
-keep class com.yourpackage.token.** { *; }

# If using Retrofit for network requests
-keep class com.yourpackage.network.** { *; }
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn retrofit2.**
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes *Annotation*



# Suppress warnings about missing classes
-dontwarn java.awt.**
-dontwarn javax.swing.**
-dontwarn org.apache.http.**
-dontwarn android.webkit.JavascriptInterface
