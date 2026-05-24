import Foundation
import SwiftData

@Model
final class Dream {
    var id: UUID
    var createdAt: Date
    var rawTranscript: String
    var reconstructedNarrative: String?
    var dominantEmotion: String?
    var emotions: [String]
    var colors: [String]
    var symbols: [String]
    var locations: [String]
    var people: [String]
    var isReconstructed: Bool

    var emotionalMirror: String?
    var modernPsychology: String?
    var jungianSymbolic: String?
    var narrativeReflection: String?
    var islamicReflection: String?
    var userReflection: String?

    var moodToday: Int?
    var stressLevel: Int?
    var sleepQuality: Int?
    var lifeEventNote: String?

    @Relationship(deleteRule: .cascade, inverse: \DreamFragment.dream)
    var fragments: [DreamFragment]

    init(rawTranscript: String = "") {
        self.id = UUID()
        self.createdAt = Date()
        self.rawTranscript = rawTranscript
        self.emotions = []
        self.colors = []
        self.symbols = []
        self.locations = []
        self.people = []
        self.isReconstructed = false
        self.fragments = []
    }

    var primaryEmotion: DreamEmotion? {
        guard let dominantEmotion else { return nil }
        return DreamEmotion(rawValue: dominantEmotion)
    }

    var displayTitle: String {
        if let narrative = reconstructedNarrative {
            let words = narrative.split(separator: " ").prefix(6)
            return words.joined(separator: " ") + (words.count >= 6 ? "…" : "")
        }
        if !rawTranscript.isEmpty {
            let words = rawTranscript.split(separator: " ").prefix(5)
            return words.joined(separator: " ") + "…"
        }
        return "Untitled dream"
    }
}
