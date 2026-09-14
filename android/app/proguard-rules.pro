# Keep llama_flutter_android native JNI bridge classes
-keep class com.write4me.llama_flutter_android.** { *; }

# Keep Kotlin Function1 interface and invoke method used by JNI callbacks in nativeLoadModel & nativeGenerateChat
-keep interface kotlin.jvm.functions.Function1 {
    public java.lang.Object invoke(java.lang.Object);
}

-keep class * implements kotlin.jvm.functions.Function1 {
    public java.lang.Object invoke(java.lang.Object);
}

-keep class kotlin.jvm.functions.** { *; }
