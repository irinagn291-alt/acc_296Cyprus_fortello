import Foundation

/// Role: FaultMark. A miss on a decoy Face. The Cue stays. Reviewable on Saved.
struct FaultMark: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var workID: UUID
    var faceID: UUID
    var daykey: Int
    var cue: Cue
}
