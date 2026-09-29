import Foundation

/// Role: Lineup. Closed algebraic fold Idle | Cued | Called. A fourth case is a defect.
enum Lineup: Equatable, Sendable {
    case idle
    case cued(LineupCard)
    case called(LineupCard, callMarkID: UUID)

    var card: LineupCard? {
        switch self {
        case .idle:
            return nil
        case .cued(let card), .called(let card, _):
            return card
        }
    }

    var trueWorkID: UUID? {
        card?.cue.workID
    }

    var status: LineupStatus {
        switch self {
        case .idle:
            return .idle
        case .cued(let card):
            return card.hasFault ? .fault : .cued
        case .called:
            return .called
        }
    }
}

extension Lineup: Codable {
    enum Kind: String, Codable, Sendable {
        case idle
        case cued
        case called
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case card
        case callMarkID
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .idle:
            try container.encode(Kind.idle, forKey: .kind)
        case .cued(let card):
            try container.encode(Kind.cued, forKey: .kind)
            try container.encode(card, forKey: .card)
        case .called(let card, let callMarkID):
            try container.encode(Kind.called, forKey: .kind)
            try container.encode(card, forKey: .card)
            try container.encode(callMarkID, forKey: .callMarkID)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .idle:
            self = .idle
        case .cued:
            self = .cued(try container.decode(LineupCard.self, forKey: .card))
        case .called:
            let card = try container.decode(LineupCard.self, forKey: .card)
            let callMarkID = try container.decode(UUID.self, forKey: .callMarkID)
            self = .called(card, callMarkID: callMarkID)
        }
    }
}

/// Role: Lineup. QuizCard. One Cue plus four Faces, one true and three Loose decoys.
struct LineupCard: Equatable, Sendable, Codable {
    var cue: Cue
    var faces: [Face]

    var hasFault: Bool {
        faces.contains(where: \.isDimmed)
    }

    var trueFace: Face? {
        faces.first(where: \.isTrue)
    }
}

/// Role: Lineup. Dock status. FAULT is a Cued overlay, not a fourth fold case.
enum LineupStatus: String, Sendable, Equatable {
    case idle
    case cued
    case called
    case fault
}

/// Role: Lineup. Typed refusals of Deal, Call, miss, and Undo. Views map these.
enum LineupFault: Error, Equatable, Sendable {
    case alreadyCued
    case notCued
    case alreadyCalled
    case unknownFace
    case faceIsDecoy
    case missOnTrue
    case faceSpent
    case nothingToPeel
    case emptyObject
}

/// Role: Lineup. Ordered peel stack. Undo pops the newest CallMark or FaultMark.
enum PeelKind: String, Codable, Sendable {
    case call
    case fault
}

struct PeelRef: Equatable, Sendable, Codable {
    var kind: PeelKind
    var markID: UUID
}

/// Role: Lineup. Explore save outcome. Duplicate object id focuses and does not reset the file case.
enum StockFocus: Equatable, Sendable {
    case inserted(UUID)
    case focused(UUID)
}

/// Role: Lineup. Recoverable load outcome. Never crash on a corrupt snapshot.
enum CrateWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

/// Role: Lineup. Pins Cue kind and Face order. Tests pin the true Face first.
protocol LineupCasting: Sendable {
    func cueKind(salt: Int) -> CueKind
    func arrange(_ faces: [Face], salt: Int) -> [Face]
}

struct LeadingTrueCast: LineupCasting {
    var kind: CueKind = .artist

    func cueKind(salt: Int) -> CueKind {
        _ = salt
        return kind
    }

    func arrange(_ faces: [Face], salt: Int) -> [Face] {
        _ = salt
        return faces.sorted { lhs, rhs in
            if lhs.isTrue != rhs.isTrue {
                return lhs.isTrue && !rhs.isTrue
            }
            return lhs.workID.uuidString < rhs.workID.uuidString
        }
    }
}

struct RotateCast: LineupCasting {
    func cueKind(salt: Int) -> CueKind {
        (salt & 1) == 0 ? .artist : .title
    }

    func arrange(_ faces: [Face], salt: Int) -> [Face] {
        guard faces.count > 1 else { return faces }
        var shift = abs(salt) % faces.count
        if shift == 0 {
            shift = 1
        }
        return Array(faces[shift...]) + Array(faces[..<shift])
    }
}

/// Role: Lineup. Hangs four Faces. One true Loose Work, three Loose decoys from the crate.
enum FaceBench {
    static func card(
        trueWork: Work,
        loose: [Work],
        caster: any LineupCasting,
        faceIDs: [UUID]? = nil
    ) -> LineupCard {
        let decoys = loose
            .filter { $0.id != trueWork.id }
            .sorted { lhs, rhs in
                if lhs.daykey != rhs.daykey { return lhs.daykey < rhs.daykey }
                return lhs.objectID < rhs.objectID
            }
            .prefix(3)
        let salt = saltValue(trueWork.id)
        let cue: Cue
        switch caster.cueKind(salt: salt) {
        case .artist:
            cue = .artist(workID: trueWork.id, line: trueWork.artist)
        case .title:
            cue = .title(workID: trueWork.id, line: trueWork.title)
        }
        var faces = [Face.live(workID: trueWork.id, isTrue: true)]
        faces.append(contentsOf: decoys.map { Face.live(workID: $0.id, isTrue: false) })
        if let faceIDs, faceIDs.count >= faces.count {
            for index in faces.indices {
                faces[index].id = faceIDs[index]
            }
        }
        faces = caster.arrange(faces, salt: salt)
        return LineupCard(cue: cue, faces: faces)
    }

    private static func saltValue(_ id: UUID) -> Int {
        var hasher = Hasher()
        hasher.combine(id)
        return hasher.finalize()
    }
}
