package com.davidcontabilidad.app_contabilidad

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.content.Context
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
        const val NOTIF_CHANNEL = "com.davidcontabilidad.app_contabilidad/notif"
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

        // Detección de pagos por notificaciones (todo en el teléfono).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIF_CHANNEL)
            .setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences(
                    PaymentNotificationListener.PREFS, Context.MODE_PRIVATE
                )
                when (call.method) {
                    "isAccessGranted" -> result.success(isNotificationAccessGranted())
                    "openAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    "setEnabled" -> {
                        val on = call.argument<Boolean>("enabled") ?: false
                        prefs.edit().putBoolean(
                            PaymentNotificationListener.KEY_ENABLED, on
                        ).apply()
                        result.success(null)
                    }
                    "drain" -> {
                        val queue = prefs.getString(
                            PaymentNotificationListener.KEY_QUEUE, "[]"
                        )
                        prefs.edit().putString(
                            PaymentNotificationListener.KEY_QUEUE, "[]"
                        ).apply()
                        result.success(queue)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isNotificationAccessGranted(): Boolean {
        return try {
            val flat = Settings.Secure.getString(
                contentResolver, "enabled_notification_listeners"
            )
            flat != null && flat.contains(packageName)
        } catch (_: Exception) {
            false
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
