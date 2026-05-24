import SwiftUI
import SwiftData

struct DreamTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dream.createdAt, order: .reverse) private var dreams: [Dream]
    @Query private var lifeEntries: [LifeEntry]
    @State private var animationPhase: CGFloat = 0
    @State private var dashPhase: CGFloat = 0
    @State private var dreamPendingDeletion: Dream?

    var body: some View {
        NavigationStack {
            ZStack {
                DreamscapeBackground(intensity: .celestial)
                    .ignoresSafeArea()

                if dreams.isEmpty {
                    emptyState
                } else {
                    timelineContent
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: UUID.self) { dreamID in
                if let dream = dreams.first(where: { $0.id == dreamID }) {
                    DreamDetailView(dream: dream)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                dashPhase = 20
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(DreamTheme.goldDust.opacity(0.6))
                .breathingPulse()
            Text("No dreams yet")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundStyle(DreamTheme.moonlight.opacity(0.6))
            Text("Record one and it'll appear here")
                .font(.caption)
                .foregroundStyle(DreamTheme.moonlight.opacity(0.4))
        }
    }

    private var timelineContent: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                remWaveLine
                    .frame(height: CGFloat(dreams.count) * 100 + 100)

                threadConnections
                    .frame(height: CGFloat(dreams.count) * 100 + 100)

                VStack(spacing: 0) {
                    ForEach(Array(dreams.enumerated()), id: \.element.id) { index, dream in
                        timelineRow(dream: dream, index: index)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .confirmationDialog(
            "Delete this dream?",
            isPresented: Binding(
                get: { dreamPendingDeletion != nil },
                set: { if !$0 { dreamPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let dream = dreamPendingDeletion {
                    DreamDeletionService.delete(dream, context: modelContext, lifeEntries: lifeEntries)
                }
                dreamPendingDeletion = nil
            }
        } message: {
            Text("This can't be undone.")
        }
    }

    private var remWaveLine: some View {
        Canvas { context, size in
            var path = Path()
            let midX = size.width * 0.5
            path.move(to: CGPoint(x: midX, y: 0))
            for y in stride(from: 0, through: size.height, by: 4) {
                let x = midX + sin(y / 28 + animationPhase * 8) * 12
                path.addLine(to: CGPoint(x: x, y: y))
            }
            context.stroke(
                path,
                with: .color(DreamTheme.tealMist.opacity(0.12)),
                style: StrokeStyle(lineWidth: 1, dash: [2, 8], dashPhase: dashPhase)
            )
        }
    }

    private var threadConnections: some View {
        Canvas { context, size in
            let symbolMap = buildSymbolConnections()

            for (_, indices) in symbolMap where indices.count >= 2 {
                let points = indices.map { index -> CGPoint in
                    let y = CGFloat(index) * 100 + 50
                    let xOffset = index.isMultiple(of: 2) ? size.width * 0.25 : size.width * 0.75
                    return CGPoint(x: xOffset, y: y)
                }

                for i in 0..<(points.count - 1) {
                    var path = Path()
                    path.move(to: points[i])
                    let mid = CGPoint(
                        x: (points[i].x + points[i + 1].x) / 2,
                        y: (points[i].y + points[i + 1].y) / 2
                    )
                    path.addQuadCurve(to: points[i + 1], control: mid)

                    context.stroke(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                DreamTheme.electricViolet.opacity(0.25),
                                DreamTheme.goldDust.opacity(0.35),
                                DreamTheme.sunsetOrange.opacity(0.2)
                            ]),
                            startPoint: points[i],
                            endPoint: points[i + 1]
                        ),
                        style: StrokeStyle(lineWidth: 1.2, dash: [4, 6], dashPhase: dashPhase)
                    )
                }
            }
        }
    }

    private func buildSymbolConnections() -> [String: [Int]] {
        var map: [String: [Int]] = [:]
        for (index, dream) in dreams.enumerated() {
            for symbol in dream.symbols {
                map[symbol, default: []].append(index)
            }
        }
        return map
    }

    private func timelineRow(dream: Dream, index: Int) -> some View {
        HStack(alignment: .center, spacing: 16) {
            if index.isMultiple(of: 2) {
                dreamOrb(dream: dream, index: index)
                Spacer()
                dateLabel(dream: dream)
            } else {
                dateLabel(dream: dream)
                Spacer()
                dreamOrb(dream: dream, index: index)
            }
        }
        .frame(height: 100)
        .contextMenu {
            Button("Delete Dream", role: .destructive) {
                dreamPendingDeletion = dream
            }
        }
    }

    private func dreamOrb(dream: Dream, index: Int) -> some View {
        NavigationLink(value: dream.id) {
            ZStack {
                Circle()
                    .fill(orbColor(for: dream).opacity(0.25))
                    .frame(width: 78, height: 78)
                    .blur(radius: 10)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                orbColor(for: dream).opacity(0.75),
                                orbColor(for: dream).opacity(0.2),
                                DreamTheme.cosmicPlum.opacity(0.2)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 38
                        )
                    )
                    .frame(width: 58, height: 58)
                    .overlay(
                        Circle()
                            .stroke(DreamTheme.iridescentBorder, lineWidth: 1)
                    )

                if let symbol = dream.symbols.first, !symbol.isEmpty {
                    Text(symbol)
                        .font(.system(size: 11, weight: .light, design: .rounded))
                        .foregroundStyle(DreamTheme.creamDream.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: 54)
                }
            }
            .orbFloat(seed: Double(index) * 0.7 + 1.2)
        }
        .buttonStyle(.plain)
    }

    private func dateLabel(dream: Dream) -> some View {
        VStack(alignment: indexAlignment(for: dream), spacing: 4) {
            Text(dream.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption)
                .foregroundStyle(DreamTheme.lavender)

            Text(dream.displayTitle)
                .font(.system(size: 13, weight: .light, design: .serif))
                .foregroundStyle(DreamTheme.moonlight.opacity(0.7))
                .lineLimit(2)
                .multilineTextAlignment(indexAlignment(for: dream) == .leading ? .leading : .trailing)
        }
        .frame(maxWidth: 160)
    }

    private func indexAlignment(for dream: Dream) -> HorizontalAlignment {
        guard let index = dreams.firstIndex(where: { $0.id == dream.id }) else { return .leading }
        return index.isMultiple(of: 2) ? .trailing : .leading
    }

    private func orbColor(for dream: Dream) -> Color {
        if let emotion = dream.primaryEmotion {
            return DreamTheme.emotionColor(emotion)
        }
        return DreamTheme.electricViolet
    }
}
