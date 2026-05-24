import Foundation

enum DreamEmotion: String, Codable, CaseIterable, Identifiable {
    case longing, grief, freedom, transition, avoidance
    case desire, shame, wonder, peace, fear

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var prompt: String {
        switch self {
        case .longing: return "a sense of reaching for something distant"
        case .grief: return "weight or loss carried quietly"
        case .freedom: return "openness, release, or flight"
        case .transition: return "thresholds and in-between spaces"
        case .avoidance: return "something kept at a distance"
        case .desire: return "pull toward what you want"
        case .shame: return "exposure or hiding"
        case .wonder: return "curiosity and the unknown"
        case .peace: return "stillness that stayed with you"
        case .fear: return "unease that lingered after waking"
        }
    }
}

enum FragmentKind: String, Codable, CaseIterable {
    case word, emotion, color, sensation, person, place, image
}

enum PersonaArchetype: String, Codable, CaseIterable {
    case guide = "The Guide"
    case pursuer = "The Pursuer"
    case child = "The Child"
    case stranger = "The Stranger"
    case watcher = "The Watcher"
    case protector = "The Protector"

    var description: String {
        switch self {
        case .guide: return "Offers direction or wisdom in unfamiliar terrain"
        case .pursuer: return "Chases, follows, or creates urgency"
        case .child: return "Vulnerable, playful, or from an earlier self"
        case .stranger: return "Unknown presence with unclear intent"
        case .watcher: return "Observes without intervening"
        case .protector: return "Shields or guards against threat"
        }
    }
}
