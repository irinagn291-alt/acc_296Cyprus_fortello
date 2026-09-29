import XCTest
@testable import Tetraptych

final class LineupRailTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        suiteName = "tpt.rail.\(UUID().uuidString)"
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        suiteName = nil
    }

    @MainActor
    func test_dealStartsCueRun_callScoresPunctuality() async throws {
        let rail = makeRail()
        let now = TetraptychGMT.instant(2026, 9, 18)
        for row in CrateShelf.bundled.rows.prefix(4) {
            await rail.stockLoose(row)
        }
        await rail.dealCue(now: now)
        XCTAssertEqual(rail.pinacotheca.status, .cued)
        XCTAssertEqual(rail.pinacotheca.lineup.card?.faces.count, 4)
        XCTAssertNotNil(rail.cueRun)
        let planned = try XCTUnwrap(rail.cueRun?.plannedFire())
        XCTAssertEqual(planned.timeIntervalSince(now), CueClock.goOffset, accuracy: 0.000_1)

        let match = try XCTUnwrap(rail.pinacotheca.lineup.card?.faces.first { $0.isTrue })
        await rail.tapFace(match, now: now.addingTimeInterval(CueClock.goOffset))
        XCTAssertEqual(rail.pinacotheca.status, .called)
        let score = try XCTUnwrap(rail.cueRun?.lastPunctuality)
        XCTAssertEqual(score, 1, accuracy: 0.000_1)
        XCTAssertEqual(rail.callPulse, 1)
    }

    @MainActor
    func test_missKeepsCueAndDoesNotPulseCall() async throws {
        let rail = makeRail()
        let now = TetraptychGMT.instant(2026, 9, 18)
        for row in CrateShelf.bundled.rows.prefix(4) {
            await rail.stockLoose(row)
        }
        await rail.dealCue(now: now)
        let decoy = try XCTUnwrap(rail.pinacotheca.lineup.card?.faces.first { !$0.isTrue })
        await rail.tapFace(decoy, now: now.addingTimeInterval(0.2))
        XCTAssertEqual(rail.pinacotheca.status, .fault)
        XCTAssertEqual(rail.pinacotheca.reviewableFaults.count, 1)
        XCTAssertEqual(rail.callPulse, 0)
        XCTAssertNil(rail.cueRun?.lastPunctuality)
        XCTAssertTrue(rail.pinacotheca.canCall)
        XCTAssertFalse(rail.dealEnabled)
    }

    func test_reviewHookMapsFourSheets() {
        XCTAssertEqual(ReviewHook.today.sheet, .quiz)
        XCTAssertEqual(ReviewHook.log.sheet, .saved)
        XCTAssertEqual(ReviewHook.goals.sheet, .settings)
        XCTAssertEqual(ReviewHook.explore.sheet, .explore)
        XCTAssertEqual(LineupCover.cueCall.rawValue, "cueCall")
    }

    @MainActor
    private func makeRail() -> LineupRail {
        let store = LineupStore(
            directory: directory,
            suiteName: suiteName,
            writeDelayNanoseconds: 0,
            seekDebounceNanoseconds: 0
        )
        return LineupRail(store: store, isBooting: false)
    }
}
