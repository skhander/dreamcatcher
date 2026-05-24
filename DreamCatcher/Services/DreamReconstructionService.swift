import Foundation
import SwiftData

@MainActor
final class DreamReconstructionService {
    static let shared = DreamReconstructionService()

    private init() {}

    func processDream(_ dream: Dream, context: ModelContext) async {
        let input = buildInput(from: dream)
        let extracted = extractElements(from: input, dream: dream)

        dream.symbols = extracted.symbols
        dream.locations = extracted.locations
        dream.people = extracted.people

        if dream.dominantEmotion == nil, let inferred = extracted.inferredEmotion {
            dream.dominantEmotion = inferred.rawValue
            if !dream.emotions.contains(inferred.rawValue) {
                dream.emotions.append(inferred.rawValue)
            }
        }

        dream.reconstructedNarrative = reconstructNarrative(from: input, extracted: extracted)
        dream.emotionalMirror = generateEmotionalMirror(dream: dream, extracted: extracted)
        dream.modernPsychology = generateModernPsychology(dream: dream, extracted: extracted)
        dream.jungianSymbolic = generateJungianSymbolic(dream: dream, extracted: extracted)
        dream.narrativeReflection = generateNarrativeReflection(dream: dream, context: context)
        dream.islamicReflection = generateIslamicReflection(dream: dream, extracted: extracted, context: context)
        dream.isReconstructed = true

        updateSymbolMemory(extracted: extracted, dream: dream, context: context)
        updatePersonas(extracted: extracted, dream: dream, context: context)

        try? context.save()
    }

    func generateReflectiveResponse(for message: String, dream: Dream, lifeContext: String? = nil) -> String {
        let lower = message.lowercased()
        let lens = AppSettings.interpretationLens
        let useIslamic = lens == .islamicReflection || lens == .both

        if useIslamic {
            if lower.contains("yes") || lower.contains("connected") || lower.contains("related") {
                return "Worth sitting with. Meaningful dreams usually invite reflection, not decoding every image. Just naming the connection is often enough."
            }
            if lower.contains("afraid") || lower.contains("scared") || lower.contains("bad dream") {
                return "Disturbing dreams are usually not meant to be dwelled on or shared widely. Seek refuge, say a brief du'a, and turn toward what steadies you. If something in waking life is weighing on you, that's still worth noticing."
            }
            if lower.contains("family") || lower.contains("faith") {
                return "Family and faith run deep. Dreams sometimes surface what we're carrying for the people we love — or what we're asking Allah for."
            }
        }

        if let lifeContext, !lifeContext.isEmpty, lower.contains("yes") || lower.contains("connected") {
            return "You mentioned \(lifeContext). This dream might be picking up on that. The link doesn't have to be exact to matter."
        }

        if lower.contains("work") || lower.contains("job") || lower.contains("career") {
            return "Sounds like something at work is on your mind. Dreams often carry the weight of things we haven't said out loud yet."
        }
        if lower.contains("relationship") || lower.contains("partner") || lower.contains("love") {
            return "Relationships sit deep. The people in your dream may not be literal — sometimes they stand in for parts of you wanting closeness, or distance."
        }
        if lower.contains("afraid") || lower.contains("scared") || lower.contains("anxious") {
            return "Fear in dreams rarely points to actual danger. More often it shows up around a change you're approaching or haven't fully processed."
        }
        if lower.contains("yes") || lower.contains("connected") || lower.contains("related") {
            return "That matters. You don't have to figure it all out tonight. Naming the link is usually a good start."
        }
        if lower.contains("no") || lower.contains("don't know") || lower.contains("not sure") {
            return "That's fine. Dreams don't always have a clear waking match. Sometimes the meaning shows up later, once patterns appear."
        }

        if useIslamic {
            return "Thanks for sharing. Sit with what feels true. Not every dream needs interpretation. For ones that feel significant or recurring, talking to someone knowledgeable can help."
        }

        return "Thanks for sharing. Is there a specific image from the dream you want to sit with?"
    }

    private func buildInput(from dream: Dream) -> String {
        var parts: [String] = []
        if !dream.rawTranscript.isEmpty { parts.append(dream.rawTranscript) }
        parts.append(contentsOf: dream.fragments.map(\.content))
        parts.append(contentsOf: dream.emotions)
        parts.append(contentsOf: dream.colors)
        return parts.joined(separator: ". ")
    }

    private struct ExtractedElements {
        var symbols: [String]
        var locations: [String]
        var people: [String]
        var inferredEmotion: DreamEmotion?
        var themes: [String]
    }

    private func extractElements(from input: String, dream: Dream) -> ExtractedElements {
        let lower = input.lowercased()
        let words = lower.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }

        let locationKeywords = ["airport", "train", "station", "house", "home", "school", "hotel", "room", "forest", "ocean", "beach", "city", "road", "bridge", "hospital", "church", "garden", "elevator", "stairs"]
        let peopleKeywords = ["mother", "mom", "father", "dad", "child", "friend", "stranger", "teacher", "brother", "sister", "partner", "baby"]
        let symbolKeywords = ["bird", "dog", "cat", "water", "fire", "moon", "mirror", "door", "snake", "wolf", "flight", "car", "boat", "tree", "rain", "snow"]

        var symbols = Set<String>()
        var locations = Set<String>()
        var people = Set<String>()

        for word in words {
            if locationKeywords.contains(word) { locations.insert(word) }
            if peopleKeywords.contains(word) { people.insert(word) }
            if symbolKeywords.contains(word) { symbols.insert(word) }
        }

        symbols.formUnion(locations)

        var themes: [String] = []
        if lower.contains("miss") || lower.contains("late") || lower.contains("lost") { themes.append("separation") }
        if lower.contains("fly") || lower.contains("float") || lower.contains("free") { themes.append("freedom") }
        if lower.contains("chase") || lower.contains("run") || lower.contains("follow") { themes.append("pursuit") }
        if lower.contains("water") || lower.contains("ocean") || lower.contains("rain") { themes.append("water imagery") }
        if lower.contains("travel") || lower.contains("journey") || lower.contains("airport") || lower.contains("train") { themes.append("travel") }

        let inferredEmotion: DreamEmotion? = {
            if let dominant = dream.dominantEmotion, let e = DreamEmotion(rawValue: dominant) { return e }
            if lower.contains("peace") || lower.contains("calm") { return .peace }
            if lower.contains("fear") || lower.contains("scared") { return .fear }
            if lower.contains("long") || lower.contains("miss") { return .longing }
            if lower.contains("wonder") || lower.contains("beautiful") { return .wonder }
            if themes.contains("travel") { return .transition }
            return nil
        }()

        return ExtractedElements(
            symbols: Array(symbols),
            locations: Array(locations),
            people: Array(people),
            inferredEmotion: inferredEmotion,
            themes: themes
        )
    }

    private func reconstructNarrative(from input: String, extracted: ExtractedElements) -> String {
        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "A dream remembered in pieces. Impressions stayed after waking, even if the story didn't."
        }

        var sentences: [String] = []

        if let location = extracted.locations.first {
            let locationPhrase = locationPhrase(for: location)
            sentences.append("You were in \(locationPhrase).")
        } else if !extracted.themes.isEmpty {
            sentences.append("The dream moved through \(extracted.themes.joined(separator: " and ")).")
        } else {
            sentences.append("The dream came in pieces — images and feelings more than a clear story.")
        }

        if let person = extracted.people.first {
            sentences.append("\(person.capitalized) showed up.")
        }

        if extracted.symbols.contains("bird") || input.lowercased().contains("bird") {
            sentences.append("Birds kept appearing.")
        }

        if extracted.themes.contains("water imagery") {
            sentences.append("Water was somewhere in it.")
        }

        if extracted.themes.contains("separation") {
            sentences.append("There was a sense of something missed or left behind.")
        }

        if extracted.themes.contains("pursuit") {
            sentences.append("Something was moving — chasing, or being moved toward.")
        }

        if let emotion = extracted.inferredEmotion {
            sentences.append("What stayed strongest was \(emotion.prompt).")
        }

        if sentences.count < 2 {
            let fragments = input.components(separatedBy: CharacterSet(charactersIn: ".,…")).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            if fragments.count > 1 {
                sentences.append("Pieces you mentioned: \(fragments.prefix(4).joined(separator: ", ")).")
            }
        }

        return sentences.joined(separator: " ")
    }

    private func locationPhrase(for location: String) -> String {
        switch location {
        case "airport": return "an airport that felt suspended in time"
        case "train", "station": return "a train station between departures"
        case "ocean", "beach": return "a vast shoreline"
        case "forest": return "a forest thick with shadow and light"
        case "hotel": return "a hotel room that didn't quite feel like yours"
        case "elevator": return "an elevator moving between floors you couldn't name"
        case "school": return "a school from an earlier chapter of life"
        default: return "a \(location) that felt both familiar and strange"
        }
    }

    private func generateEmotionalMirror(dream: Dream, extracted: ExtractedElements) -> String {
        if let emotion = extracted.inferredEmotion ?? dream.primaryEmotion {
            return "This dream felt \(emotion.displayName.lowercased()) — \(emotion.prompt). The feeling usually says more than the plot."
        }
        return "Sit with what lingered after you woke up. That feeling usually says more than any detail in the dream."
    }

    private func generateModernPsychology(dream: Dream, extracted: ExtractedElements) -> String {
        var insights: [String] = []

        if extracted.themes.contains("travel") || extracted.themes.contains("separation") {
            insights.append("Travel and missed connections in dreams often come up during transitions — when your mind is processing change before you've named it.")
        }
        if !extracted.people.isEmpty {
            insights.append("People in dreams usually stand in for the relationship more than the actual person — closeness, distance, or unfinished conversation.")
        }
        if extracted.themes.contains("pursuit") {
            insights.append("Chase dreams can show up around avoidance, or around ambition that hasn't found a direction yet.")
        }
        if dream.emotions.contains(DreamEmotion.peace.rawValue) {
            insights.append("Peaceful dreams after a hard stretch usually mean your mind is settling — processing and moving on.")
        }

        if insights.isEmpty {
            insights.append("Your mind tends to mix recent experiences with older emotional material in dreams. This one may be doing that.")
        }

        return insights.joined(separator: " ")
    }

    private func generateJungianSymbolic(dream: Dream, extracted: ExtractedElements) -> String {
        var insights: [String] = []

        if extracted.symbols.contains("water") || extracted.themes.contains("water imagery") {
            insights.append("Water often stands in for the unconscious — fluid, not fully knowable. Something underneath may be looking for expression.")
        }
        if extracted.symbols.contains("door") || extracted.locations.contains("elevator") {
            insights.append("Doors, elevators, and stairs are classic symbols of transition. You may be between one phase and another.")
        }
        if extracted.people.contains("stranger") {
            insights.append("A stranger in a dream often represents a part of yourself you haven't met yet.")
        }
        if extracted.themes.contains("pursuit") {
            insights.append("What chases you in a dream may be something you've pushed away in waking life, asking to be acknowledged.")
        }

        if insights.isEmpty {
            insights.append("Every symbol here is personal first. What \(extracted.symbols.first ?? "these images") mean to you over time matters more than any dictionary.")
        }

        return insights.joined(separator: " ")
    }

    private func generateNarrativeReflection(dream: Dream, context: ModelContext) -> String {
        let descriptor = FetchDescriptor<Dream>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let allDreams = try? context.fetch(descriptor) else {
            return "Patterns will show up as you log more dreams — recurring symbols, emotional stretches, people who keep appearing."
        }

        let others = allDreams.filter { $0.id != dream.id }
        guard !others.isEmpty else {
            return "First dream in your archive. Come back in a few weeks — patterns take a little time to show up."
        }

        var reflections: [String] = []

        let sharedSymbols = Set(dream.symbols).intersection(Set(others.flatMap { $0.symbols }))
        if let symbol = sharedSymbols.first {
            let count = others.filter { $0.symbols.contains(symbol) }.count
            reflections.append("\"\(symbol)\" has shown up in \(count) other dream\(count == 1 ? "" : "s"). It's becoming one of your recurring images.")
        }

        let threeWeeksAgo = Calendar.current.date(byAdding: .day, value: -21, to: Date()) ?? Date()
        let recentDreams = others.filter { $0.createdAt >= threeWeeksAgo }
        let sharedThemes = Set(dream.symbols).intersection(Set(recentDreams.flatMap { $0.symbols }))
        if !sharedThemes.isEmpty {
            reflections.append("Themes from recent weeks show up again here. Your mind may still be working on something.")
        }

        if let emotion = dream.primaryEmotion {
            let sameEmotion = others.filter { $0.dominantEmotion == emotion.rawValue }.count
            if sameEmotion >= 2 {
                reflections.append("\(emotion.displayName) has come up in \(sameEmotion) other dreams. This may be a stretch, not just one night.")
            }
        }

        if reflections.isEmpty {
            reflections.append("This one stands apart from your recent dreams. New patterns sometimes start with a dream like this.")
        }

        return reflections.joined(separator: " ")
    }

    private func generateIslamicReflection(dream: Dream, extracted: ExtractedElements, context: ModelContext) -> String {
        var parts: [String] = []

        let peaceful = [DreamEmotion.peace, .wonder, .freedom].contains(extracted.inferredEmotion ?? dream.primaryEmotion)
        let uneasy = [DreamEmotion.fear, .shame, .grief, .avoidance].contains(extracted.inferredEmotion ?? dream.primaryEmotion)

        if peaceful {
            parts.append("Dreams that leave peace may fall among those worth sitting with quietly — perhaps a ru'ya (a good dream) that invites gratitude rather than over-analysis.")
        } else if uneasy {
            parts.append("Dreams that disturb are often treated as hulum — not to be dwelled upon or shared widely. The tradition encourages seeking refuge, a brief du'a, and turning toward what steadies the heart.")
        } else {
            parts.append("Mixed or fragmentary dreams may be adghath — impressions from the day's thoughts rather than symbolic messages. That doesn't make them meaningless, only gentler in weight.")
        }

        if extracted.themes.contains("water imagery") {
            parts.append("Scholars have long reflected on water as life, mercy, and the unseen — its appearance may invite you to notice what nourishes or overwhelms you inwardly.")
        }
        if !extracted.people.isEmpty {
            parts.append("Figures from your life in dreams can carry love, unfinished conversation, or concern for those you hold dear.")
        }
        if extracted.themes.contains("travel") || extracted.themes.contains("separation") {
            parts.append("Journeys and passages in dreams sometimes appear during seasons of istikhara, change, or trust in what lies ahead — tawakkul does not require certainty.")
        }

        let lifeDescriptor = FetchDescriptor<LifeEntry>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        if let entries = try? context.fetch(lifeDescriptor),
           let linked = entries.first(where: { $0.linkedDreamID == dream.id }),
           let tag = linked.tags.first {
            parts.append("You connected this dream to \"\(tag)\". That's probably where to look first.")
        }

        parts.append("Reflective guidance only — not a religious ruling. For significant or recurring dreams, consult someone knowledgeable.")

        return parts.joined(separator: " ")
    }

    private func updateSymbolMemory(extracted: ExtractedElements, dream: Dream, context: ModelContext) {
        let descriptor = FetchDescriptor<DreamSymbol>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let emotion = dream.primaryEmotion

        for symbolName in extracted.symbols {
            if let match = existing.first(where: { $0.name == symbolName.lowercased() }) {
                match.recordAppearance(emotion: emotion)
            } else {
                let symbol = DreamSymbol(name: symbolName)
                if let emotion { symbol.associatedEmotions = [emotion.rawValue] }
                context.insert(symbol)
            }
        }
    }

    private func updatePersonas(extracted: ExtractedElements, dream: Dream, context: ModelContext) {
        let descriptor = FetchDescriptor<DreamPersona>()
        let existing = (try? context.fetch(descriptor)) ?? []

        for person in extracted.people {
            let archetype = inferArchetype(for: person, dream: dream)
            if let match = existing.first(where: { $0.name.lowercased() == person.lowercased() }) {
                match.recordAppearance(dreamID: dream.id)
            } else {
                let persona = DreamPersona(name: person.capitalized, archetype: archetype)
                persona.recordAppearance(dreamID: dream.id)
                context.insert(persona)
            }
        }
    }

    private func inferArchetype(for person: String, dream: Dream) -> PersonaArchetype {
        switch person.lowercased() {
        case "stranger": return .stranger
        case "child", "baby": return .child
        case "mother", "mom", "father", "dad": return .guide
        default:
            if dream.rawTranscript.lowercased().contains("chase") || dream.rawTranscript.lowercased().contains("follow") {
                return .pursuer
            }
            return .watcher
        }
    }
}
