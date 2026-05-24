import Foundation

struct LifePrompt: Equatable {
    let mirrorLine: String
    let question: String
    let chips: [String]
}

enum LifePromptEngine {
    static func prompt(for dream: Dream, lens: InterpretationLens = AppSettings.interpretationLens) -> LifePrompt {
        if lens == .islamicReflection || lens == .both {
            if let islamic = islamicPrompt(for: dream) { return islamic }
        }
        return psychologyPrompt(for: dream)
    }

    private static func psychologyPrompt(for dream: Dream) -> LifePrompt {
        let emotion = dream.primaryEmotion
        let symbols = dream.symbols
        let hasWater = symbols.contains(where: { ["water", "ocean", "rain", "beach"].contains($0) })
        let hasTravel = symbols.contains(where: { ["airport", "train", "flight", "station", "road"].contains($0) })

        if hasWater {
            return LifePrompt(
                mirrorLine: mirrorLine(for: dream, fallback: "Water showed up in this dream"),
                question: "Does water connect to anything emotional in your life right now?",
                chips: ["Yes, a bit", "Not really", "Family", "Faith", "Skip"]
            )
        }

        if hasTravel || emotion == .transition {
            return LifePrompt(
                mirrorLine: mirrorLine(for: dream, fallback: "There was a lot of movement in this dream"),
                question: "Is something changing in your life?",
                chips: ["Career", "Move", "Relationship", "Faith", "Skip"]
            )
        }

        switch emotion {
        case .fear, .shame, .avoidance:
            return LifePrompt(
                mirrorLine: mirrorLine(for: dream, fallback: "Something in this dream felt uneasy"),
                question: "What's been stressing you out lately?",
                chips: ["Work", "Family", "Health", "Money", "Skip"]
            )
        case .longing, .grief:
            return LifePrompt(
                mirrorLine: mirrorLine(for: dream, fallback: "There was a sense of loss or reaching in this dream"),
                question: "Has someone or something been on your mind?",
                chips: ["A person", "A place", "The past", "Faith", "Skip"]
            )
        case .desire:
            return LifePrompt(
                mirrorLine: mirrorLine(for: dream, fallback: "This dream had a pull toward something"),
                question: "What do you find yourself wanting lately?",
                chips: ["Connection", "Change", "Rest", "Clarity", "Skip"]
            )
        case .peace, .wonder, .freedom:
            return LifePrompt(
                mirrorLine: mirrorLine(for: dream, fallback: "It left some stillness or wonder after waking"),
                question: "What's been bringing you peace lately?",
                chips: ["Faith", "People", "Nature", "Work", "Skip"]
            )
        default:
            return LifePrompt(
                mirrorLine: mirrorLine(for: dream, fallback: "This one left an impression"),
                question: "Does anything in your life feel connected to this?",
                chips: ["Work", "Family", "Health", "Faith", "Skip"]
            )
        }
    }

    private static func islamicPrompt(for dream: Dream) -> LifePrompt? {
        let uneasy = [DreamEmotion.fear, .shame, .grief, .avoidance].contains(dream.primaryEmotion)
        let peaceful = [DreamEmotion.peace, .wonder, .freedom].contains(dream.primaryEmotion)

        if uneasy {
            return LifePrompt(
                mirrorLine: "This one left some unease — worth noticing",
                question: "Was anything heavy on your heart before sleep?",
                chips: ["Dunya worries", "Family", "Seeking clarity", "Health", "Skip"]
            )
        }

        if peaceful {
            return LifePrompt(
                mirrorLine: "This dream had a gentle feel",
                question: "Has anything been a source of hope or gratitude lately?",
                chips: ["Family", "Faith", "Work", "Health", "Skip"]
            )
        }

        return LifePrompt(
            mirrorLine: mirrorLine(for: dream, fallback: "Some dreams mean something. Some are leftover from the day."),
            question: "Did anything weigh on you before sleep?",
            chips: ["Dunya worries", "Family", "Faith", "Not much", "Skip"]
        )
    }

    private static func mirrorLine(for dream: Dream, fallback: String) -> String {
        if let mirror = dream.emotionalMirror {
            let firstSentence = mirror.split(separator: ".").first.map(String.init) ?? mirror
            if firstSentence.count < 120 { return firstSentence }
        }
        if let emotion = dream.primaryEmotion {
            return "This dream felt \(emotion.displayName.lowercased())"
        }
        return fallback
    }
}
