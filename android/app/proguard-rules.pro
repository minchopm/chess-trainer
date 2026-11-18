# The search thread calls back into this interface by name (engine_jni.cpp).
-keep class com.artesoft.brasspawn.engine.StockfishNative { *; }
-keep interface com.artesoft.brasspawn.engine.StockfishNative$Listener { *; }
-keepclassmembers class * implements com.artesoft.brasspawn.engine.StockfishNative$Listener { *; }
