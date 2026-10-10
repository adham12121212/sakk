import SwiftUI
import WidgetKit

// Home screen widget showing the next warranty to end. The Flutter side
// (lib/core/service/home_widget_sync.dart) saves already-translated texts to
// the shared App Group, so this only draws them. Tapping opens the app.

private let appGroup = "group.com.sakk.app"

struct WarrantyEntry: TimelineEntry {
    let date: Date
    let header: String
    let title: String
    let subtitle: String
}

struct WarrantyProvider: TimelineProvider {
    func placeholder(in context: Context) -> WarrantyEntry {
        WarrantyEntry(date: Date(), header: "Next warranty to end", title: "Samsung TV", subtitle: "Ends Dec 1, 2026")
    }

    func getSnapshot(in context: Context, completion: @escaping (WarrantyEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : currentEntry())
    }

    // The app calls updateWidget whenever products change, so one entry
    // with no scheduled refresh is enough.
    func getTimeline(in context: Context, completion: @escaping (Timeline<WarrantyEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> WarrantyEntry {
        let data = UserDefaults(suiteName: appGroup)
        return WarrantyEntry(
            date: Date(),
            header: data?.string(forKey: "header") ?? "Sakk",
            title: data?.string(forKey: "title") ?? "Open Sakk to see your warranties",
            subtitle: data?.string(forKey: "subtitle") ?? ""
        )
    }
}

struct SakkWarrantyWidgetView: View {
    let entry: WarrantyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.header).font(.caption).opacity(0.85).lineLimit(1)
            Text(entry.title).font(.headline).lineLimit(2)
            if !entry.subtitle.isEmpty {
                Text(entry.subtitle).font(.footnote).lineLimit(1)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        // Arabic texts lay out right-to-left even on an English iPhone.
        .environment(\.layoutDirection, entry.title.containsArabic ? .rightToLeft : .leftToRight)
        .widgetBackground(
            LinearGradient(
                colors: [Color(red: 0.24, green: 0.48, blue: 1.0), Color(red: 0.36, green: 0.24, blue: 0.96)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

@main
struct SakkWarrantyWidget: Widget {
    // Must match HomeWidgetSync.iOSName in Dart.
    let kind = "SakkWarrantyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WarrantyProvider()) { entry in
            SakkWarrantyWidgetView(entry: entry)
        }
        .configurationDisplayName("Sakk")
        .description("The next warranty to end.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private extension String {
    var containsArabic: Bool { unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) } }
}

private extension View {
    // iOS 17 requires containerBackground; older versions use a plain background.
    @ViewBuilder
    func widgetBackground<B: View>(_ background: B) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { background }
        } else {
            padding().background(background)
        }
    }
}
