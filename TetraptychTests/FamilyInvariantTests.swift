import XCTest
@testable import Tetraptych

/// Family invariant: Quiz draws from saved works. Misses are reviewable. Collecting without a test is the crate clone.
final class FamilyInvariantTests: XCTestCase {
    private var calendar: Calendar { TetraptychGMT.calendar }
    private var now: Date { TetraptychGMT.instant(2026, 9, 18) }
    private var caster: LeadingTrueCast { LeadingTrueCast(kind: .artist) }
    private var shelf: [CatalogRow] { CrateShelf.bundled.rows }

    func test_quizDrawsFromSavedWorks_missesStayReviewable_stockingIsNotFiling() throws {
        var crate = Pinacotheca.empty
        XCTAssertFalse(crate.canDeal)
        XCTAssertFalse(crate.canCall)
        XCTAssertEqual(crate.status, .idle)

        for row in shelf.prefix(4) {
            _ = try crate.stockLoose(row, now: now, calendar: calendar)
        }
        XCTAssertEqual(crate.works.count, 4)
        XCTAssertEqual(crate.calledWorks.count, 0)
        XCTAssertEqual(crate.loosePool.count, 4)
        XCTAssertEqual(crate.lineup, .idle)

        try crate.dealCue(now: now, calendar: calendar, caster: caster)
        let hangingID = try XCTUnwrap(crate.lineup.trueWorkID)
        XCTAssertTrue(crate.loosePool.contains { $0.id == hangingID })
        XCTAssertEqual(crate.lineup.card?.faces.count, 4)
        XCTAssertEqual(crate.lineup.card?.faces.filter(\.isTrue).count, 1)
        XCTAssertTrue(crate.canCall)
        let hungIDs = Set(crate.lineup.card?.faces.map(\.workID) ?? [])
        let savedIDs = Set(crate.works.map(\.id))
        XCTAssertTrue(hungIDs.isSubset(of: savedIDs))

        let decoy = try XCTUnwrap(crate.lineup.card?.faces.first { !$0.isTrue })
        try crate.missFace(faceID: decoy.id, now: now, calendar: calendar)
        XCTAssertEqual(crate.lineup.trueWorkID, hangingID)
        XCTAssertEqual(crate.hangingTrue?.file, .loose)
        XCTAssertEqual(crate.reviewableFaults.count, 1)
        XCTAssertEqual(crate.reviewableFaults.first?.workID, hangingID)
        XCTAssertEqual(crate.reviewableFaults.first?.cue, crate.lineup.card?.cue)
        XCTAssertEqual(crate.status, .fault)
        XCTAssertEqual(crate.calledWorks.count, 0)
        XCTAssertTrue(crate.loosePool.contains { $0.id == hangingID })
    }

    func test_calledWorksLeaveTheDealPool() throws {
        var crate = try stockedAndDealt(count: 5)
        let firstTrue = try XCTUnwrap(crate.lineup.trueWorkID)
        let match = try XCTUnwrap(crate.lineup.card?.faces.first { $0.isTrue })
        _ = try crate.callFace(faceID: match.id, now: now, calendar: calendar)
        XCTAssertEqual(crate.hangingTrue?.file, .called)
        XCTAssertEqual(crate.calledWorks.count, 1)
        XCTAssertFalse(crate.loosePool.contains { $0.id == firstTrue })
        XCTAssertEqual(crate.status, .called)

        try crate.dealCue(now: now, calendar: calendar, caster: caster)
        let hung = Set(crate.lineup.card?.faces.map(\.workID) ?? [])
        XCTAssertFalse(hung.contains(firstTrue))
        XCTAssertNotEqual(crate.lineup.trueWorkID, firstTrue)
        XCTAssertEqual(crate.lineup.card?.faces.count, 4)
        XCTAssertEqual(crate.status, .cued)
    }

    private func stockedAndDealt(count: Int) throws -> Pinacotheca {
        var crate = Pinacotheca.empty
        for row in shelf.prefix(count) {
            _ = try crate.stockLoose(row, now: now, calendar: calendar)
        }
        try crate.dealCue(now: now, calendar: calendar, caster: caster)
        return crate
    }
}
