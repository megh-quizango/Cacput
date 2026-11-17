package com.creativemedia.capcut

import android.content.ComponentName
import android.net.Uri
import android.os.Bundle
import androidx.browser.customtabs.CustomTabsClient
import androidx.browser.customtabs.CustomTabsService
import androidx.browser.customtabs.CustomTabsServiceConnection
import androidx.browser.customtabs.CustomTabsSession
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CUSTOM_TABS_CHANNEL = "com.creativemedia.capcut/custom_tabs"
    }

    private var customTabsClient: CustomTabsClient? = null
    private var customTabsSession: CustomTabsSession? = null
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
                    "launchBatch" -> {
                        val urls = call.argument<List<String>>("urls").orEmpty()
                        val showTitle = call.argument<Boolean>("showTitle") ?: true
                        result.success(launchBatch(urls, showTitle))
                    }
                    "launch" -> {
                        val url = call.argument<String>("url").orEmpty()
                        val showTitle = call.argument<Boolean>("showTitle") ?: true
                        result.success(launchTab(url, showTitle))
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

        val packageName = resolveCustomTabsPackage() ?: return
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

    private fun resolveCustomTabsPackage(): String? = TabSlotActivity.resolvePackage(this)

    /// Stacks one TabSlotActivity per URL in a single call while we are in the foreground.
    /// The top slot opens its tab; each following tab opens when the user closes the previous one,
    /// and the app comes back only after the last tab is closed.
    private fun launchBatch(urls: List<String>, showTitle: Boolean): Boolean {
        val slots = urls
            .filter { url -> runCatching { Uri.parse(url).scheme }.getOrNull() in setOf("http", "https") }
            .map { TabSlotActivity.intent(this, it, showTitle) }
        if (slots.isEmpty()) return false
        startActivities(slots.toTypedArray())
        overridePendingTransition(0, 0)
        return true
    }

    /// Opens one Custom Tab directly (legal pages).
    private fun launchTab(url: String, showTitle: Boolean): Boolean {
        val uri = runCatching { Uri.parse(url) }.getOrNull()
            ?.takeIf { it.scheme == "http" || it.scheme == "https" } ?: return false
        return TabSlotActivity.start(this, TabSlotActivity.tabIntent(this, uri, showTitle))
    }
}
