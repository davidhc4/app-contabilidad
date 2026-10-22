package com.davidcontabilidad.app_contabilidad

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        const val ACTION_QUICK = "com.davidcontabilidad.app_contabilidad.QUICK_ADD"
        const val EXTRA_QUICK = "quick_action"
        const val CHANNEL = "com.davidcontabilidad.app_contabilidad/quick_action"
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
    }
}
