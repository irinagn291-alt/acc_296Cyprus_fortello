import Foundation

/// Role: Cue. One written line for the hanging lineup. Artist or Title, never both.
enum CueKind: String, Codable, Sendable, Equatable {
    case artist
    case title
}

/// Role: Cue. Deal writes this as Artist or as Title. The learner calls the matching Face.
enum Cue: Equatable, Sendable {
    case artist(workID: UUID, line: String)
    case title(workID: UUID, line: String)

    var workID: UUID {
        switch self {
        case .artist(let workID, _), .title(let workID, _):
            return workID
        }
    }

    var line: String {
        switch self {
        case .artist(_, let line), .title(_, let line):
            return line
        }
    }

    var kind: CueKind {
        switch self {
        case .artist:
            return .artist
        case .title:
            return .title
        }
    }
}

extension Cue: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case workID
        case line
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        try container.encode(workID, forKey: .workID)
        try container.encode(line, forKey: .line)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(CueKind.self, forKey: .kind)
        let workID = try container.decode(UUID.self, forKey: .workID)
        let line = try container.decode(String.self, forKey: .line)
        switch kind {
        case .artist:
            self = .artist(workID: workID, line: line)
        case .title:
            self = .title(workID: workID, line: line)
        }
    }
}
