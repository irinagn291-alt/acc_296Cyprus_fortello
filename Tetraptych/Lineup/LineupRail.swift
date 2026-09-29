import Foundation
import Observation
import SwiftUI

/// Role: Lineup. Presentation fold over LineupStore. Views call dealCue, callFace, missFace, and peelLatestMark and never keep a second lineup enum.
@MainActor
@Observable
final class LineupRail {
    let store: LineupStore
    private(set) var pinacotheca: Pinacotheca
    var isBooting: Bool
    var showsOnboarding: Bool
    var cover: LineupCover?
    var recoveredNotice: Bool
    var isDealing: Bool
    var dealBusy: Bool
    var isPeeling: Bool
    var peelBusy: Bool
    var faceBusy: UUID?
    var isSeeking: Bool
    var query: String
    var seekHits: [CatalogRow]
    var seekFault: String?
    var hangFault: String?
    var stockNote: String?
    var stockingObjectID: Int?
    var callPulse: Int
    var showSuccess: Bool
    var dayStamp: Int
    var cueRun: CueRun?
    private var cueConsumed: Bool
    private var seekTask: Task<Void, Never>?
    private var successTask: Task<Void, Never>?

    init(store: LineupStore, isBooting: Bool = true) {
        self.store = store
        self.pinacotheca = store.pinacotheca
        self.isBooting = isBooting
        self.showsOnboarding = false
        self.cover = nil
        self.recoveredNotice = false
        self.isDealing = false
        self.dealBusy = false
        self.isPeeling = false
        self.peelBusy = false
        self.faceBusy = nil
        self.isSeeking = false
        self.query = ""
        self.seekHits = []
        self.seekFault = nil
        self.hangFault = nil
        self.stockNote = nil
        self.stockingObjectID = nil
        self.callPulse = 0
        self.showSuccess = false
        self.dayStamp = Daykey.stamp(Date(), calendar: .current)
        self.cueRun = nil
        self.cueConsumed = false
    }

    static func live() -> LineupRail {
        LineupRail(store: LineupStore())
    }

    func boot() async {
        guard isBooting else { return }
        await store.load()
        await store.seedDemoIfNeeded()
        sync()
        recoveredNotice = store.warning != nil
        showsOnboarding = !pinacotheca.onboardingComplete
        isBooting = false
        if query.isEmpty {
            seekHits = pinacotheca.fallbackRows(shelf: CrateShelf.bundled.rows)
        }
        if case .cued = pinacotheca.lineup, cueRun == nil {
            startRun(now: Date())
        }
        if !showsOnboarding {
            consumeCue()
        }
    }

    func flush() async {
        await store.flush()
        sync()
    }

    func refreshDay() {
        dayStamp = Daykey.stamp(Date(), calendar: .current)
    }

    func handle(phase: ScenePhase) async {
        switch phase {
        case .inactive, .background:
            await flush()
        case .active:
            refreshDay()
        @unknown default:
            break
        }
    }

    func finishOnboarding() async {
        await store.setOnboardingComplete(true)
        await store.flush()
        sync()
        showsOnboarding = false
        consumeCue()
    }

    func replayOnboarding() {
        cover = nil
        showsOnboarding = true
    }

    func present(_ cover: LineupCover) {
        self.cover = cover
    }

    func handle(_ job: LineupJob) {
        switch job {
        case .quiz:
            cover = nil
        case .deal:
            cover = nil
            Task { await dealCue() }
        case .explore, .saved, .settings, .cue:
            cover = job.cover
        }
    }

    func handle(url: URL) {
        guard let job = LineupJob.parse(url) else { return }
        handle(job)
    }

    func dealCue(now: Date = Date()) async {
        guard !isDealing else { return }
        isDealing = true
        let pulse = Task {
            try await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { dealBusy = true }
        }
        do {
            try await store.dealCue(now: now)
            sync()
            if case .cued = pinacotheca.lineup {
                advanceRun(now: now)
            } else {
                cueRun = nil
            }
            showSuccess = false
            if store.lastWriteError == nil {
                hangFault = nil
            }
        } catch {
            hangFault = LineupCopy.fault(error)
            sync()
        }
        pulse.cancel()
        dealBusy = false
        isDealing = false
        sync()
    }

    func tapFace(_ face: Face, now: Date = Date()) async {
        guard faceBusy == nil else { return }
        guard pinacotheca.canCall else {
            hangFault = LineupCopy.fault(LineupFault.notCued)
            return
        }
        if face.isDimmed {
            hangFault = LineupCopy.fault(LineupFault.faceSpent)
            return
        }
        faceBusy = face.id
        defer { faceBusy = nil }
        do {
            if face.isTrue {
                try await store.callFace(faceID: face.id, now: now)
                scorePunctuality(at: now)
                callPulse += 1
                flashSuccess()
            } else {
                try await store.missFace(faceID: face.id, now: now)
            }
            sync()
            if store.lastWriteError == nil {
                hangFault = nil
            }
        } catch {
            hangFault = LineupCopy.fault(error)
            sync()
        }
    }

    func peelLatestMark() async {
        guard !isPeeling else { return }
        isPeeling = true
        let pulse = Task {
            try await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { peelBusy = true }
        }
        do {
            try await store.peelLatestMark()
            showSuccess = false
            sync()
            if store.lastWriteError == nil {
                hangFault = nil
            }
        } catch {
            hangFault = LineupCopy.fault(error)
            sync()
        }
        pulse.cancel()
        peelBusy = false
        isPeeling = false
        sync()
    }

    func stockLoose(_ row: CatalogRow) async {
        guard stockingObjectID == nil else { return }
        stockingObjectID = row.objectID
        do {
            let focus = try await store.stockLoose(row)
            sync()
            switch focus {
            case .inserted:
                stockNote = "Saved as Loose."
            case .focused:
                stockNote = "Already in the crate."
            }
            hangFault = nil
        } catch {
            stockNote = LineupCopy.fault(error)
        }
        stockingObjectID = nil
        if store.lastWriteError != nil {
            hangFault = "Write failed. Deal or Undo again."
        }
    }

    func scheduleSeek() {
        seekTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        seekTask = Task { await seek(trimmed) }
    }

    func resetAllData() async {
        seekTask?.cancel()
        successTask?.cancel()
        await store.resetAllData()
        sync()
        cover = nil
        query = ""
        seekHits = pinacotheca.fallbackRows(shelf: CrateShelf.bundled.rows)
        seekFault = nil
        hangFault = nil
        stockNote = nil
        recoveredNotice = false
        showSuccess = false
        showsOnboarding = true
        cueConsumed = true
        cueRun = nil
    }

    func work(for id: UUID) -> Work? {
        pinacotheca.works.first { $0.id == id }
    }

    var dealEnabled: Bool {
        pinacotheca.canDeal && !isDealing
    }

    var peelEnabled: Bool {
        !pinacotheca.peelLog.isEmpty && !isPeeling
    }

    var quizIsEmpty: Bool {
        if case .idle = pinacotheca.lineup { return true }
        return pinacotheca.lineup.card == nil
    }

    var savedIsEmpty: Bool {
        pinacotheca.calledWorks.isEmpty && pinacotheca.reviewableFaults.isEmpty
    }

    var exploreIsEmpty: Bool {
        seekHits.isEmpty && !isSeeking
    }

    var settingsIsEmpty: Bool {
        pinacotheca.works.isEmpty && pinacotheca.callMarks.isEmpty && pinacotheca.faultMarks.isEmpty
    }

    func goStamp(at date: Date) -> String {
        guard let run = cueRun, pinacotheca.status == .cued || pinacotheca.status == .fault else {
            return "HOLD"
        }
        let remaining = run.plannedFire().timeIntervalSince(date)
        if remaining <= 0 { return "GO" }
        return LineupFigures.seconds(remaining)
    }

    private func seek(_ trimmed: String) async {
        if trimmed.isEmpty {
            isSeeking = false
            seekFault = nil
            seekHits = pinacotheca.fallbackRows(shelf: CrateShelf.bundled.rows)
            return
        }
        let pulse = Task {
            try await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { isSeeking = true }
        }
        defer {
            pulse.cancel()
            isSeeking = false
        }
        do {
            let hits = try await store.seek(trimmed)
            if Task.isCancelled { return }
            sync()
            seekHits = hits
            seekFault = nil
        } catch is CancellationError {
            return
        } catch let fault as SeekFault where fault == .cancelled {
            return
        } catch let fault as SeekFault {
            if Task.isCancelled { return }
            sync()
            seekHits = pinacotheca.fallbackRows(shelf: CrateShelf.bundled.rows)
            seekFault = LineupCopy.seek(fault)
        } catch {
            if Task.isCancelled { return }
            sync()
            seekHits = pinacotheca.fallbackRows(shelf: CrateShelf.bundled.rows)
            seekFault = LineupCopy.seek(.transport)
        }
    }

    private func flashSuccess() {
        successTask?.cancel()
        showSuccess = true
        successTask = Task {
            try? await Task.sleep(for: .milliseconds(1200))
            if !Task.isCancelled {
                showSuccess = false
            }
        }
    }

    private func startRun(now: Date) {
        cueRun = CueRun(
            runStart: now,
            prior: [],
            offset: CueClock.goOffset,
            lastPunctuality: nil
        )
    }

    private func advanceRun(now: Date) {
        if var run = cueRun {
            run.prior.append(run.offset)
            run.offset = CueClock.goOffset
            run.lastPunctuality = nil
            cueRun = run
        } else {
            startRun(now: now)
        }
    }

    private func scorePunctuality(at now: Date) {
        guard var run = cueRun else { return }
        let planned = run.plannedFire()
        run.lastPunctuality = CueClock.punctuality(actual: now, planned: planned)
        cueRun = run
    }

    private func sync() {
        pinacotheca = store.pinacotheca
        if let write = store.lastWriteError, !write.isEmpty {
            hangFault = "Write failed. Deal or Undo again."
        }
    }

    private func consumeCue() {
        if let hook = LineupLinks.consume(
            arguments: ProcessInfo.processInfo.arguments,
            onboardingComplete: pinacotheca.onboardingComplete,
            consumed: &cueConsumed
        ) {
            switch hook.sheet {
            case .quiz:
                cover = nil
            case .explore:
                cover = .explore
            case .saved:
                cover = .saved
            case .settings:
                cover = .settings
            }
        }
    }
}
