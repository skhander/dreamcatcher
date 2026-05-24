import WidgetKit
import SwiftUI

struct DreamCaptureEntry: TimelineEntry {
    let date: Date
}

struct DreamCaptureProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamCaptureEntry {
        DreamCaptureEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (DreamCaptureEntry) -> Void) {
        completion(DreamCaptureEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamCaptureEntry>) -> Void) {
        let entry = DreamCaptureEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct DreamCaptureWidgetView: View {
    var entry: DreamCaptureEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            accessoryCircular
        case .accessoryRectangular:
            accessoryRectangular
        default:
            homeScreenWidget
        }
    }

    private var homeScreenWidget: some View {
        Link(destination: URL(string: "dreamcatcher://capture")!) {
            ZStack {
                ContainerRelativeShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.14, green: 0.08, blue: 0.22),
                                Color(red: 0.08, green: 0.07, blue: 0.20),
                                Color(red: 0.22, green: 0.55, blue: 0.58).opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 8) {
                    Image(systemName: "cloud.moon.fill")
                        .font(.title2)
                        .foregroundStyle(Color(red: 0.55, green: 0.28, blue: 0.85))

                    Text("Catch")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(red: 0.96, green: 0.91, blue: 0.82))
                }
            }
        }
    }

    private var accessoryCircular: some View {
        Link(destination: URL(string: "dreamcatcher://capture")!) {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "cloud.moon.fill")
                    .font(.title3)
            }
        }
    }

    private var accessoryRectangular: some View {
        Link(destination: URL(string: "dreamcatcher://capture")!) {
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dream Catcher")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("Tap to catch a dream")
                        .font(.caption2)
                        .opacity(0.7)
                }
            }
        }
    }
}

struct DreamCaptureWidget: Widget {
    let kind: String = "DreamCaptureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DreamCaptureProvider()) { entry in
            DreamCaptureWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.14, green: 0.08, blue: 0.22)
                }
        }
        .configurationDisplayName("Capture Dream")
        .description("One tap to capture a dream fragment.")
        .supportedFamilies([
            .systemSmall,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

@main
struct DreamCatcherWidgetBundle: WidgetBundle {
    var body: some Widget {
        DreamCaptureWidget()
    }
}
