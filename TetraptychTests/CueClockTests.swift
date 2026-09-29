import XCTest
@testable import Tetraptych

final class CueClockTests: XCTestCase {
    func test_fireAtIsRunStartPlusPriorPlusOffset() {
        let start = Date(timeIntervalSince1970: 1_000)
        let planned = CueClock.fireAt(runStart: start, prior: [0.5, 0.25], offset: 0.1)
        XCTAssertEqual(planned.timeIntervalSince1970, 1_000.85, accuracy: 0.000_1)
    }

    func test_punctualityIsOneMinusClampedDriftOverWindow() {
        let planned = Date(timeIntervalSince1970: 50)
        XCTAssertEqual(CueClock.punctuality(actual: planned, planned: planned), 1, accuracy: 0.000_1)
        XCTAssertEqual(
            CueClock.punctuality(actual: planned.addingTimeInterval(1.5), planned: planned),
            0,
            accuracy: 0.000_1
        )
        XCTAssertEqual(
            CueClock.punctuality(actual: planned.addingTimeInterval(0.75), planned: planned),
            0.5,
            accuracy: 0.000_1
        )
        XCTAssertEqual(
            CueClock.punctuality(actual: planned.addingTimeInterval(-2), planned: planned),
            0,
            accuracy: 0.000_1
        )
        XCTAssertEqual(CueClock.window, 1.5, accuracy: 0.000_1)
    }
}
