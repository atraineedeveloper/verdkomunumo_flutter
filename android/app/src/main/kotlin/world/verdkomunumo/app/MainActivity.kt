package world.verdkomunumo.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "verdkomunumo/notifications"
    private val requestCodeNotifications = 1001
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPermissionStatus" -> result.success(getPermissionStatus())
                "requestPermission" -> requestNotificationPermission(result)
                "openSystemSettings" -> {
                    openNotificationSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getPermissionStatus(): String {
        val notificationsEnabled = NotificationManagerCompat.from(this).areNotificationsEnabled()

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return if (notificationsEnabled) "granted" else "denied"
        }

        val permissionGranted =
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED

        if (permissionGranted && notificationsEnabled) {
            return "granted"
        }

        return if (ActivityCompat.shouldShowRequestPermissionRationale(
                this,
                Manifest.permission.POST_NOTIFICATIONS,
            )
        ) {
            "denied"
        } else {
            "notDetermined"
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(getPermissionStatus())
            return
        }

        val alreadyGranted =
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED

        if (alreadyGranted) {
            result.success(getPermissionStatus())
            return
        }

        if (pendingPermissionResult != null) {
            result.error(
                "request_in_progress",
                "Another notification permission request is already in progress.",
                null,
            )
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            requestCodeNotifications,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (requestCode == requestCodeNotifications) {
            pendingPermissionResult?.success(getPermissionStatus())
            pendingPermissionResult = null
            return
        }

        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    private fun openNotificationSettings() {
        val intent =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                }
            } else {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                }
            }

        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }
}
