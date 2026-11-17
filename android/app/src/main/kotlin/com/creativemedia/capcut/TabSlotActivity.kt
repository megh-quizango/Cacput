package com.creativemedia.capcut

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.browser.customtabs.CustomTabColorSchemeParams
import androidx.browser.customtabs.CustomTabsClient
import androidx.browser.customtabs.CustomTabsIntent

/**
 * One placeholder per Custom Tab in a batch. MainActivity stacks N of these in one
 * startActivities() call; Android only creates the top one. It opens its tab; when the user
 * closes that tab it finishes, the next placeholder below is created and opens its tab, and so
 * on. Every tab is started by our own activity while it is on top, so background-activity-start
 * limits (strict on Samsung / Android 14+) never drop a tab, and the user sees the app's dark
 * background between tabs instead of the app's UI.
 */
class TabSlotActivity : Activity() {
    companion object {
        private const val EXTRA_URL = "url"
        private const val EXTRA_SHOW_TITLE = "show_title"
        private const val STATE_LAUNCHED = "launched"
        private const val TOOLBAR_COLOR = 0xFF0A0A0F.toInt()
        private const val CHROME_PACKAGE = "com.android.chrome"

        fun intent(context: Context, url: String, showTitle: Boolean): Intent =
            Intent(context, TabSlotActivity::class.java)
                .putExtra(EXTRA_URL, url)
                .putExtra(EXTRA_SHOW_TITLE, showTitle)

        // Prefer Chrome: Samsung Internet (Samsung's default) handles custom tabs differently.
        fun resolvePackage(context: Context): String? =
            CustomTabsClient.getPackageName(context, listOf(CHROME_PACKAGE), true)
                ?: CustomTabsClient.getPackageName(context, null)

        fun tabIntent(context: Context, uri: Uri, showTitle: Boolean): Intent {
            val colorParams = CustomTabColorSchemeParams.Builder()
                .setToolbarColor(TOOLBAR_COLOR)
                .build()
            return CustomTabsIntent.Builder()
                .setDefaultColorSchemeParams(colorParams)
                .setShowTitle(showTitle)
                .setUrlBarHidingEnabled(true)
                .setShareState(CustomTabsIntent.SHARE_STATE_ON)
                .build()
                .intent
                .apply {
                    data = uri
                    resolvePackage(context)?.let { setPackage(it) }
                }
        }

        /** Starts the tab; retries once with the system default if the chosen browser is gone. */
        fun start(activity: Activity, intent: Intent): Boolean = try {
            activity.startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            intent.setPackage(null)
            runCatching { activity.startActivity(intent) }.isSuccess
        }
    }

    private var launched = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Survives process death: never reopen a tab the user already saw.
        launched = savedInstanceState?.getBoolean(STATE_LAUNCHED) ?: false
    }

    override fun onResume() {
        super.onResume()
        if (launched) {
            // Our tab was closed: step aside so the next placeholder (or the app) comes up.
            finish()
            overridePendingTransition(0, 0)
            return
        }
        launched = true
        val uri = runCatching { Uri.parse(intent.getStringExtra(EXTRA_URL)) }.getOrNull()
            ?.takeIf { it.scheme == "http" || it.scheme == "https" }
        val showTitle = intent.getBooleanExtra(EXTRA_SHOW_TITLE, true)
        if (uri == null || !start(this, tabIntent(this, uri, showTitle))) {
            finish()
            overridePendingTransition(0, 0)
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean(STATE_LAUNCHED, launched)
    }
}
