import Foundation

/// Role: Lineup. Preference keys. Snapshot is JSON Data under tpt.crate.v1. Demo is Simulator-only.
enum CrateKey {
    static let snapshot = "tpt.crate.v1"
    static let backup = "tpt.crate.v1.backup"
    static let demo = "tpt.demo.v1"
}

enum CrateCodecError: Error, Equatable, Sendable {
    case unsupportedSchema(Int)
    case corrupt
}

/// Role: Lineup. Codable PinacothecaDocument. schemaVersion from 1. Lineup case is stored. Called-ness is Work.file.
enum PinacothecaDocument {
    static func encode(_ crate: Pinacotheca) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        var copy = crate
        copy.schemaVersion = Pinacotheca.currentSchema
        return try encoder.encode(RootFile(crate: copy))
    }

    static func decode(_ data: Data) throws -> Pinacotheca {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw CrateCodecError.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                var crate = try decoder.decode(RootFile.self, from: data).crate
                crate.schemaVersion = Pinacotheca.currentSchema
                return crate
            } catch let error as CrateCodecError {
                throw error
            } catch {
                throw CrateCodecError.corrupt
            }
        default:
            throw CrateCodecError.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}

private struct RootFile: Codable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var works: [Work]
    var lineup: Lineup
    var callMarks: [CallMark]
    var faultMarks: [FaultMark]
    var peelLog: [PeelRef]
    var cachedRows: [CatalogRow]
    var focusedWorkID: UUID?

    init(crate: Pinacotheca) {
        schemaVersion = crate.schemaVersion
        onboardingComplete = crate.onboardingComplete
        works = crate.works
        lineup = crate.lineup
        callMarks = crate.callMarks
        faultMarks = crate.faultMarks
        peelLog = crate.peelLog
        cachedRows = crate.cachedRows
        focusedWorkID = crate.focusedWorkID
    }

    var crate: Pinacotheca {
        Pinacotheca(
            schemaVersion: schemaVersion,
            onboardingComplete: onboardingComplete,
            works: works,
            lineup: lineup,
            callMarks: callMarks,
            faultMarks: faultMarks,
            peelLog: peelLog,
            cachedRows: cachedRows,
            focusedWorkID: focusedWorkID
        )
    }
}
