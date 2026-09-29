import Foundation

/// Role: Lineup. Projects Pinacotheca to UserDefaults tpt.crate.v1 plus an atomic Application Support file. Views never touch this type.
actor CrateVault {
    private let directory: URL
    private let suiteName: String?
    private let fileManager: FileManager

    init(
        directory: URL,
        suiteName: String? = nil,
        fileManager: FileManager = .default
    ) {
        self.directory = directory
        self.suiteName = suiteName
        self.fileManager = fileManager
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Fortello", isDirectory: true)
    }

    func load() -> (crate: Pinacotheca, warning: CrateWarning?) {
        if let crate = decode(defaults().data(forKey: CrateKey.snapshot)) {
            return (crate, nil)
        }
        if let crate = decode(read(fileURL)) {
            return (crate, nil)
        }
        if let crate = decode(defaults().data(forKey: CrateKey.backup)) {
            return (crate, .recoveredFromBackup)
        }
        if let crate = decode(read(backupURL)) {
            return (crate, .recoveredFromBackup)
        }
        let hadPayload = defaults().data(forKey: CrateKey.snapshot) != nil
            || fileManager.fileExists(atPath: fileURL.path)
        return (.empty, hadPayload ? .startedEmpty : nil)
    }

    func save(_ crate: Pinacotheca) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try PinacothecaDocument.encode(crate)
        let box = defaults()
        if let current = box.data(forKey: CrateKey.snapshot) {
            box.set(current, forKey: CrateKey.backup)
        }
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: backupURL)
            try? fileManager.copyItem(at: fileURL, to: backupURL)
        }
        box.set(data, forKey: CrateKey.snapshot)
        try data.write(to: fileURL, options: .atomic)
    }

    func wipe() throws {
        let box = defaults()
        box.removeObject(forKey: CrateKey.snapshot)
        box.removeObject(forKey: CrateKey.backup)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
    }

    func demoPlanted() -> Bool {
        defaults().object(forKey: CrateKey.demo) != nil
    }

    func markDemoPlanted() {
        defaults().set(true, forKey: CrateKey.demo)
    }

    private func decode(_ data: Data?) -> Pinacotheca? {
        guard let data else { return nil }
        return try? PinacothecaDocument.decode(data)
    }

    private func read(_ url: URL) -> Data? {
        try? Data(contentsOf: url)
    }

    private var fileURL: URL {
        directory.appendingPathComponent("crate.json", isDirectory: false)
    }

    private var backupURL: URL {
        directory.appendingPathComponent("crate.json.backup", isDirectory: false)
    }

    private func defaults() -> UserDefaults {
        if let suiteName {
            return UserDefaults(suiteName: suiteName) ?? .standard
        }
        return .standard
    }
}
