# Flutter 核心
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# flutter_sound 原生层
-keep class com.dooboolab.** { *; }
-dontwarn com.dooboolab.**

# sqflite 数据库
-keep class com.tekartik.sqflite.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# JSON 序列化
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# 通用保护
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
