# iOS "Share → Sakk": one-time setup (needs a paid Apple Developer account)

On Android, sharing a receipt photo or PDF to Sakk already works (the intent
filters are in `AndroidManifest.xml`). On iOS it needs a Share Extension,
which needs an **App Group**, and Apple's free personal teams can't use App
Groups. Do this once the account is in the Apple Developer Program. Until
then this folder isn't part of the Xcode project, so iPhone builds still sign
with the free team.

The Dart side (`ShareIntake`, `SharedReceiptListener`, `ScanView(shared:)`) is
the same on both platforms.

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target… → Share Extension.** Product name `ShareExtension`,
   bundle ID `com.sakk.app.ShareExtension`. When Xcode asks to activate the
   scheme, choose Cancel.
3. Delete the files Xcode generated in the new `ShareExtension` group
   (`ShareViewController.swift`, `MainInterface.storyboard`, `Info.plist`;
   Move to Trash), then drag this folder's `ShareViewController.swift`,
   `Info.plist` and `ShareExtension.entitlements` into the group (tick only
   the ShareExtension target for the Swift file).
4. ShareExtension target → Build Settings:
   - **Info.plist File**: `ShareExtension/Info.plist`
   - **Code Signing Entitlements**: `ShareExtension/ShareExtension.entitlements`
   - **iOS Deployment Target**: 15.0 (same as Runner)
   - Add a User-Defined setting `CUSTOM_GROUP_ID` = `group.com.sakk.app`
   - `FLUTTER_BUILD_NAME` and `FLUTTER_BUILD_NUMBER` come from
     `Flutter/Generated.xcconfig`: base the target's configurations on an
     xcconfig that includes it and the target's Pods xcconfig (copy
     `Flutter/Debug.xcconfig` / `Release.xcconfig` and point the Pods include
     at `Pods-Runner-ShareExtension`), so the extension's version matches the
     app's.
5. Runner target → Build Settings: add `CUSTOM_GROUP_ID` = `group.com.sakk.app`.
6. **Signing & Capabilities** → + Capability → **App Groups** → add
   `group.com.sakk.app` to **both** Runner and ShareExtension (the home
   screen widget uses the same group; see `../SakkWarrantyWidget/README.md`).
7. Runner `Info.plist`: add
   ```xml
   <key>AppGroupId</key>
   <string>$(CUSTOM_GROUP_ID)</string>
   ```
   and a second entry in `CFBundleURLTypes` → `CFBundleURLSchemes`:
   `ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)` (the extension opens Sakk with it).
8. `ios/Podfile`, inside `target 'Runner' do`:
   ```ruby
   target 'ShareExtension' do
     inherit! :search_paths
   end
   ```
   then `cd ios && pod install`.
9. Runner → Build Phases: drag **Embed Foundation Extensions** above
   **Thin Binary** (otherwise: "No such module 'receive_sharing_intent'").
10. `SceneDelegate.swift`: the app uses scenes, so iOS hands the
    `ShareMedia-…` link to the scene, but `receive_sharing_intent` 1.8.1 only
    listens on the app delegate. Pass it on from
    `scene(_:openURLContexts:)` (app already running) and from the
    `urlContexts` of `scene(_:willConnectTo:options:)` (share launched the
    app) to `SwiftReceiveSharingIntentPlugin.instance.application(_:open:options:)`
    and `…application(_:didFinishLaunchingWithOptions:)` with the URL under
    `.url`, keeping `FlutterSceneDelegate`'s own handling.

Before shipping, test on a device: a photo from Photos, a PDF from Files, and
a PDF attachment from Mail and from WhatsApp. `RSIShareViewController` only
reads PDFs that come as a file URL; if Mail or WhatsApp send the PDF as data,
the controller needs to write the data to the App Group itself.