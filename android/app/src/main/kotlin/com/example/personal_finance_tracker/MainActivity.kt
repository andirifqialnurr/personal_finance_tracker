package com.example.personal_finance_tracker

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val SAVE_FILE_REQUEST = 4821
    }

    private var pendingSavePath: String? = null
    private var pendingSaveResult: MethodChannel.Result? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != SAVE_FILE_REQUEST) return

        val result = pendingSaveResult
        val sourcePath = pendingSavePath
        pendingSaveResult = null
        pendingSavePath = null

        if (result == null || sourcePath == null) return
        val destination = data?.data
        if (resultCode != Activity.RESULT_OK || destination == null) {
            result.success(null)
            return
        }

        try {
            File(sourcePath).inputStream().use { input ->
                contentResolver.openOutputStream(destination, "w").use { output ->
                    requireNotNull(output) { "Unable to open the selected location" }
                    input.copyTo(output)
                    output.flush()
                }
            }
            result.success(destination.toString())
        } catch (error: Exception) {
            result.error("save_failed", error.message, null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.aran.personalfinance/exported_files",
        ).setMethodCallHandler { call, result ->
            val path = call.argument<String>("path")
            if (path.isNullOrBlank() || !File(path).isFile) {
                result.error("file_missing", "Exported file does not exist", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "openFile" -> openFile(path, result)
                "saveFile" -> saveFile(path, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun openFile(path: String, result: MethodChannel.Result) {
        val file = File(path)
        val uri = FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.file_provider",
            file,
        )
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType(file))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        try {
            startActivity(intent)
            result.success(null)
        } catch (error: ActivityNotFoundException) {
            result.error(
                "no_viewer",
                "No installed app can open ${file.name}",
                null,
            )
        }
    }

    private fun saveFile(path: String, result: MethodChannel.Result) {
        if (pendingSaveResult != null) {
            result.error("save_in_progress", "Another file is being saved", null)
            return
        }
        val file = File(path)
        pendingSavePath = path
        pendingSaveResult = result
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType(file)
            putExtra(Intent.EXTRA_TITLE, file.name)
        }
        try {
            startActivityForResult(intent, SAVE_FILE_REQUEST)
        } catch (error: ActivityNotFoundException) {
            pendingSavePath = null
            pendingSaveResult = null
            result.error("no_file_manager", "No file manager is available", null)
        }
    }

    private fun mimeType(file: File): String {
        return when (file.extension.lowercase()) {
            "csv" -> "text/csv"
            "json" -> "application/json"
            "pdf" -> "application/pdf"
            else -> MimeTypeMap.getSingleton()
                .getMimeTypeFromExtension(file.extension.lowercase())
                ?: "application/octet-stream"
        }
    }
}
