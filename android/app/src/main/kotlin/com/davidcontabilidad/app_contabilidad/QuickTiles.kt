package com.davidcontabilidad.app_contabilidad

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Botón del panel de ajustes rápidos (el que sale al deslizar hacia abajo).
 * Al tocarlo abre la app directo en el formulario de gasto o de ingreso.
 */
abstract class BaseQuickTile : TileService() {
    abstract val quickAction: String

    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        val intent = Intent(this, MainActivity::class.java).apply {
            action = MainActivity.ACTION_QUICK
            putExtra(MainActivity.EXTRA_QUICK, quickAction)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        if (Build.VERSION.SDK_INT >= 34) {
            val pending = PendingIntent.getActivity(
                this,
                quickAction.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            startActivityAndCollapse(pending)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}

class AddExpenseTile : BaseQuickTile() {
    override val quickAction = "expense"
}

class AddIncomeTile : BaseQuickTile() {
    override val quickAction = "income"
}
