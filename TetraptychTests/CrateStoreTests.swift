import XCTest
@testable import Tetraptych

final class CrateStoreTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar { TetraptychGMT.calendar }
    private var now: Date { TetraptychGMT.instant(2026, 9, 18) }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        suiteName = "tpt.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    @MainActor
    func test_roundTrip_reloadPreservesLineupMarksAndFileCase() async throws {
        let store = makeStore()
        await store.load()
        for row in CrateShelf.bundled.rows.prefix(4) {
            try await store.stockLoose(row, now: now, calendar: calendar)
        }
        try await store.dealCue(now: now, calendar: calendar)
        let decoy = try XCTUnwrap(store.pinacotheca.lineup.card?.faces.first { !$0.isTrue })
        try await store.missFace(faceID: decoy.id, now: now, calendar: calendar)
        let match = try XCTUnwrap(store.pinacotheca.lineup.card?.faces.first { $0.isTrue })
        try await store.callFace(faceID: match.id, now: now, calendar: calendar)
        await store.flush()

        let relaunched = makeStore()
        await relaunched.load()
        XCTAssertNil(relaunched.warning)
        XCTAssertEqual(relaunched.pinacotheca.works.count, 4)
        XCTAssertEqual(relaunched.pinacotheca.hangingTrue?.file, .called)
        XCTAssertEqual(relaunched.pinacotheca.callMarks.count, 1)
        XCTAssertEqual(relaunched.pinacotheca.faultMarks.count, 1)
        XCTAssertEqual(relaunched.pinacotheca.status, .called)
        XCTAssertNotNil(defaults.data(forKey: CrateKey.snapshot))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("crate.json").path))
        let calledness = relaunched.pinacotheca.works.map(\.file)
        XCTAssertEqual(calledness.filter { $0 == .called }.count, 1)
    }

    @MainActor
    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        await store.load()
        try await store.stockLoose(CrateShelf.bundled.rows[0], now: now, calendar: calendar)
        await store.flush()
        if let good = defaults.data(forKey: CrateKey.snapshot) {
            defaults.set(good, forKey: CrateKey.backup)
        }
        let file = directory.appendingPathComponent("crate.json")
        let backup = directory.appendingPathComponent("crate.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: CrateKey.snapshot)
        try Data("{not-json".utf8).write(to: file)

        let loaded = makeStore()
        await loaded.load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.pinacotheca.works.count, 1)
    }

    @MainActor
    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults.set(Data("nope".utf8), forKey: CrateKey.snapshot)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("crate.json"))
        let store = makeStore()
        await store.load()
        XCTAssertEqual(store.warning, .startedEmpty)
        XCTAssertTrue(store.pinacotheca.works.isEmpty)
        XCTAssertFalse(store.pinacotheca.onboardingComplete)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let crate = CrateSeed.crate(now: now, calendar: calendar)
        let data = try PinacothecaDocument.encode(crate)
        let decoded = try PinacothecaDocument.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.works.count, crate.works.count)
        XCTAssertEqual(decoded.lineup.trueWorkID, crate.lineup.trueWorkID)
        XCTAssertEqual(decoded.faultMarks.count, crate.faultMarks.count)
        XCTAssertTrue(decoded.works.contains { $0.file == .called })
        XCTAssertTrue(decoded.works.contains { $0.file == .loose })

        XCTAssertThrowsError(try PinacothecaDocument.decode(Data("{\"schemaVersion\":99}".utf8))) { error in
            XCTAssertEqual(error as? CrateCodecError, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try PinacothecaDocument.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? CrateCodecError, .corrupt)
        }
    }

    @MainActor
    func test_resetAllDataClearsSnapshotAndFiles() async throws {
        let store = makeStore()
        await store.load()
        try await store.stockLoose(CrateShelf.bundled.rows[0], now: now, calendar: calendar)
        await store.flush()
        await store.resetAllData()
        await store.load()
        XCTAssertTrue(store.pinacotheca.works.isEmpty)
        XCTAssertFalse(store.pinacotheca.onboardingComplete)
        XCTAssertNil(defaults.data(forKey: CrateKey.snapshot))
        XCTAssertNil(defaults.data(forKey: CrateKey.backup))
        let leftovers = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    @MainActor
    func test_onboardingFlagDebouncesUntilFlush() async throws {
        let store = makeStore()
        await store.load()
        await store.setOnboardingComplete(true)
        await store.flush()
        let loaded = makeStore()
        await loaded.load()
        XCTAssertTrue(loaded.pinacotheca.onboardingComplete)
    }

    #if targetEnvironment(simulator)
    @MainActor
    func test_simulatorSeedWritesOnceAndEnablesCall() async throws {
        let store = makeStore()
        await store.seedDemoIfNeeded(now: now, calendar: calendar)
        let firstWorks = store.pinacotheca.works.count
        await store.seedDemoIfNeeded(now: now, calendar: calendar)
        XCTAssertEqual(store.pinacotheca.works.count, firstWorks)
        XCTAssertTrue(store.pinacotheca.onboardingComplete)
        XCTAssertTrue(store.pinacotheca.canCall)
        XCTAssertEqual(store.pinacotheca.hangingTrue?.file, .loose)
        XCTAssertNotEqual(store.pinacotheca.status, .idle)
        XCTAssertGreaterThanOrEqual(store.pinacotheca.works.count, 6)
        XCTAssertTrue(defaults.bool(forKey: CrateKey.demo))
        XCTAssertNotNil(defaults.data(forKey: CrateKey.snapshot))
    }
    #endif

    @MainActor
    func test_seekFallsBackToLocalShelf() async throws {
        let store = makeStore(client: CatalogClient(carrier: FailingCarrier()))
        await store.load()
        let rows = try await store.seek("gogh")
        XCTAssertEqual(rows.first?.title, CrateShelf.bundled.rows[0].title)
        XCTAssertGreaterThanOrEqual(rows.count, 8)
    }

    @MainActor
    func test_emptyQueryDoesNotHitNetwork() async throws {
        let log = RequestLog()
        let store = makeStore(client: CatalogClient(carrier: LoggingCarrier(log: log)))
        let rows = try await store.seek("   ")
        XCTAssertFalse(rows.isEmpty)
        let count = await log.count
        XCTAssertEqual(count, 0)
    }

    @MainActor
    private func makeStore(client: CatalogClient = CatalogClient(carrier: FailingCarrier())) -> LineupStore {
        LineupStore(
            directory: directory,
            suiteName: suiteName,
            client: client,
            caster: LeadingTrueCast(kind: .artist),
            shelf: .bundled,
            writeDelayNanoseconds: 0,
            seekDebounceNanoseconds: 0
        )
    }
}

actor RequestLog {
    private var urls: [URL?] = []

    @discardableResult
    func append(_ url: URL?) -> Int {
        urls.append(url)
        return urls.count
    }

    var count: Int { urls.count }
}

struct FailingCarrier: SeekCarrying {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        throw URLError(.timedOut)
    }
}

struct LoggingCarrier: SeekCarrying {
    let log: RequestLog

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        await log.append(request.url)
        throw URLError(.cannotConnectToHost)
    }
}
