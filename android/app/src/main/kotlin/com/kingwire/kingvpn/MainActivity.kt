package com.kingwire.kingvpn

import android.content.Intent
import androidx.annotation.NonNull
import id.laskarmedia.openvpn_flutter.OpenVPNFlutterPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.ArrayList
import java.util.Collections

class MainActivity : FlutterActivity() {

    private var disallowedAppsChannel: MethodChannel? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        OpenVPNFlutterPlugin.connectWhileGranted(requestCode == 24 && resultCode == RESULT_OK)
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun finish() {
        disallowedAppsChannel?.setMethodCallHandler(null)
        super.finish()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        disallowedAppsChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL_DISALLOWED_APPS
        )
        disallowedAppsChannel?.setMethodCallHandler { call, result ->
            if ("applyChanges" == call.method) {
                val str: String? = call.argument("packageName")
                val packageName = str ?: ""

                val list: ArrayList<String> = ArrayList(Collections.singletonList(packageName))
                try {
                    addInDisallowedList(list)
                    result.success("$packageName : $list")
                } catch (e: Exception) {
                    e.printStackTrace()
                    result.success("$packageName : dffd ${e.message}")
                }
            }
        }
    }

    private fun addInDisallowedList(list: ArrayList<String>) {
        // bypassPackages = list;
//        Set<String> set = new HashSet(list);
//        vpnProfile.mAllowedAppsVpn.addAll(set);
    }

    companion object {
        private const val METHOD_CHANNEL_DISALLOWED_APPS: String = "disallowList"
    }
}