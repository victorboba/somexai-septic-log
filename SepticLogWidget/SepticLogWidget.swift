import WidgetKit
import SwiftUI

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: .now, snapshot: context.isPreview ? .placeholder : WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let entry = SnapshotEntry(date: .now, snapshot: WidgetSnapshot.load())
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct SepticLogWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    private var due: Int { entry.snapshot.dueSoon }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Septic", systemImage: due > 0 ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(due > 0 ? .orange : .green)

            Spacer(minLength: 0)

            // A homeowner does not want a count of records. They want the next date.
            if let title = entry.snapshot.lastEntryTitle, let date = entry.snapshot.lastEntryDate {
                Text(title)
                    .font(.footnote.weight(.medium))
                    .lineLimit(2)
                Text(date, style: .relative)
                    .font(.system(size: family == .systemSmall ? 17 : 22, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if entry.snapshot.totalEntries == 0 {
                Text("Add your last pump-out")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("Nothing due")
                    .font(.headline)
                Text("\(entry.snapshot.totalEntries) records kept")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SepticLogWidget: Widget {
    let kind = "SepticLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            SepticLogWidgetView(entry: entry)
        }
        .configurationDisplayName(AppConfig.appName)
        .description("\(AppConfig.entryNounPlural) this week and your latest one.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct SepticLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        SepticLogWidget()
    }
}
