import Foundation

/// Role: Lineup. Jobs for App Intents and tetraptych:// plus https://tetraptych-lineup.pro paths. Quiz stays put. No Game tab.
enum LineupJob: String, Equatable, Sendable {
    case quiz
    case explore
    case saved
    case settings
    case deal
    case cue

    static let httpsHost = "tetraptych-lineup.pro"

    static func parse(_ url: URL) -> LineupJob? {
        let scheme = url.scheme?.lowercased() ?? ""
        if scheme == "tetraptych" {
            let host = url.host?.lowercased() ?? ""
            let path = url.path.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let token = host.isEmpty ? path : host
            return LineupJob(rawValue: token)
        }
        if scheme == "https", url.host?.lowercased() == httpsHost {
            let path = url.path.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if path.isEmpty { return .quiz }
            return LineupJob(rawValue: path)
        }
        return nil
    }

    static func parse(notification: Notification) -> LineupJob? {
        guard let raw = notification.userInfo?[LineupPost.key] as? String else { return nil }
        return LineupJob(rawValue: raw)
    }

    var cover: LineupCover? {
        switch self {
        case .quiz, .deal: nil
        case .explore: .explore
        case .saved: .saved
        case .settings: .settings
        case .cue: .cueCall
        }
    }
}

/// Role: Lineup. Sheets over the locked Quiz lineup. Four destinations plus the cue-then-call twist screen.
enum LineupCover: String, Identifiable, Equatable, Sendable {
    case explore
    case saved
    case settings
    case cueCall

    var id: String { rawValue }
}

extension Notification.Name {
    static let lineupJob = Notification.Name("tpt.lineup.job")
}

enum LineupPost {
    static let key = "job"

    static func broadcast(_ job: LineupJob) {
        NotificationCenter.default.post(
            name: .lineupJob,
            object: nil,
            userInfo: [key: job.rawValue]
        )
    }
}
