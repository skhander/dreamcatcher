import Foundation

enum LifeRecapService {
    static func weeklyRecap(dreams: [Dream], lifeEntries: [LifeEntry]) -> String {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let weekDreams = dreams.filter { $0.createdAt >= weekAgo }
        let weekLife = lifeEntries.filter { $0.createdAt >= weekAgo }

        guard !weekDreams.isEmpty || !weekLife.isEmpty else {
            return "Nothing logged this week yet. Save a dream or add a note to start."
        }

        var parts: [String] = []

        let tagCounts = Dictionary(grouping: weekLife.flatMap(\.tags), by: { $0 }).mapValues(\.count).sorted { $0.value > $1.value }
        if let topTag = tagCounts.first {
            parts.append("\"\(topTag.key)\" came up \(topTag.value) time\(topTag.value == 1 ? "" : "s") in your notes.")
        }

        let emotions = weekDreams.compactMap(\.primaryEmotion)
        if let dominant = Dictionary(grouping: emotions, by: { $0 }).max(by: { $0.value.count < $1.value.count })?.key {
            parts.append("Most dreams felt \(dominant.displayName.lowercased()).")
        }

        let symbols = weekDreams.flatMap(\.symbols)
        let topSymbols = Dictionary(grouping: symbols, by: { $0 }).sorted { $0.value.count > $1.value.count }.prefix(2).map(\.key)
        if !topSymbols.isEmpty {
            parts.append("Recurring images: \(topSymbols.joined(separator: " and ")).")
        }

        if tagCounts.contains(where: { $0.key.lowercased() == "work" }),
           weekDreams.contains(where: { $0.symbols.contains("airport") || $0.symbols.contains("train") || $0.primaryEmotion == .transition }) {
            parts.append("You had movement-themed dreams alongside notes about work — your mind may be working through change.")
        }

        if parts.isEmpty {
            parts.append("Keep logging. Patterns get clearer over a few weeks.")
        }

        return parts.joined(separator: " ")
    }

    static func lifeCorrelations(dreams: [Dream], lifeEntries: [LifeEntry]) -> [String] {
        var insights: [String] = []
        let tagCounts = Dictionary(grouping: lifeEntries.flatMap(\.tags), by: { $0 }).mapValues(\.count)

        for (tag, count) in tagCounts where count >= 2 {
            let linkedDreams = dreams.filter { dream in
                lifeEntries.contains { entry in
                    entry.linkedDreamID == dream.id && entry.tags.contains(tag)
                }
            }
            if !linkedDreams.isEmpty {
                let emotion = linkedDreams.compactMap(\.primaryEmotion).first?.displayName.lowercased() ?? "mixed emotions"
                insights.append("When you tagged \"\(tag)\", your dreams often felt \(emotion).")
            }
        }

        let waterDreams = dreams.filter { $0.symbols.contains(where: { ["water", "ocean", "rain"].contains($0) }) }
        if waterDreams.count >= 2, tagCounts["Family"] != nil || tagCounts["Faith"] != nil {
            insights.append("Water shows up in your dreams around the times you write about family or faith.")
        }

        return insights
    }
}
