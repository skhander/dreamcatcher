import Foundation
import SwiftData

@Model
final class DreamSymbol {
    var id: UUID
    var name: String
    var appearanceCount: Int
    var personalMeaning: String?
    var lastSeenAt: Date
    var associatedEmotions: [String]
    var contextNotes: String?

    init(name: String) {
        self.id = UUID()
        self.name = name.lowercased()
        self.appearanceCount = 1
        self.lastSeenAt = Date()
        self.associatedEmotions = []
    }

    func recordAppearance(emotion: DreamEmotion?) {
        appearanceCount += 1
        lastSeenAt = Date()
        if let emotion, !associatedEmotions.contains(emotion.rawValue) {
            associatedEmotions.append(emotion.rawValue)
        }
    }
}
