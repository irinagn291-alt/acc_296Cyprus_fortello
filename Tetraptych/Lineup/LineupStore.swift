import Foundation
import Observation

/// Role: Lineup. Observable fold owner. Memory is the source of truth. UserDefaults is the projection. Views call dealCue, callFace, missFace, and peelLatestMark.
@MainActor
@Observable
final class LineupStore {
    static let seekDebounceNanoseconds: UInt64 = 500_000_000

    private(set) var pinacotheca: Pinacotheca
    private(set) var warning: CrateWarning?
    private(set) var lastWriteError: String?

    private let vault: CrateVault
    private let client: CatalogClient
    private let caster: any LineupCasting
    private let shelf: CrateShelf
    private let writeDelayNanoseconds: UInt64
    private let seekDebounce: UInt64
    private var persistTask: Task<Void, Never>?
    private var seekTask: Task<[CatalogRow], Error>?

    init(
        directory: URL,
        suiteName: String? = nil,
        client: CatalogClient = CatalogClient(),
        caster: any LineupCasting = RotateCast(),
        shelf: CrateShelf = .bundled,
        writeDelayNanoseconds: UInt64 = 280_000_000,
        seekDebounceNanoseconds: UInt64 = LineupStore.seekDebounceNanoseconds
    ) {
        self.vault = CrateVault(directory: directory, suiteName: suiteName)
        self.client = client
        self.caster = caster
        self.shelf = shelf
        self.writeDelayNanoseconds = writeDelayNanoseconds
        self.seekDebounce = seekDebounceNanoseconds
        self.pinacotheca = .empty
        self.warning = nil
        self.lastWriteError = nil
    }

    convenience init() {
        let directory: URL
        do {
            directory = try CrateVault.applicationSupportDirectory()
        } catch {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent("Fortello", isDirectory: true)
        }
        self.init(directory: directory)
    }

    func load() async {
        let loaded = await vault.load()
        pinacotheca = loaded.crate
        warning = loaded.warning
        lastWriteError = nil
    }

    func dealCue(now: Date = Date(), calendar: Calendar = .current) async throws {
        var next = pinacotheca
        try next.dealCue(now: now, calendar: calendar, caster: caster)
        pinacotheca = next
        await persistNow()
    }

    func callFace(faceID: UUID, now: Date = Date(), calendar: Calendar = .current) async throws {
        var next = pinacotheca
        _ = try next.callFace(faceID: faceID, now: now, calendar: calendar)
        pinacotheca = next
        await persistNow()
    }

    func missFace(faceID: UUID, now: Date = Date(), calendar: Calendar = .current) async throws {
        var next = pinacotheca
        try next.missFace(faceID: faceID, now: now, calendar: calendar)
        pinacotheca = next
        await persistNow()
    }

    func peelLatestMark() async throws {
        var next = pinacotheca
        try next.peelLatestMark()
        pinacotheca = next
        await persistNow()
    }

    @discardableResult
    func stockLoose(_ row: CatalogRow, now: Date = Date(), calendar: Calendar = .current) async throws -> StockFocus {
        var next = pinacotheca
        let focus = try next.stockLoose(row, now: now, calendar: calendar)
        pinacotheca = next
        await persistNow()
        return focus
    }

    func seek(_ query: String, page: Int = 1, pageSize: Int = 8) async throws -> [CatalogRow] {
        seekTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return pinacotheca.fallbackRows(shelf: shelf.rows)
        }
        let client = self.client
        let delay = seekDebounce
        let task = Task { () throws -> [CatalogRow] in
            if delay > 0 {
                try await Task.sleep(nanoseconds: delay)
            }
            try Task.checkCancellation()
            return try await client.search(query: trimmed, page: page, pageSize: pageSize)
        }
        seekTask = task
        do {
            let rows = try await task.value
            if Task.isCancelled { throw SeekFault.cancelled }
            if rows.isEmpty {
                return pinacotheca.fallbackRows(shelf: shelf.rows)
            }
            var next = pinacotheca
            next.remember(rows)
            pinacotheca = next
            await persistNow()
            return rows
        } catch is CancellationError {
            throw SeekFault.cancelled
        } catch let fault as SeekFault where fault == .cancelled {
            throw fault
        } catch {
            return pinacotheca.fallbackRows(shelf: shelf.rows)
        }
    }

    func setOnboardingComplete(_ flag: Bool) async {
        var next = pinacotheca
        next.setOnboardingComplete(flag)
        pinacotheca = next
        schedulePersist()
    }

    func flush() async {
        persistTask?.cancel()
        persistTask = nil
        await persistNow()
    }

    func resetAllData() async {
        persistTask?.cancel()
        persistTask = nil
        pinacotheca = .empty
        warning = nil
        lastWriteError = nil
        do {
            try await vault.wipe()
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    func seedDemoIfNeeded(now: Date = Date(), calendar: Calendar = .current) async {
        #if targetEnvironment(simulator)
        if await vault.demoPlanted() { return }
        pinacotheca = CrateSeed.crate(now: now, calendar: calendar, caster: caster, shelf: shelf.rows)
        await vault.markDemoPlanted()
        await persistNow()
        #else
        _ = now
        _ = calendar
        #endif
    }

    private func persistNow() async {
        do {
            try await vault.save(pinacotheca)
            lastWriteError = nil
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func schedulePersist() {
        persistTask?.cancel()
        let delay = writeDelayNanoseconds
        persistTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.persistNow()
        }
    }
}
