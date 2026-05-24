import Foundation

enum InterpretationLens: String, CaseIterable, Identifiable {
    case modernPsychology = "Modern Psychology"
    case islamicReflection = "Islamic Reflection"
    case both = "Both"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .modernPsychology: return "brain.head.profile"
        case .islamicReflection: return "moon.stars.fill"
        case .both: return "square.stack.3d.up"
        }
    }
}

enum InterpretationLayer: String, CaseIterable, Identifiable {
    case emotionalMirror = "Emotional Mirror"
    case modernPsychology = "Modern Psychology"
    case islamicReflection = "Islamic Reflection"
    case jungianSymbolic = "Jungian & Symbolic"
    case narrativeReflection = "Narrative Reflection"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .emotionalMirror: return "heart.text.square"
        case .modernPsychology: return "brain.head.profile"
        case .islamicReflection: return "moon.stars.fill"
        case .jungianSymbolic: return "sparkles"
        case .narrativeReflection: return "text.book.closed"
        }
    }

    static func visibleLayers(lens: InterpretationLens, showJungian: Bool) -> [InterpretationLayer] {
        var layers: [InterpretationLayer] = [.emotionalMirror]

        switch lens {
        case .modernPsychology:
            layers.append(.modernPsychology)
            if showJungian { layers.append(.jungianSymbolic) }
        case .islamicReflection:
            layers.append(.islamicReflection)
        case .both:
            layers.append(.modernPsychology)
            layers.append(.islamicReflection)
            if showJungian { layers.append(.jungianSymbolic) }
        }

        layers.append(.narrativeReflection)
        return layers
    }
}

enum AppSettings {
    static let interpretationLensKey = "interpretationLens"
    static let showJungianKey = "showJungianSymbolic"

    static var interpretationLens: InterpretationLens {
        get {
            guard let raw = UserDefaults.standard.string(forKey: interpretationLensKey),
                  let lens = InterpretationLens(rawValue: raw) else {
                return .modernPsychology
            }
            return lens
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: interpretationLensKey)
        }
    }

    static var showJungianSymbolic: Bool {
        get { UserDefaults.standard.object(forKey: showJungianKey) as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: showJungianKey) }
    }
}
