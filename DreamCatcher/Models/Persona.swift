import Foundation
import SwiftData

@Model
final class DreamPersona {
    var id: UUID
    var name: String
    var archetype: String
    var appearanceCount: Int
    var firstSeenAt: Date
    var lastSeenAt: Date
    var notes: String?
    var associatedDreamIDs: [UUID]

    init(name: String, archetype: PersonaArchetype) {
        self.id = UUID()
        self.name = name
        self.archetype = archetype.rawValue
        self.appearanceCount = 1
        self.firstSeenAt = Date()
        self.lastSeenAt = Date()
        self.associatedDreamIDs = []
    }

    var personaArchetype: PersonaArchetype {
        PersonaArchetype(rawValue: archetype) ?? .stranger
    }

    func recordAppearance(dreamID: UUID) {
        appearanceCount += 1
        lastSeenAt = Date()
        if !associatedDreamIDs.contains(dreamID) {
            associatedDreamIDs.append(dreamID)
        }
    }
}
