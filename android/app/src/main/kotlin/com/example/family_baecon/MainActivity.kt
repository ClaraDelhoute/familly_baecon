package com.example.family_baecon

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val appIconChannelName = "family_baecon/app_icon"
    private val notificationChannelName = "family_baecon/anomaly_notifications"
    private val anomalyNotificationChannelId = "family_baecon_anomaly_alerts"
    private val notificationPermissionRequestCode = 4201

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appIconChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "setStatus") {
                    val status = call.argument<String>("status") ?: "ok"
                    try {
                        setLauncherStatus(status)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ICON_SWITCH_ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        createAnomalyNotificationChannel()
                        requestNotificationPermissionIfNeeded()
                        result.success(null)
                    }
                    "showAnomalyAlert" -> {
                        createAnomalyNotificationChannel()
                        val title = call.argument<String>("title") ?: "Alerte anomalie"
                        val message = call.argument<String>("message") ?: ""
                        val severity = call.argument<String>("severity") ?: "medium"
                        val id = call.argument<String>("id") ?: "$title$message"
                        showAnomalyNotification(id, title, message, severity)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setLauncherStatus(status: String) {
        val pm = packageManager
        val clsOk = ComponentName(this, "$packageName.LauncherOk")
        val clsWarning = ComponentName(this, "$packageName.LauncherWarning")
        val clsCritical = ComponentName(this, "$packageName.LauncherCritical")

        val desired = when (status.lowercase()) {
            "critical" -> clsCritical
            "warning" -> clsWarning
            else -> clsOk
        }

        fun setState(component: ComponentName, enabled: Boolean) {
            pm.setComponentEnabledSetting(
                component,
                if (enabled) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )
        }

        // Never disable the launcher alias currently hosting this Activity.
        // Disabling it can send the app to the Android home screen on some devices.
        val running = componentName
        fun shouldEnable(component: ComponentName): Boolean {
            val isDesired = component.className == desired.className
            val isRunning = component.className == running.className
            return isDesired || isRunning
        }

        setState(clsOk, shouldEnable(clsOk))
        setState(clsWarning, shouldEnable(clsWarning))
        setState(clsCritical, shouldEnable(clsCritical))
    }

    private fun createAnomalyNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val importance = NotificationManager.IMPORTANCE_HIGH
        val channel = NotificationChannel(
            anomalyNotificationChannelId,
            "Alertes d'anomalies",
            importance
        ).apply {
            description = "Notifications envoyees quand Family Beacon recoit une anomalie."
            enableVibration(true)
        }
        manager.createNotificationChannel(channel)
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) return
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            notificationPermissionRequestCode
        )
    }

    private fun showAnomalyNotification(
        id: String,
        title: String,
        message: String,
        severity: String
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) return

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntentFlags =
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                }
        val pendingIntent = PendingIntent.getActivity(this, 0, launchIntent, pendingIntentFlags)
        val priority = if (severity.lowercase() == "high") {
            Notification.PRIORITY_HIGH
        } else {
            Notification.PRIORITY_DEFAULT
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, anomalyNotificationChannelId)
        } else {
            Notification.Builder(this)
        }
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(Notification.BigTextStyle().bigText(message))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(priority)
            .setDefaults(Notification.DEFAULT_ALL)

        manager.notify(id.hashCode(), builder.build())
    }
}
