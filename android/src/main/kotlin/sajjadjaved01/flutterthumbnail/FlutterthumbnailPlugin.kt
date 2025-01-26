package sajjadjaved01.flutterthumbnail

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class FlutterthumbnailPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutterthumbnail")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "file" -> {
                val args = call.arguments as Map<*, *>
                val video = args["video"] as String
                val format = args["format"] as Int
                val maxh = args["maxh"] as Int
                val maxw = args["maxw"] as Int
                val timeMs = args["timeMs"] as Int
                val quality = args["quality"] as Int
                val headers = args["headers"] as? Map<String, String>
                val path = args["path"] as? String

                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val filePath = buildThumbnailFile(video, headers, path, format, maxh, maxw, timeMs, quality)
                        withContext(Dispatchers.Main) {
                            result.success(filePath)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("exception", e.message, null)
                        }
                    }
                }
            }
            "data" -> {
                val args = call.arguments as Map<*, *>
                val video = args["video"] as String
                val format = args["format"] as Int
                val maxh = args["maxh"] as Int
                val maxw = args["maxw"] as Int
                val timeMs = args["timeMs"] as Int
                val quality = args["quality"] as Int
                val headers = args["headers"] as? Map<String, String>

                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val thumbnailData = buildThumbnailData(video, headers, format, maxh, maxw, timeMs, quality)
                        withContext(Dispatchers.Main) {
                            result.success(thumbnailData)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("exception", e.message, null)
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun buildThumbnailData(
        videoPath: String,
        headers: Map<String, String>?,
        format: Int,
        maxh: Int,
        maxw: Int,
        timeMs: Int,
        quality: Int
    ): ByteArray {
        val bitmap = createVideoThumbnail(videoPath, headers, maxh, maxw, timeMs)
            ?: throw NullPointerException("Failed to create video thumbnail.")

        val stream = ByteArrayOutputStream()
        bitmap.compress(getCompressFormat(format), quality, stream)
        bitmap.recycle()
        return stream.toByteArray()
    }

    private fun buildThumbnailFile(
        videoPath: String,
        headers: Map<String, String>?,
        path: String?,
        format: Int,
        maxh: Int,
        maxw: Int,
        timeMs: Int,
        quality: Int
    ): String {
        val thumbnailData = buildThumbnailData(videoPath, headers, format, maxh, maxw, timeMs, quality)
        val extension = getFormatExtension(format)
        val outputPath = getOutputPath(videoPath, path, extension)

        FileOutputStream(outputPath).use { outputStream ->
            outputStream.write(thumbnailData)
            Log.d("FlutterthumbnailPlugin", "Thumbnail saved to: $outputPath")
        }

        return outputPath
    }

    private fun getOutputPath(videoPath: String, path: String?, extension: String): String {
        if (path != null && path.endsWith(extension)) {
            return path
        }

        val fileName = File(videoPath).name.replaceAfterLast(".", extension)
        return if (path != null) {
            File(path, fileName).absolutePath
        } else {
            File(context.cacheDir, fileName).absolutePath
        }
    }

    private fun getCompressFormat(format: Int): Bitmap.CompressFormat {
        return when (format) {
            1 -> Bitmap.CompressFormat.PNG
            2 -> Bitmap.CompressFormat.WEBP
            else -> Bitmap.CompressFormat.JPEG
        }
    }

    private fun getFormatExtension(format: Int): String {
        return when (format) {
            1 -> "png"
            2 -> "webp"
            else -> "jpg"
        }
    }

    private fun createVideoThumbnail(
        video: String,
        headers: Map<String, String>?,
        targetH: Int,
        targetW: Int,
        timeMs: Int
    ): Bitmap? {
        val retriever = MediaMetadataRetriever()
        return try {
            when {
                video.startsWith("/") || video.startsWith("file://") -> {
                    val filePath = if (video.startsWith("file://")) video.substring(7) else video
                    val file = File(filePath)
                    if (!file.exists()) {
                        throw IOException("Video file does not exist: $filePath")
                    }
                    retriever.setDataSource(filePath)
                }
                video.startsWith("http://") || video.startsWith("https://") -> {
                    retriever.setDataSource(video, headers ?: HashMap())
                }
                else -> throw IllegalArgumentException("Unsupported video path: $video")
            }

            if (targetH != 0 && targetW != 0 && android.os.Build.VERSION.SDK_INT >= 27) {
                retriever.getScaledFrameAtTime(timeMs * 1000L, MediaMetadataRetriever.OPTION_CLOSEST, targetW, targetH)
            } else {
                val bitmap = retriever.getFrameAtTime(timeMs * 1000L, MediaMetadataRetriever.OPTION_CLOSEST)
                if (bitmap != null && (targetH != 0 || targetW != 0)) {
                    val width = bitmap.width
                    val height = bitmap.height
                    val scaledWidth = if (targetW == 0) ((targetH.toFloat() / height) * width).toInt() else targetW
                    val scaledHeight = if (targetH == 0) ((targetW.toFloat() / width) * height).toInt() else targetH
                    Bitmap.createScaledBitmap(bitmap, scaledWidth, scaledHeight, true)
                } else {
                    bitmap
                }
            }
        } catch (e: Exception) {
            Log.e("FlutterthumbnailPlugin", "Failed to create video thumbnail: ", e)
            null
        } finally {
            try {
                retriever.release()
            } catch (e: IOException) {
                Log.e("FlutterthumbnailPlugin", "Failed to release MediaMetadataRetriever: ", e)
            }
        }
    }
}