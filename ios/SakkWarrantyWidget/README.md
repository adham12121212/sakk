# iOS home screen widget: one-time Xcode setup

The widget code is in `SakkWarrantyWidget.swift`. It needs its own Xcode target,
which has to be added in Xcode:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target… → Widget Extension.** Product name `SakkWarrantyWidget`,
   untick "Include Live Activity" and "Include Configuration App Intent".
   When Xcode asks to activate the scheme, choose Cancel.
3. Xcode creates a `SakkWarrantyWidget` folder with sample files. Delete its
   generated `.swift` files (Move to Trash), then drag this folder's
   `SakkWarrantyWidget.swift` into the target (tick only the
   SakkWarrantyWidget target).
4. Set the widget target's **Minimum Deployments** to iOS 15.0.
5. Add the shared App Group to **both** the Runner and SakkWarrantyWidget targets:
   Signing & Capabilities → + Capability → App Groups → add
   `group.com.sakk.app` (the name must match `HomeWidgetSync.iOSAppGroup`).
6. Build and run, then long-press the home screen → + → Sakk.

The App Group needs an Apple Developer team selected under Signing, and the
widget's bundle ID must start with the app's (e.g. `<app id>.SakkWarrantyWidget`).
