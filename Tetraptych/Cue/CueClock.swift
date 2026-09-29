import Foundation

/// Role: Cue. Desk cue rail clock. fireAt = runStart + Σprior + offset. punctuality = 1 − min(1, |actual − planned| / 1.5s).
enum CueClock {
    static let window: TimeInterval = 1.5
    static let goOffset: TimeInterval = 0.9

    static func fireAt(runStart: Date, prior: [TimeInterval], offset: TimeInterval) -> Date {
        let total = prior.reduce(0, +) + offset
        return runStart.addingTimeInterval(total)
    }

    static func punctuality(
        actual: Date,
        planned: Date,
        window: TimeInterval = CueClock.window
    ) -> Double {
        let drift = abs(actual.timeIntervalSince(planned))
        return 1 - min(1, drift / window)
    }
}

/// Role: Cue. One Deal run on the rail. Presentation only. The crate fold does not store the clock.
struct CueRun: Equatable, Sendable {
    var runStart: Date
    var prior: [TimeInterval]
    var offset: TimeInterval
    var lastPunctuality: Double?

    func plannedFire() -> Date {
        CueClock.fireAt(runStart: runStart, prior: prior, offset: offset)
    }
}
