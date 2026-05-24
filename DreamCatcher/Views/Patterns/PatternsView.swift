import SwiftUI
import SwiftData

struct PatternsView: View {
    @Query(sort: \Dream.createdAt, order: .reverse) private var dreams: [Dream]
    @Query(sort: \DreamSymbol.appearanceCount, order: .reverse) private var symbols: [DreamSymbol]
    @Query(sort: \DreamPersona.appearanceCount, order: .reverse) private var personas: [DreamPersona]
    @Query(sort: \LifeEntry.createdAt, order: .reverse) private var lifeEntries: [LifeEntry]

    @StateObject private var healthKit = HealthKitService.shared
    @State private var insights: [PatternInsight] = []
    @State private var subconsciousStory = ""
    @State private var lifeCorrelations: [String] = []

    var body: some View {
        NavigationStack {
            ZStack {
                DreamscapeBackground(intensity: .standard)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        subconsciousStoryCard
                        lifeCorrelationsSection
                        insightsSection
                        symbolsSection
                        personasSection
                        healthSection
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Patterns")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                refreshInsights()
                Task {
                    if healthKit.isAvailable && !healthKit.isAuthorized {
                        await healthKit.requestAuthorization()
                    }
                    _ = healthKit.correlateSleepWithDreams(dreams)
                }
            }
            .onChange(of: dreams.count) { _, _ in
                refreshInsights()
            }
            .onChange(of: lifeEntries.count) { _, _ in
                refreshInsights()
            }
        }
    }

    private func refreshInsights() {
        insights = PatternEngine.shared.generateInsights(dreams: dreams, symbols: symbols, personas: personas)
        subconsciousStory = PatternEngine.shared.generateSubconsciousStory(dreams: dreams)
        lifeCorrelations = LifeRecapService.lifeCorrelations(dreams: dreams, lifeEntries: lifeEntries)
    }

    private var lifeCorrelationsSection: some View {
        Group {
            if !lifeCorrelations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dreams and life")
                        .font(.caption)
                        .foregroundStyle(DreamTheme.lavender)

                    ForEach(lifeCorrelations, id: \.self) { correlation in
                        Text(correlation)
                            .font(.system(size: 14, weight: .light, design: .serif))
                            .foregroundStyle(DreamTheme.moonlight.opacity(0.75))
                            .lineSpacing(4)
                            .padding(16)
                            .glassCard()
                    }
                }
            }
        }
    }

    private var subconsciousStoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.book.closed.fill")
                    .foregroundStyle(DreamTheme.lavender)
                Text("What your dreams keep saying")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(DreamTheme.moonlight)
            }

            Text(subconsciousStory)
                .font(.system(size: 15, weight: .light, design: .serif))
                .foregroundStyle(DreamTheme.moonlight.opacity(0.85))
                .lineSpacing(6)
        }
        .padding(20)
        .glassCard()
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.caption)
                .foregroundStyle(DreamTheme.lavender)

            ForEach(insights) { insight in
                VStack(alignment: .leading, spacing: 8) {
                    Text(insight.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DreamTheme.moonlight)

                    Text(insight.detail)
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .foregroundStyle(DreamTheme.moonlight.opacity(0.7))
                        .lineSpacing(4)
                }
                .padding(16)
                .glassCard()
            }
        }
    }

    private var symbolsSection: some View {
        Group {
            if !symbols.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recurring symbols")
                        .font(.caption)
                        .foregroundStyle(DreamTheme.lavender)

                    ForEach(symbols.prefix(8)) { symbol in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(symbol.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(DreamTheme.softGlow)
                                Spacer()
                                Text("\(symbol.appearanceCount)×")
                                    .font(.caption)
                                    .foregroundStyle(DreamTheme.moonlight.opacity(0.4))
                            }

                            Text(PatternEngine.shared.personalSymbolInsight(for: symbol, dreams: dreams))
                                .font(.system(size: 13, weight: .light, design: .serif))
                                .foregroundStyle(DreamTheme.moonlight.opacity(0.6))
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .glassCard()
                    }
                }
            }
        }
    }

    private var personasSection: some View {
        Group {
            if !personas.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("People in your dreams")
                        .font(.caption)
                        .foregroundStyle(DreamTheme.lavender)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(personas) { persona in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(persona.personaArchetype.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(DreamTheme.lavender)

                                    Text(persona.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(DreamTheme.moonlight)

                                    Text("\(persona.appearanceCount) appearances")
                                        .font(.caption2)
                                        .foregroundStyle(DreamTheme.moonlight.opacity(0.5))

                                    Text(persona.personaArchetype.description)
                                        .font(.system(size: 12, weight: .light, design: .serif))
                                        .foregroundStyle(DreamTheme.moonlight.opacity(0.6))
                                        .lineLimit(3)
                                }
                                .frame(width: 180)
                                .padding(16)
                                .glassCard()
                            }
                        }
                    }
                }
            }
        }
    }

    private var healthSection: some View {
        Group {
            if healthKit.isAvailable {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "heart.text.square")
                            .foregroundStyle(DreamTheme.lavender)
                        Text("Sleep")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(DreamTheme.moonlight)
                    }

                    if let hours = healthKit.averageSleepHours {
                        Text(String(format: "Average sleep: %.1f hours", hours))
                            .font(.caption)
                            .foregroundStyle(DreamTheme.moonlight.opacity(0.5))
                    }

                    if let note = healthKit.sleepCorrelationNote {
                        Text(note)
                            .font(.system(size: 14, weight: .light, design: .serif))
                            .foregroundStyle(DreamTheme.moonlight.opacity(0.7))
                            .lineSpacing(4)
                    } else if !healthKit.isAuthorized {
                        Button {
                            Task { await healthKit.requestAuthorization() }
                        } label: {
                            Text("Connect Apple Health")
                                .font(.caption)
                                .foregroundStyle(DreamTheme.lavender)
                        }
                    } else {
                        Text("Record more dreams to see how they line up with your sleep.")
                            .font(.system(size: 14, weight: .light, design: .serif))
                            .foregroundStyle(DreamTheme.moonlight.opacity(0.5))
                    }
                }
                .padding(20)
                .glassCard()
            }
        }
    }
}
