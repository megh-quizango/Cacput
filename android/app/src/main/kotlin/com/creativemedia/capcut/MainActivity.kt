package com.creativemedia.capcut

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.net.Uri
import android.os.Bundle
import androidx.browser.customtabs.CustomTabColorSchemeParams
import androidx.browser.customtabs.CustomTabsClient
import androidx.browser.customtabs.CustomTabsIntent
import androidx.browser.customtabs.CustomTabsService
import androidx.browser.customtabs.CustomTabsServiceConnection
import androidx.browser.customtabs.CustomTabsSession
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CUSTOM_TABS_CHANNEL = "com.creativemedia.capcut/custom_tabs"
        private const val TOOLBAR_COLOR = 0xFF0A0A0F.toInt()
    }

    private var customTabsClient: CustomTabsClient? = null
    private var customTabsSession: CustomTabsSession? = null
    private var customTabsPackage: String? = null
    private var isServiceBound = false
    private var pendingWarmupUrls: List<String> = emptyList()

    private val customTabsConnection = object : CustomTabsServiceConnection() {
        override fun onCustomTabsServiceConnected(name: ComponentName, client: CustomTabsClient) {
            customTabsClient = client
            client.warmup(0L)
            customTabsSession = client.newSession(null)
            prefetchPendingUrls()
        }

        override fun onServiceDisconnected(name: ComponentName) {
            customTabsClient = null
            customTabsSession = null
            isServiceBound = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CUSTOM_TABS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "warmup" -> {
                        val urls = call.arguments as? List<*>
                        pendingWarmupUrls = urls?.filterIsInstance<String>() ?: emptyList()
                        ensureCustomTabsWarmedUp()
                        result.success(null)
                    }
                    "launch" -> {
                        val url = call.argument<String>("url")
                        val showTitle = call.argument<Boolean>("showTitle") ?: true
                        if (url.isNullOrBlank()) {
                            result.success(false)
                        } else {
                            result.success(launchWithWarmSession(url, showTitle))
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onStart() {
        super.onStart()
        ensureCustomTabsWarmedUp()
    }

    override fun onDestroy() {
        if (isServiceBound) {
            try {
                unbindService(customTabsConnection)
            } catch (_: IllegalArgumentException) {
            }
            isServiceBound = false
        }
        customTabsClient = null
        customTabsSession = null
        super.onDestroy()
    }

    private fun ensureCustomTabsWarmedUp() {
        val client = customTabsClient
        if (client != null) {
            client.warmup(0L)
            if (customTabsSession == null) {
                customTabsSession = client.newSession(null)
            }
            prefetchPendingUrls()
            return
        }
        if (isServiceBound) return

        val packageName = CustomTabsClient.getPackageName(this, null) ?: return
        customTabsPackage = packageName
        isServiceBound = CustomTabsClient.bindCustomTabsService(
            this,
            packageName,
            customTabsConnection,
        )
    }

    private fun prefetchPendingUrls() {
        val session = customTabsSession ?: return
        val uris = pendingWarmupUrls
            .asSequence()
            .mapNotNull { runCatching { Uri.parse(it) }.getOrNull() }
            .filter { it.scheme == "http" || it.scheme == "https" }
            .distinct()
            .toList()
        if (uris.isEmpty()) return

        val otherBundles = if (uris.size > 1) {
            uris.drop(1).map { uri ->
                Bundle().apply {
                    putParcelable(CustomTabsService.KEY_URL, uri)
                }
            }
        } else {
            null
        }
        session.mayLaunchUrl(uris.first(), null, otherBundles)
    }

    private fun launchWithWarmSession(url: String, showTitle: Boolean): Boolean {
        val uri = runCatching { Uri.parse(url) }.getOrNull() ?: return false
        if (uri.scheme != "http" && uri.scheme != "https") return false

        val colorParams = CustomTabColorSchemeParams.Builder()
            .setToolbarColor(TOOLBAR_COLOR)
            .build()

        val customTabsIntent = CustomTabsIntent.Builder(customTabsSession)
            .setDefaultColorSchemeParams(colorParams)
            .setShowTitle(showTitle)
            .setUrlBarHidingEnabled(true)
            .setShareState(CustomTabsIntent.SHARE_STATE_ON)
            .build()

        customTabsPackage?.let { pkg ->
            customTabsIntent.intent.setPackage(pkg)
        }

        return try {
            customTabsIntent.launchUrl(this, uri)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }
}
