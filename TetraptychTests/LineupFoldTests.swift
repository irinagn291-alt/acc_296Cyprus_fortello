import XCTest
@testable import Tetraptych

final class LineupFoldTests: XCTestCase {
    private var calendar: Calendar { TetraptychGMT.calendar }
    private var now: Date { TetraptychGMT.instant(2026, 9, 18) }
    private var caster: LeadingTrueCast { LeadingTrueCast(kind: .artist) }
    private var shelf: [CatalogRow] { CrateShelf.bundled.rows }

    func test_architecture_notCalledSampling_fourFaceHang_dealWhileCuedRefuse_underFourIdle_callFile_missKeep_undoFoldBack_duplicateFocus() throws {
        var crate = Pinacotheca.empty
        XCTAssertEqual(foldLabel(crate.lineup), "idle")

        for row in shelf.prefix(3) {
            _ = try crate.stockLoose(row, now: now, calendar: calendar)
        }
        try crate.dealCue(now: now, calendar: calendar, caster: caster)
        XCTAssertEqual(crate.lineup, .idle)
        XCTAssertEqual(crate.status, .idle)

        _ = try crate.stockLoose(shelf[3], now: now, calendar: calendar)
        _ = try crate.stockLoose(shelf[4], now: now, calendar: calendar)
        try crate.dealCue(now: now, calendar: calendar, caster: caster)
        XCTAssertEqual(foldLabel(crate.lineup), "cued")
        XCTAssertEqual(crate.lineup.card?.faces.count, 4)
        XCTAssertEqual(crate.lineup.card?.faces.filter(\.isTrue).count, 1)
        XCTAssertEqual(crate.lineup.card?.faces.filter { !$0.isTrue }.count, 3)
        switch crate.lineup.card?.cue {
        case .artist(let workID, let line):
            XCTAssertEqual(workID, crate.lineup.trueWorkID)
            XCTAssertEqual(line, crate.hangingTrue?.artist)
        case .title:
            XCTFail("pinned artist cue")
        case .none:
            XCTFail("missing cue")
        }

        XCTAssertThrowsError(try crate.dealCue(now: now, calendar: calendar, caster: caster)) { error in
            XCTAssertEqual(error as? LineupFault, .alreadyCued)
        }
        XCTAssertEqual(foldLabel(crate.lineup), "cued")

        let hangingID = try XCTUnwrap(crate.lineup.trueWorkID)
        let decoy = try XCTUnwrap(crate.lineup.card?.faces.first { !$0.isTrue })
        try crate.missFace(faceID: decoy.id, now: now, calendar: calendar)
        XCTAssertEqual(crate.lineup.trueWorkID, hangingID)
        XCTAssertEqual(foldLabel(crate.lineup), "cued")
        XCTAssertEqual(crate.status, .fault)
        XCTAssertEqual(crate.reviewableFaults.first?.cue, crate.lineup.card?.cue)
        XCTAssertEqual(crate.reviewableFaults.first?.cue.line, crate.hangingTrue?.artist)
        XCTAssertTrue(crate.lineup.card?.faces.contains { $0.id == decoy.id && $0.isDimmed && $0.isStruck } ?? false)
        XCTAssertEqual(crate.hangingTrue?.file, .loose)

        let match = try XCTUnwrap(crate.lineup.card?.faces.first { $0.isTrue })
        _ = try crate.callFace(faceID: match.id, now: now, calendar: calendar)
        XCTAssertEqual(foldLabel(crate.lineup), "called")
        XCTAssertEqual(crate.hangingTrue?.file, .called)
        XCTAssertEqual(crate.callMarks.count, 1)
        XCTAssertFalse(crate.loosePool.contains { $0.id == hangingID })

        try crate.dealCue(now: now, calendar: calendar, caster: caster)
        XCTAssertEqual(foldLabel(crate.lineup), "cued")
        XCTAssertFalse((crate.lineup.card?.faces.map(\.workID) ?? []).contains(hangingID))

        let again = try crate.stockLoose(shelf[0], now: now, calendar: calendar)
        guard case .focused(let focusedID) = again else {
            return XCTFail("expected focus")
        }
        XCTAssertEqual(crate.works.filter { $0.objectID == shelf[0].objectID }.count, 1)
        XCTAssertEqual(crate.focusedWorkID, focusedID)
    }

    func test_primaryVerb_emptyPopulatedInvalid() throws {
        var empty = Pinacotheca.empty
        try empty.dealCue(now: now, calendar: calendar, caster: caster)
        XCTAssertEqual(empty.status, .idle)
        XCTAssertFalse(empty.canCall)
        XCTAssertThrowsError(try empty.callFace(faceID: UUID(), now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? LineupFault, .notCued)
        }

        var crate = try stockedAndDealt(count: 4)
        XCTAssertTrue(crate.canCall)
        XCTAssertEqual(crate.status, .cued)
        XCTAssertEqual(crate.lineup.card?.faces.count, 4)

        XCTAssertThrowsError(try crate.callFace(faceID: UUID(), now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? LineupFault, .unknownFace)
        }
        let match = try XCTUnwrap(crate.lineup.card?.faces.first { $0.isTrue })
        XCTAssertThrowsError(try crate.missFace(faceID: match.id, now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? LineupFault, .missOnTrue)
        }
        XCTAssertThrowsError(try crate.peelLatestMark()) { error in
            XCTAssertEqual(error as? LineupFault, .nothingToPeel)
        }
        let decoy = try XCTUnwrap(crate.lineup.card?.faces.first { !$0.isTrue })
        XCTAssertThrowsError(try crate.callFace(faceID: decoy.id, now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? LineupFault, .faceIsDecoy)
        }
    }

    func test_twist_cueThenCall_titleKind_undoCallRestoresCued_undoFaultUndims() throws {
        var crate = Pinacotheca.empty
        for row in shelf.prefix(4) {
            _ = try crate.stockLoose(row, now: now, calendar: calendar)
        }
        let titleCast = LeadingTrueCast(kind: .title)
        try crate.dealCue(now: now, calendar: calendar, caster: titleCast)
        switch crate.lineup.card?.cue {
        case .title(let workID, let line):
            XCTAssertEqual(workID, crate.lineup.trueWorkID)
            XCTAssertEqual(line, crate.hangingTrue?.title)
        case .artist:
            XCTFail("pinned title cue")
        case .none:
            XCTFail("missing cue")
        }

        let decoy = try XCTUnwrap(crate.lineup.card?.faces.first { !$0.isTrue })
        let cueBeforeMiss = crate.lineup.card?.cue
        try crate.missFace(faceID: decoy.id, now: now, calendar: calendar)
        XCTAssertEqual(crate.lineup.card?.cue, cueBeforeMiss)
        XCTAssertEqual(crate.status, .fault)

        try crate.peelLatestMark()
        XCTAssertEqual(crate.reviewableFaults.count, 0)
        XCTAssertEqual(crate.lineup.card?.faces.first { $0.id == decoy.id }?.isDimmed, false)
        XCTAssertEqual(crate.status, .cued)

        let savedCue = try XCTUnwrap(crate.lineup.card?.cue)
        let savedFaces = try XCTUnwrap(crate.lineup.card?.faces)
        let match = try XCTUnwrap(crate.lineup.card?.faces.first { $0.isTrue })
        _ = try crate.callFace(faceID: match.id, now: now, calendar: calendar)
        XCTAssertEqual(foldLabel(crate.lineup), "called")

        try crate.peelLatestMark()
        XCTAssertEqual(foldLabel(crate.lineup), "cued")
        XCTAssertEqual(crate.hangingTrue?.file, .loose)
        XCTAssertEqual(crate.lineup.card?.cue, savedCue)
        XCTAssertEqual(crate.lineup.card?.faces.map(\.workID), savedFaces.map(\.workID))
        XCTAssertEqual(crate.callMarks.count, 0)
        XCTAssertTrue(crate.canCall)
    }

    func test_seedHangsFourFacesAndEnablesCall() {
        let crate = CrateSeed.crate(now: now, calendar: calendar, caster: caster, shelf: shelf)
        XCTAssertTrue(crate.onboardingComplete)
        XCTAssertTrue(crate.canCall)
        XCTAssertEqual(foldLabel(crate.lineup), "cued")
        XCTAssertEqual(crate.lineup.card?.faces.count, 4)
        XCTAssertEqual(crate.hangingTrue?.file, .loose)
        XCTAssertGreaterThanOrEqual(crate.works.count, 6)
        XCTAssertGreaterThanOrEqual(crate.loosePool.count, 4)
        XCTAssertGreaterThanOrEqual(crate.callMarks.count, 2)
        XCTAssertGreaterThanOrEqual(crate.reviewableFaults.count, 3)
        XCTAssertNotEqual(crate.status, .idle)
        XCTAssertFalse(crate.canDeal)
        let stayed = Set(crate.reviewableFaults.map(\.cue.line))
        XCTAssertGreaterThanOrEqual(stayed.count, 2)
        for mark in crate.reviewableFaults {
            XCTAssertFalse(mark.cue.line.isEmpty)
            XCTAssertNotNil(crate.work(mark.workID))
            XCTAssertNotEqual(mark.cue.line, "Line stayed.")
        }
    }

    func test_daykeyIsYYYYMMDDFromStartOfDay() {
        let late = TetraptychGMT.instant(2026, 9, 18, hour: 23)
        let next = TetraptychGMT.instant(2026, 9, 19, hour: 1)
        XCTAssertEqual(Daykey.stamp(late, calendar: calendar), 20260918)
        XCTAssertEqual(Daykey.stamp(next, calendar: calendar), 20260919)
        XCTAssertEqual(Daykey.shifting(20260918, by: -1, calendar: calendar), 20260917)
    }

    private func stockedAndDealt(count: Int) throws -> Pinacotheca {
        var crate = Pinacotheca.empty
        for row in shelf.prefix(count) {
            _ = try crate.stockLoose(row, now: now, calendar: calendar)
        }
        try crate.dealCue(now: now, calendar: calendar, caster: caster)
        return crate
    }

    private func foldLabel(_ lineup: Lineup) -> String {
        switch lineup {
        case .idle:
            return "idle"
        case .cued:
            return "cued"
        case .called:
            return "called"
        }
    }
}
