import Foundation
import SwiftData

@MainActor
enum DreamDeletionService {
    static func delete(_ dream: Dream, context: ModelContext, lifeEntries: [LifeEntry]) {
        let dreamID = dream.id
        for entry in lifeEntries where entry.linkedDreamID == dreamID {
            context.delete(entry)
        }
        context.delete(dream)
        try? context.save()
    }
}
