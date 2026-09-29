import Foundation

/// Role: CallMark. A matching Call files the true Face. The Work leaves the deal pool as Called.
struct CallMark: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var workID: UUID
    var card: LineupCard
    var daykey: Int

    var cueKind: CueKind { card.cue.kind }
    var line: String { card.cue.line }
}
