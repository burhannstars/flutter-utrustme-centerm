package com.gudangvoucher.utrustme;

import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry

class Application : FlutterApplication(), PluginRegistry.PluginRegistrantCallback {
    override fun onCreate() {
        super.onCreate()
    }

    override fun registerWith(registry: PluginRegistry) {
    }
}