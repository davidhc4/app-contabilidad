package com.davidcontabilidad.app_contabilidad

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

/**
 * Lee las notificaciones del teléfono para detectar pagos. Todo ocurre en el
 * dispositivo: solo guarda, en una cola local, las notificaciones que parecen
 * tener un monto de dinero, y únicamente cuando la persona activó la función.
 * Nada se envía a internet.
 */
class PaymentNotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            if (!prefs.getBoolean(KEY_ENABLED, false)) return

            val pkg = sbn.packageName ?: return
            if (pkg == packageName) return

            val extras = sbn.notification?.extras ?: return
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
            val text = (extras.getCharSequence(Notification.EXTRA_TEXT)
                ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT))?.toString() ?: ""
            val blob = "$title $text"
            if (!MONEY.containsMatchIn(blob)) return

            val arr = JSONArray(prefs.getString(KEY_QUEUE, "[]"))
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                if (o.optString("pkg") == pkg && o.optString("text") == text) return
            }
            val entry = JSONObject().apply {
                put("pkg", pkg)
                put("title", title)
                put("text", text)
                put("time", System.currentTimeMillis())
            }
            arr.put(entry)

            val capped = JSONArray()
            val start = maxOf(0, arr.length() - MAX_QUEUE)
            for (i in start until arr.length()) capped.put(arr.get(i))
            prefs.edit().putString(KEY_QUEUE, capped.toString()).apply()
        } catch (_: Exception) {
            // Si algo falla con una notificación, se ignora sin romper nada.
        }
    }

    companion object {
        const val PREFS = "bolsillo_notif"
        const val KEY_ENABLED = "enabled"
        const val KEY_QUEUE = "queue"
        const val MAX_QUEUE = 30
        // Busca algo que parezca dinero con separador de miles: "50.000".
        val MONEY = Regex("\\d[.,]\\d{3}")
    }
}
