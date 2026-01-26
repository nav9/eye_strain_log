package com.example.eye_strain_log

import io.flutter.embedding.android.FlutterActivity

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.eye_strain_log/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "lockScreen") {
                lockScreen(result)
            } else if (call.method == "enableAdmin") {
                enableAdmin(result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun lockScreen(result: MethodChannel.Result) {
        val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val componentName = ComponentName(this, DeviceAdmin::class.java)

        if (devicePolicyManager.isAdminActive(componentName)) {
            devicePolicyManager.lockNow()
            result.success(true)
        } else {
            result.error("NO_ADMIN", "Device Admin not enabled", null)
        }
    }

    private fun enableAdmin(result: MethodChannel.Result) {
        val componentName = ComponentName(this, DeviceAdmin::class.java)
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
        intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Needed to lock screen for eye rest.")
        startActivityForResult(intent, 1)
        result.success(true)
    }
}
