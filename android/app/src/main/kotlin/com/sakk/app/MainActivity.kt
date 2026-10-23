package com.sakk.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

// FragmentActivity, not FlutterActivity: local_auth needs it to show the
// biometric prompt.
class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        dropUnreadableShare(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        dropUnreadableShare(intent)
        super.onNewIntent(intent)
    }

    // "Share → Sakk": receive_sharing_intent reads the shared file without
    // catching errors, so a share Sakk wasn't given access to (a sender
    // that didn't grant it) would crash the app. Such a share is dropped
    // before the plugin sees it; the app just opens.
    private fun dropUnreadableShare(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return
        val uri = streamOf(intent) ?: return
        if (uri.scheme != "content") return
        try {
            contentResolver.openInputStream(uri)?.close()
        } catch (e: Exception) {
            // SecurityException (no access), or the file is gone.
            intent.removeExtra(Intent.EXTRA_STREAM)
        }
    }

    private fun streamOf(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
}
