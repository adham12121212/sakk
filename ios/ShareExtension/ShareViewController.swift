// "Share → Sakk": copies the shared receipt photo or PDF into the App Group
// (group.com.sakk.app) and opens Sakk, which scans it (ShareIntake in Dart).
// If this fails to build with "No such module 'receive_sharing_intent'", see
// README.md in this folder.
import receive_sharing_intent

class ShareViewController: RSIShareViewController {}