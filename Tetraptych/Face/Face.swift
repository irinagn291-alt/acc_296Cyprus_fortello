import Foundation

/// Role: Face. QuizCard leaf. One hanging canvas in the four-face lineup.
struct Face: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var workID: UUID
    var isTrue: Bool
    var isDimmed: Bool
    var isStruck: Bool

    static func live(id: UUID = UUID(), workID: UUID, isTrue: Bool) -> Face {
        Face(
            id: id,
            workID: workID,
            isTrue: isTrue,
            isDimmed: false,
            isStruck: false
        )
    }
}
