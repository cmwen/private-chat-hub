// TODO: Change package name to match your applicationId in build.gradle.kts
// Example: package com.yourcompany.yourapp
package com.cmwen.private_chat_hub

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register LiteRT-LM plugin for on-device inference
        flutterEngine.plugins.add(LiteRTPlugin())
    }
}
