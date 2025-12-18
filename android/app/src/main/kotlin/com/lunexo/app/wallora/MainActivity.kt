package com.lunexo.app.wallora

import android.app.WallpaperManager
import android.content.ContentResolver
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import java.io.InputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.lunexo.app.wallpaper"
    private val SYSTEM_CHANNEL = "com.lunexo.app.system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Wallpaper channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setWallpaper") {
                val path = call.argument<String>("path")
                val imageBytesList = call.argument<List<Int>>("imageBytes")
                val screen = call.argument<Int>("screen") ?: 3
                
                // Öncelik path'e verilir (geçici dosya yolu)
                if (path != null) {
                    try {
                        setWallpaperFromPath(path, screen)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else if (imageBytesList != null) {
                    // Fallback: Byte array kullan (geriye dönük uyumluluk için)
                    val imageBytes = ByteArray(imageBytesList.size) { i ->
                        val value = imageBytesList[i]
                        if (value > 127) (value - 256).toByte() else value.toByte()
                    }
                    try {
                        setWallpaperFromBytes(imageBytes, screen)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else {
                    result.error("ERROR", "Path and imageBytes are both null", null)
                }
            } else {
                result.notImplemented()
            }
        }
        
        // System info channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAndroidSdkVersion") {
                result.success(android.os.Build.VERSION.SDK_INT)
            } else if (call.method == "getWallpaperDimensions") {
                val wallpaperManager = WallpaperManager.getInstance(applicationContext)
                val dimensions = mapOf(
                    "width" to wallpaperManager.desiredMinimumWidth,
                    "height" to wallpaperManager.desiredMinimumHeight
                )
                result.success(dimensions)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun setWallpaperFromBytes(imageBytes: ByteArray, screen: Int) {
        val wallpaperManager = WallpaperManager.getInstance(applicationContext)
        
        // Byte array'den bitmap oluştur
        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
        
        // Bitmap null kontrolü
        if (bitmap == null) {
            throw Exception("Failed to decode image from bytes")
        }
        
        applyWallpaper(wallpaperManager, bitmap, screen)
    }
    
    private fun setWallpaperFromPath(path: String, screen: Int) {
        val wallpaperManager = WallpaperManager.getInstance(applicationContext)
        val bitmap: android.graphics.Bitmap?
        
        // Content URI kontrolü (Android 10+ için)
        if (path.startsWith("content://")) {
            val uri = Uri.parse(path)
            val contentResolver: ContentResolver = applicationContext.contentResolver
            var inputStream: InputStream? = null
            
            try {
                inputStream = contentResolver.openInputStream(uri)
                if (inputStream == null) {
                    throw Exception("Unable to open input stream for content URI: $path")
                }
                bitmap = BitmapFactory.decodeStream(inputStream)
            } catch (e: Exception) {
                throw Exception("Failed to decode content URI: ${e.message}")
            } finally {
                inputStream?.close()
            }
        } else {
            // Normal dosya yolu
            val file = File(path)
            if (!file.exists()) {
                throw Exception("Image file not found: $path")
            }
            bitmap = BitmapFactory.decodeFile(path)
        }
        
        // Bitmap null kontrolü
        if (bitmap == null) {
            throw Exception("Failed to decode image file")
        }
        
        applyWallpaper(wallpaperManager, bitmap, screen)
    }
    
    private fun applyWallpaper(wallpaperManager: WallpaperManager, bitmap: android.graphics.Bitmap, screen: Int) {
        when (screen) {
            1 -> { // LOCK_SCREEN
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
                } else {
                    wallpaperManager.setBitmap(bitmap)
                }
            }
            2 -> { // HOME_SCREEN
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                } else {
                    wallpaperManager.setBitmap(bitmap)
                }
            }
            3 -> { // BOTH_SCREENS
                wallpaperManager.setBitmap(bitmap)
            }
            else -> {
                throw Exception("Invalid screen option: $screen")
            }
        }
    }
}
