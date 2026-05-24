import Foundation
import SwiftData

struct PatternInsight: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let symbol: String?
}

@MainActor
final class PatternEngine {
    static let shared = PatternEngine()

    private init() {}

    func updatePatterns(for dream: Dream, context: ModelContext) async {
        try? context.save()
    }

    func generateInsights(dreams: [Dream], symbols: [DreamSymbol], personas: [DreamPersona]) -> [PatternInsight] {
        var insights: [PatternInsight] = []

        let symbolCounts = Dictionary(grouping: dreams.flatMap { $0.symbols }, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        if let top = symbolCounts.first, top.value >= 2 {
            let personalNote = symbols.first(where: { $0.name == top.key })?.contextNotes
            insights.append(PatternInsight(
                title: "Recurring symbol: \(top.key)",
                detail: personalNote ?? "\(top.key) has shown up \(top.value) times in your dreams. Its meaning is personal — notice what's going on in your life when it appears.",
                symbol: top.key
            ))
        }

        let emotionCounts = Dictionary(grouping: dreams.compactMap { $0.dominantEmotion }, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        if let topEmotion = emotionCounts.first, topEmotion.value >= 2,
           let emotion = DreamEmotion(rawValue: topEmotion.key) {
            insights.append(PatternInsight(
                title: "Common feeling: \(emotion.displayName)",
                detail: "\(topEmotion.value) of your dreams felt \(emotion.displayName.lowercased()). \(emotion.prompt.capitalized).",
                symbol: nil
            ))
        }

        if dreams.contains(where: { $0.symbols.contains("elevator") || $0.locations.contains("elevator") }) {
            let elevatorDreams = dreams.filter { $0.symbols.contains("elevator") || $0.locations.contains("elevator") }
            if elevatorDreams.count >= 2 {
                insights.append(PatternInsight(
                    title: "Thresholds",
                    detail: "Elevators show up in \(elevatorDreams.count) dreams. These often come up around big decisions or identity shifts.",
                    symbol: "elevator"
                ))
            }
        }

        let waterDreams = dreams.filter { dream in
            dream.symbols.contains(where: { ["water", "ocean", "rain", "beach"].contains($0) }) ||
            dream.rawTranscript.lowercased().contains("water") ||
            dream.rawTranscript.lowercased().contains("ocean")
        }
        if waterDreams.count >= 2 {
            insights.append(PatternInsight(
                title: "Water",
                detail: "Water has come up in \(waterDreams.count) dreams. For you, it may track times of emotional intensity.",
                symbol: "water"
            ))
        }

        for persona in personas where persona.appearanceCount >= 2 {
            insights.append(PatternInsight(
                title: "\(persona.personaArchetype.rawValue): \(persona.name)",
                detail: "\(persona.name) has appeared \(persona.appearanceCount) times. \(persona.personaArchetype.description)",
                symbol: nil
            ))
        }

        if insights.isEmpty, !dreams.isEmpty {
            insights.append(PatternInsight(
                title: "Just getting started",
                detail: "Keep recording. Patterns usually start to show up after a few weeks of dreams.",
                symbol: nil
            ))
        }

        return insights
    }

    func personalSymbolInsight(for symbol: DreamSymbol, dreams: [Dream]) -> String {
        let relatedDreams = dreams.filter { $0.symbols.contains(symbol.name) }
        let emotions = symbol.associatedEmotions.compactMap { DreamEmotion(rawValue: $0) }

        var parts: [String] = []
        parts.append("\"\(symbol.name)\" has come up in \(symbol.appearanceCount) dream\(symbol.appearanceCount == 1 ? "" : "s").")

        if !emotions.isEmpty {
            parts.append("Often alongside \(emotions.map(\.displayName).joined(separator: ", ").lowercased()).")
        }

        if relatedDreams.count >= 2 {
            let recent = relatedDreams.prefix(3).compactMap { $0.reconstructedNarrative?.prefix(60) }
            if !recent.isEmpty {
                parts.append("This is one of your personal symbols. What it means is shaped by your dreams, not a dictionary.")
            }
        }

        return parts.joined(separator: " ")
    }

    func generateSubconsciousStory(dreams: [Dream], month: Date = Date()) -> String {
        let calendar = Calendar.current
        let monthDreams = dreams.filter {
            calendar.component(.month, from: $0.createdAt) == calendar.component(.month, from: month) &&
            calendar.component(.year, from: $0.createdAt) == calendar.component(.year, from: month)
        }

        guard !monthDreams.isEmpty else {
            return "No dreams recorded this month yet. Save one and a recap will start to take shape."
        }

        let emotions = monthDreams.compactMap { $0.primaryEmotion }
        let dominant = Dictionary(grouping: emotions, by: { $0 }).max(by: { $0.value.count < $1.value.count })?.key

        let allSymbols = monthDreams.flatMap { $0.symbols }
        let topSymbols = Dictionary(grouping: allSymbols, by: { $0 }).sorted { $0.value.count > $1.value.count }.prefix(3).map(\.key)

        var story = "\(month.formatted(.dateTime.month(.wide))) has been "

        if let dominant {
            story += "mostly \(dominant.displayName.lowercased()) — \(dominant.prompt). "
        } else {
            story += "quiet in your archive so far. "
        }

        if !topSymbols.isEmpty {
            story += "Recurring images: \(topSymbols.joined(separator: ", ")). "
        }

        let transitionDreams = monthDreams.filter { $0.emotions.contains(DreamEmotion.transition.rawValue) || $0.symbols.contains("airport") || $0.symbols.contains("train") }
        if transitionDreams.count >= 2 {
            story += "Movement and passage have been showing up — your mind may be working through a change. "
        }

        story += "Check back next month and see what's shifted."

        return story
    }
}
