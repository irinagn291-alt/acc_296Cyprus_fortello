import Foundation

/// Role: Lineup. In-memory fold over Works. Views never keep a second lineup enum. Deal, Call, miss, Undo live here.
struct Pinacotheca: Equatable, Sendable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var works: [Work]
    var lineup: Lineup
    var callMarks: [CallMark]
    var faultMarks: [FaultMark]
    var peelLog: [PeelRef]
    var cachedRows: [CatalogRow]
    var focusedWorkID: UUID?

    static let currentSchema = 1

    static let empty = Pinacotheca(
        schemaVersion: currentSchema,
        onboardingComplete: false,
        works: [],
        lineup: .idle,
        callMarks: [],
        faultMarks: [],
        peelLog: [],
        cachedRows: [],
        focusedWorkID: nil
    )

    var loosePool: [Work] {
        works.filter { $0.file == .loose }
    }

    var calledWorks: [Work] {
        works.filter { $0.file == .called }
    }

    var reviewableFaults: [FaultMark] {
        faultMarks
    }

    var canDeal: Bool {
        if case .cued = lineup { return false }
        return loosePool.count >= 4
    }

    var canCall: Bool {
        if case .cued = lineup { return true }
        return false
    }

    var status: LineupStatus {
        lineup.status
    }

    var hangingTrue: Work? {
        guard let id = lineup.trueWorkID else { return nil }
        return work(id)
    }

    func work(_ id: UUID) -> Work? {
        works.first { $0.id == id }
    }

    mutating func dealCue(
        now: Date,
        calendar: Calendar,
        caster: any LineupCasting,
        faceIDs: [UUID]? = nil
    ) throws {
        _ = now
        _ = calendar
        if case .cued = lineup {
            throw LineupFault.alreadyCued
        }
        let pool = loosePool.sorted { lhs, rhs in
            if lhs.daykey != rhs.daykey { return lhs.daykey < rhs.daykey }
            return lhs.objectID < rhs.objectID
        }
        guard pool.count >= 4 else {
            lineup = .idle
            return
        }
        let currentTrue = lineup.trueWorkID
        let chosen = pool.first { $0.id != currentTrue } ?? pool[0]
        let card = FaceBench.card(
            trueWork: chosen,
            loose: pool,
            caster: caster,
            faceIDs: faceIDs
        )
        lineup = .cued(card)
        focusedWorkID = chosen.id
    }

    @discardableResult
    mutating func callFace(
        faceID: UUID,
        markID: UUID = UUID(),
        now: Date,
        calendar: Calendar
    ) throws -> CallMark {
        guard case .cued(let card) = lineup else {
            if case .called = lineup { throw LineupFault.alreadyCalled }
            throw LineupFault.notCued
        }
        guard let face = card.faces.first(where: { $0.id == faceID }) else {
            throw LineupFault.unknownFace
        }
        guard face.isTrue else { throw LineupFault.faceIsDecoy }
        guard let workIndex = works.firstIndex(where: { $0.id == card.cue.workID }) else {
            throw LineupFault.unknownFace
        }
        works[workIndex].file = .called
        let mark = CallMark(
            id: markID,
            workID: card.cue.workID,
            card: card,
            daykey: Daykey.stamp(now, calendar: calendar)
        )
        callMarks.append(mark)
        peelLog.append(PeelRef(kind: .call, markID: markID))
        lineup = .called(card, callMarkID: mark.id)
        focusedWorkID = mark.workID
        return mark
    }

    mutating func missFace(
        faceID: UUID,
        markID: UUID = UUID(),
        now: Date,
        calendar: Calendar
    ) throws {
        guard case .cued(var card) = lineup else {
            if case .called = lineup { throw LineupFault.alreadyCalled }
            throw LineupFault.notCued
        }
        guard let index = card.faces.firstIndex(where: { $0.id == faceID }) else {
            throw LineupFault.unknownFace
        }
        if card.faces[index].isTrue { throw LineupFault.missOnTrue }
        if card.faces[index].isDimmed { throw LineupFault.faceSpent }
        card.faces[index].isDimmed = true
        card.faces[index].isStruck = true
        let mark = FaultMark(
            id: markID,
            workID: card.cue.workID,
            faceID: faceID,
            daykey: Daykey.stamp(now, calendar: calendar),
            cue: card.cue
        )
        faultMarks.append(mark)
        peelLog.append(PeelRef(kind: .fault, markID: markID))
        lineup = .cued(card)
    }

    mutating func peelLatestMark() throws {
        guard let last = peelLog.popLast() else { throw LineupFault.nothingToPeel }
        switch last.kind {
        case .call:
            peelCall(markID: last.markID)
        case .fault:
            peelFault(markID: last.markID)
        }
    }

    @discardableResult
    mutating func stockLoose(
        _ row: CatalogRow,
        now: Date,
        calendar: Calendar,
        id: UUID = UUID()
    ) throws -> StockFocus {
        guard row.objectID > 0 else { throw LineupFault.emptyObject }
        if let existing = works.first(where: { $0.objectID == row.objectID }) {
            focusedWorkID = existing.id
            return .focused(existing.id)
        }
        let work = Work.loose(from: row, id: id, daykey: Daykey.stamp(now, calendar: calendar))
        works.append(work)
        remember(row)
        focusedWorkID = work.id
        return .inserted(work.id)
    }

    mutating func remember(_ rows: [CatalogRow]) {
        for row in rows {
            remember(row)
        }
    }

    mutating func remember(_ row: CatalogRow) {
        guard row.objectID > 0 else { return }
        if let index = cachedRows.firstIndex(where: { $0.objectID == row.objectID }) {
            cachedRows[index] = row
        } else {
            cachedRows.append(row)
        }
    }

    mutating func setOnboardingComplete(_ flag: Bool) {
        onboardingComplete = flag
    }

    mutating func resetAllData() {
        self = .empty
    }

    func fallbackRows(shelf: [CatalogRow]) -> [CatalogRow] {
        var seen = Set<Int>()
        var merged: [CatalogRow] = []
        for row in cachedRows + shelf {
            if seen.insert(row.objectID).inserted {
                merged.append(row)
            }
        }
        return merged
    }

    private mutating func peelCall(markID: UUID) {
        guard let index = callMarks.firstIndex(where: { $0.id == markID }) else { return }
        let mark = callMarks.remove(at: index)
        if let workIndex = works.firstIndex(where: { $0.id == mark.workID }) {
            works[workIndex].file = .loose
        }
        lineup = .cued(mark.card)
        focusedWorkID = mark.workID
    }

    private mutating func peelFault(markID: UUID) {
        guard let index = faultMarks.firstIndex(where: { $0.id == markID }) else { return }
        let mark = faultMarks.remove(at: index)
        switch lineup {
        case .idle:
            break
        case .cued(var card):
            undim(faceID: mark.faceID, in: &card)
            lineup = .cued(card)
        case .called(var card, let callMarkID):
            undim(faceID: mark.faceID, in: &card)
            lineup = .called(card, callMarkID: callMarkID)
        }
    }

    private func undim(faceID: UUID, in card: inout LineupCard) {
        guard let index = card.faces.firstIndex(where: { $0.id == faceID }) else { return }
        card.faces[index].isDimmed = false
        card.faces[index].isStruck = false
    }
}
