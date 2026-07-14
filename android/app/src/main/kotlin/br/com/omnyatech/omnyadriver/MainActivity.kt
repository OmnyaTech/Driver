package br.com.omnyatech.omnyadriver

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "br.com.omnyatech.omnyadriver/android"
    private val notificationRequestCode = 7108
    private val alertsChannelId = "omnya_driver_alerts"
    private var pendingNotificationResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestNotificationPermission" -> {
                        requestNotificationPermission(result)
                    }
                    "areNotificationsEnabled" -> {
                        result.success(areNotificationsEnabled())
                    }
                    "showDriverAlertNotification" -> {
                        val id = call.argument<Int>("id") ?: System.currentTimeMillis().toInt()
                        val title = call.argument<String>("title") ?: "Driver"
                        val body = call.argument<String>("body") ?: ""
                        showDriverAlertNotification(id, title, body, result)
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        result.success(isIgnoringBatteryOptimizations())
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        result.success(requestIgnoreBatteryOptimizations())
                    }
                    "startActiveJourneyForeground" -> {
                        val startedAt = call.argument<Long>("startedAt") ?: System.currentTimeMillis()
                        val title = call.argument<String>("title") ?: "Jornada em andamento"
                        val body = call.argument<String>("body")
                            ?: "Toque para voltar ao Driver e finalizar quando terminar."
                        try {
                            ActiveJourneyForegroundService.start(this, startedAt, title, body)
                            result.success(true)
                        } catch (error: Exception) {
                            result.error(
                                "active_journey_foreground_failed",
                                error.message ?: "Nao foi possivel iniciar a notificacao fixa.",
                                null
                            )
                        }
                    }
                    "stopActiveJourneyForeground" -> {
                        ActiveJourneyForegroundService.stop(this)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == notificationRequestCode) {
            pendingNotificationResult?.success(true)
            pendingNotificationResult = null
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }

        if (pendingNotificationResult != null) {
            result.success(false)
            return
        }

        pendingNotificationResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            notificationRequestCode
        )
    }

    private fun areNotificationsEnabled(): Boolean {
        if (!NotificationManagerCompat.from(this).areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun showDriverAlertNotification(
        id: Int,
        title: String,
        body: String,
        result: MethodChannel.Result
    ) {
        if (!areNotificationsEnabled()) {
            result.success(false)
            return
        }

        try {
            ensureAlertsChannel()
            val openIntent = packageManager.getLaunchIntentForPackage(packageName)
                ?: Intent(this, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                this,
                id,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notification = NotificationCompat.Builder(this, alertsChannelId)
                .setSmallIcon(R.drawable.ic_stat_driver)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .setOnlyAlertOnce(false)
                .setShowWhen(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .build()

            NotificationManagerCompat.from(this).notify(id, notification)
            result.success(true)
        } catch (error: SecurityException) {
            result.error(
                "notification_permission_missing",
                error.message ?: "Permissao de notificacao ausente.",
                null
            )
        } catch (error: Exception) {
            result.error(
                "notification_failed",
                error.message ?: "Nao foi possivel mostrar a notificacao.",
                null
            )
        }
    }

    private fun ensureAlertsChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(alertsChannelId) != null) return
        val channel = NotificationChannel(
            alertsChannelId,
            "Avisos do Driver",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Avisos importantes sobre jornadas, metas e reservas."
            setShowBadge(true)
            enableVibration(true)
        }
        manager.createNotificationChannel(channel)
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    private fun requestIgnoreBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        if (isIgnoringBatteryOptimizations()) return true

        return try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                true
            } catch (_: Exception) {
                false
            }
        }
    }
}
