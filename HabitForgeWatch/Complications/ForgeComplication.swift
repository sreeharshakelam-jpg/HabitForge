import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct ForgeEntry: TimelineEntry {
    let date: Date
    let progress: Double
    let streak: Int
    let level: Int
    let pendingCount: Int
}

// MARK: - Timeline Provider

struct ForgeProvider: TimelineProvider {
    func placeholder(in context: Context) -> ForgeEntry {
        ForgeEntry(date: Date(), progress: 0.6, streak: 7, level: 3, pendingCount: 2)
    }

    func getSnapshot(in context: Context, completion: @escaping (ForgeEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ForgeEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh every 30 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> ForgeEntry {
        let defaults = UserDefaults.standard
        return ForgeEntry(
            date: Date(),
            progress: defaults.double(forKey: "complication_progress"),
            streak: defaults.integer(forKey: "complication_streak"),
            level: defaults.integer(forKey: "wc_level"),
            pendingCount: defaults.integer(forKey: "complication_pending")
        )
    }
}

// MARK: - Complication Views

// Circular — progress ring + streak
struct ForgeCircularView: View {
    let entry: ForgeEntry

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 3)
            Circle()
                .trim(from: 0, to: entry.progress)
                .stroke(Color.purple, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(Int(entry.progress * 100))")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                Image(systemName: "flame.fill")
                    .font(.system(size: 7))
                    .foregroundColor(.orange)
            }
            .foregroundColor(.white)
        }
    }
}

// Corner — streak count
struct ForgeCornerView: View {
    let entry: ForgeEntry

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            HStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
                Text("\(entry.streak)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
            }
            Text("\(Int(entry.progress * 100))%")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .foregroundColor(.white)
    }
}

// Rectangular — full bar
struct ForgeRectangularView: View {
    let entry: ForgeEntry

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 3)
                    .frame(width: 30, height: 30)
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 30, height: 30)
                Text("\(Int(entry.progress * 100))%")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Virtue Forge")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Label("\(entry.streak)d", systemImage: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                    Label("Lv.\(entry.level)", systemImage: "crown.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.yellow)
                    if entry.pendingCount > 0 {
                        Label("\(entry.pendingCount)", systemImage: "circle")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
        }
    }
}

// MARK: - Widget

@main
struct ForgeWidget: Widget {
    let kind = "ForgeComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ForgeProvider()) { entry in
            ForgeWidgetEntryView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Virtue Forge")
        .description("Track your habit progress on your watch face.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

struct ForgeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ForgeEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            ForgeCircularView(entry: entry)
        case .accessoryCorner:
            ForgeCornerView(entry: entry)
        case .accessoryRectangular:
            ForgeRectangularView(entry: entry)
        case .accessoryInline:
            Label("\(entry.streak)🔥 \(Int(entry.progress * 100))%", systemImage: "flame.fill")
        default:
            ForgeCircularView(entry: entry)
        }
    }
}
