import AppIntents
import Foundation

/// Role: Lineup. App Intents open Quiz, Explore, Saved, or Settings, or fire dealCue in place.
struct OpenQuizIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Quiz" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        LineupPost.broadcast(.quiz)
        return .result()
    }
}

struct OpenExploreIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Explore" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        LineupPost.broadcast(.explore)
        return .result()
    }
}

struct OpenSavedIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Saved" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        LineupPost.broadcast(.saved)
        return .result()
    }
}

struct OpenSettingsIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Settings" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        LineupPost.broadcast(.settings)
        return .result()
    }
}

struct DealCueIntent: AppIntent {
    static var title: LocalizedStringResource { "Deal a line" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        LineupPost.broadcast(.deal)
        return .result()
    }
}

struct OpenCueCallIntent: AppIntent {
    static var title: LocalizedStringResource { "How to call" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        LineupPost.broadcast(.cue)
        return .result()
    }
}

struct TetraptychShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenQuizIntent(),
            phrases: [
                "Open Quiz in \(.applicationName)",
                "Call the lineup in \(.applicationName)",
            ],
            shortTitle: "Quiz",
            systemImageName: "square.grid.2x2"
        )
        AppShortcut(
            intent: OpenExploreIntent(),
            phrases: [
                "Open Explore in \(.applicationName)",
            ],
            shortTitle: "Explore",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: OpenSavedIntent(),
            phrases: [
                "Open Saved in \(.applicationName)",
            ],
            shortTitle: "Saved",
            systemImageName: "bookmark"
        )
        AppShortcut(
            intent: OpenSettingsIntent(),
            phrases: [
                "Open Settings in \(.applicationName)",
            ],
            shortTitle: "Settings",
            systemImageName: "gearshape"
        )
        AppShortcut(
            intent: DealCueIntent(),
            phrases: [
                "Deal a line in \(.applicationName)",
            ],
            shortTitle: "Deal",
            systemImageName: "plus.square.on.square"
        )
        AppShortcut(
            intent: OpenCueCallIntent(),
            phrases: [
                "How to call in \(.applicationName)",
            ],
            shortTitle: "Call",
            systemImageName: "text.alignleft"
        )
    }
}
