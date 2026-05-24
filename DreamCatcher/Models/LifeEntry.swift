import Foundation
import SwiftData

@Model
final class LifeEntry {
    var id: UUID
    var createdAt: Date
    var content: String
    var tags: [String]
    var linkedDreamID: UUID?
    var promptQuestion: String?

    init(content: String = "", tags: [String] = [], linkedDreamID: UUID? = nil, promptQuestion: String? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.content = content
        self.tags = tags
        self.linkedDreamID = linkedDreamID
        self.promptQuestion = promptQuestion
    }

    var displaySummary: String {
        if !content.isEmpty { return content }
        if let tag = tags.first { return tag }
        return "Life note"
    }
}
