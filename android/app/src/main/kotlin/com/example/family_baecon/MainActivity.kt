package com.example.family_baecon

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "family_baecon/app_icon"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
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
}
