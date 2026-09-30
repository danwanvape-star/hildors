package com.hildors.hildors_cockpit

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var deviceWifiSocket: DeviceWifiSocket? = null
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        deviceWifiSocket?.close()
        deviceWifiSocket = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val deviceSockets = DeviceWifiSocket(applicationContext)
        deviceWifiSocket = deviceSockets
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hildors/device_wifi")
            .setMethodCallHandler { call, result ->
                val host = call.argument<String>("host")
                val port = call.argument<Int>("port")
                if (call.method == "open" && host != null && port != null) {
                    deviceSockets.open(host, port, result)
                } else result.notImplemented()
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hildors/app_info")
            .setMethodCallHandler { call, result ->
                if (call.method == "version") {
                    @Suppress("DEPRECATION")
                    val info = packageManager.getPackageInfo(packageName, 0)
                    val build = if (android.os.Build.VERSION.SDK_INT >= 28) info.longVersionCode else {
                        @Suppress("DEPRECATION")
                        info.versionCode.toLong()
                    }
                    result.success("${info.versionName} ($build)")
                } else result.notImplemented()
            }
    }
}
