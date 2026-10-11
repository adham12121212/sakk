package com.sakk.app

import io.flutter.embedding.android.FlutterFragmentActivity

// FragmentActivity, not FlutterActivity: local_auth needs it to show the
// biometric prompt.
class MainActivity : FlutterFragmentActivity()
