import XCTest
@testable import Tetraptych

final class LineupRouteTests: XCTestCase {
    func test_tetraptychSchemeOpensFourDestinations() {
        XCTAssertEqual(LineupJob.parse(URL(string: "tetraptych://quiz")!), .quiz)
        XCTAssertEqual(LineupJob.parse(URL(string: "tetraptych://explore")!), .explore)
        XCTAssertEqual(LineupJob.parse(URL(string: "tetraptych://saved")!), .saved)
        XCTAssertEqual(LineupJob.parse(URL(string: "tetraptych://settings")!), .settings)
        XCTAssertEqual(LineupJob.parse(URL(string: "tetraptych://deal")!), .deal)
        XCTAssertEqual(LineupJob.parse(URL(string: "tetraptych://cue")!), .cue)
        XCTAssertNil(LineupJob.parse(URL(string: "tetraptych://game")!))
        XCTAssertNil(LineupJob.quiz.cover)
        XCTAssertNil(LineupJob.deal.cover)
        XCTAssertEqual(LineupJob.explore.cover, .explore)
        XCTAssertEqual(LineupJob.saved.cover, .saved)
        XCTAssertEqual(LineupJob.settings.cover, .settings)
        XCTAssertEqual(LineupJob.cue.cover, .cueCall)
        XCTAssertEqual(Set(LineupSheet.allCases.map(\.rawValue)).count, 4)
    }

    func test_httpsHostMapsTheSameJobs() {
        XCTAssertEqual(LineupJob.parse(URL(string: "https://tetraptych-lineup.pro/quiz")!), .quiz)
        XCTAssertEqual(LineupJob.parse(URL(string: "https://tetraptych-lineup.pro/explore")!), .explore)
        XCTAssertEqual(LineupJob.parse(URL(string: "https://tetraptych-lineup.pro/saved")!), .saved)
        XCTAssertEqual(LineupJob.parse(URL(string: "https://tetraptych-lineup.pro/settings")!), .settings)
        XCTAssertEqual(LineupJob.parse(URL(string: "https://tetraptych-lineup.pro")!), .quiz)
        XCTAssertNil(LineupJob.parse(URL(string: "https://example.com/quiz")!))
        XCTAssertNil(LineupJob.parse(URL(string: "https://tetraptych-lineup.pro/contact-us")!))
    }

    func test_notificationParsesJobOnce() {
        let notice = Notification(
            name: .lineupJob,
            object: nil,
            userInfo: [LineupPost.key: LineupJob.saved.rawValue]
        )
        XCTAssertEqual(LineupJob.parse(notification: notice), .saved)
        XCTAssertNil(LineupJob.parse(notification: Notification(name: .lineupJob)))
    }

    func test_figuresGoThroughNumberFormatter() {
        XCTAssertFalse(LineupFigures.whole(2).isEmpty)
        XCTAssertFalse(LineupFigures.daykey(20260918).isEmpty)
        XCTAssertFalse(LineupFigures.seconds(0.9).isEmpty)
        XCTAssertFalse(LineupFigures.score(1).isEmpty)
        XCTAssertEqual(LineupStatusInk.stamp(.idle), "IDLE")
        XCTAssertEqual(LineupStatusInk.stamp(.cued), "CUED")
        XCTAssertEqual(LineupStatusInk.stamp(.called), "CALLED")
        XCTAssertEqual(LineupStatusInk.stamp(.fault), "FAULT")
        XCTAssertEqual(LineupCueInk.stamp(.artist), "ARTIST")
        XCTAssertEqual(LineupCueInk.stamp(.title), "TITLE")
        XCTAssertEqual(LineupCopy.nextTap(.cued), "Tap the matching canvas.")
        XCTAssertEqual(LineupCopy.nextTap(.idle), "Save four works, then deal.")
        XCTAssertEqual(LineupCopy.nextTap(.fault), "Miss stays. Tap the true canvas.")
        XCTAssertEqual(LineupCopy.calledFile, "Called")
        XCTAssertEqual(LineupCopy.missFile, "Misses")
        XCTAssertFalse(LineupCopy.missFile.contains("FAULT"))
        let cue = Cue.artist(workID: UUID(), line: "Gustave Moreau")
        XCTAssertEqual(
            LineupCopy.missSpeak(title: "Oedipus and the Sphinx", cue: cue, day: "Sep 12, 2026"),
            "Oedipus and the Sphinx. ARTIST Gustave Moreau. Sep 12, 2026."
        )
        XCTAssertFalse(LineupCopy.missSpeak(title: "Boating", cue: cue, day: "Sep 11, 2026").contains("FAULT"))
        XCTAssertEqual(
            LineupCopy.canvasSpeak(title: "Wheat Field with Cypresses", artist: "Vincent van Gogh", hiding: .title),
            "Vincent van Gogh"
        )
        XCTAssertEqual(
            LineupCopy.canvasSpeak(title: "Wheat Field with Cypresses", artist: "Vincent van Gogh", hiding: .artist),
            "Wheat Field with Cypresses"
        )
        XCTAssertFalse(LineupCopy.canvasSpeak(title: "Boating", artist: "Edouard Manet", hiding: .title).contains("Boating"))
        XCTAssertEqual(LineupCopy.fault(LineupFault.alreadyCued), "The line stays. Call the matching canvas.")
        XCTAssertEqual(LineupRadius.card, 12)
        XCTAssertEqual(LineupRadius.chip, 8)
        XCTAssertEqual(LineupSpace.unit, 4)
        XCTAssertEqual(LineupSpace.hit, 44)
    }
}
