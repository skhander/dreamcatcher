import SwiftUI
import SwiftData

struct SampleDataSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Dream>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let samples: [(transcript: String, emotions: [DreamEmotion], colors: [String])] = [
            ("airport… missed flight… mom younger… red birds", [.transition, .longing], ["Red", "Blue"]),
            ("old house… purple ocean… childhood dog running", [.wonder, .peace], ["Purple", "Blue"]),
            ("elevator going up… couldn't find the floor… stranger watching", [.fear, .transition], ["Silver", "Black"]),
            ("train station at night… waiting… felt lonely but peaceful", [.peace, .longing], ["Blue", "Gold"]),
            ("forest path… mirror on a tree… my reflection was different", [.wonder, .desire], ["Green", "Silver"])
        ]

        for sample in samples {
            let daysAgo = Double.random(in: 1...45)
            let dream = Dream(rawTranscript: sample.transcript)
            dream.createdAt = Calendar.current.date(byAdding: .day, value: -Int(daysAgo), to: Date()) ?? Date()
            dream.emotions = sample.emotions.map(\.rawValue)
            dream.dominantEmotion = sample.emotions.first?.rawValue
            dream.colors = sample.colors
            context.insert(dream)
        }

        try? context.save()

        Task { @MainActor in
            let dreams = (try? context.fetch(descriptor)) ?? []
            for dream in dreams {
                await DreamReconstructionService.shared.processDream(dream, context: context)
            }
        }
    }
}
