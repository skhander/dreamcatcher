import Foundation
import SwiftData

@Model
final class DreamFragment {
    var id: UUID
    var content: String
    var kind: String
    var createdAt: Date
    var dream: Dream?

    init(content: String, kind: FragmentKind = .word) {
        self.id = UUID()
        self.content = content
        self.kind = kind.rawValue
        self.createdAt = Date()
    }

    var fragmentKind: FragmentKind {
        FragmentKind(rawValue: kind) ?? .word
    }
}
