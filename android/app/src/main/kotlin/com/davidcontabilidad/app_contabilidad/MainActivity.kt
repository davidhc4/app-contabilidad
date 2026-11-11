package com.davidcontabilidad.app_contabilidad

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        const val ACTION_QUICK = "com.davidcontabilidad.app_contabilidad.QUICK_ADD"
        const val EXTRA_QUICK = "quick_action"
        const val CHANNEL = "com.davidcontabilidad.app_contabilidad/quick_action"
        const val UPDATES_CHANNEL = "com.davidcontabilidad.app_contabilidad/updates"
        const val APK_MIME = "application/vnd.android.package-archive"
    }

    // Acción pedida desde el panel de ajustes rápidos ("expense" o "income").
    private var pendingAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        captureQuickAction(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureQuickAction(intent)
    }

    private fun captureQuickAction(intent: Intent?) {
        if (intent?.action == ACTION_QUICK) {
            pendingAction = intent.getStringExtra(EXTRA_QUICK)
            // Evita repetir la acción si la actividad se recrea.
            intent.action = Intent.ACTION_MAIN
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "consume") {
                    result.success(pendingAction)
                    pendingAction = null
                } else {
                    result.notImplemented()
                }
            }

        // Actualizaciones: la app descarga el APK y aquí se le entrega al
        // instalador de Android.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATES_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "canInstall" -> result.success(canInstallPackages())
                        "openInstallSettings" -> {
                            openInstallSettings()
                            result.success(null)
                        }
                        "install" -> {
                            val path = call.argument<String>("path")
                            if (path == null || !File(path).exists()) {
                                result.error("missing", "No se encontró el archivo descargado", null)
                            } else {
                                installApk(File(path))
                                result.success(null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("failed", e.message, null)
                }
            }
    }

    private fun canInstallPackages(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            packageManager.canRequestPackageInstalls()

    private fun openInstallSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName")
                )
            )
        }
    }

    private fun installApk(file: File) {
        val uri = FileProvider.getUriForFile(this, "$packageName.updates", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, APK_MIME)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }
}
