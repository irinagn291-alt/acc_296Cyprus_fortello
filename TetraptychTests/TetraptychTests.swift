import XCTest
@testable import Tetraptych

final class TetraptychTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: TetraptychApp.self), "TetraptychApp")
        XCTAssertEqual(CatalogClient.userAgent, "Tetraptych/1.0 (iOS; +https://tetraptych-lineup.pro)")
        XCTAssertEqual(CatalogClient.contactURL.absoluteString, "https://tetraptych-lineup.pro/contact-us")
        XCTAssertEqual(CrateShelf.bundled.rows.count, 10)
        XCTAssertEqual(CrateKey.snapshot, "tpt.crate.v1")
        XCTAssertEqual(CrateKey.demo, "tpt.demo.v1")
        XCTAssertEqual(LineupInk.face, "SF Pro")
        XCTAssertEqual(LineupInk.Hex.background, "#FAF8F5")
        XCTAssertEqual(LineupInk.Hex.surface, "#FEFEFD")
        XCTAssertEqual(LineupInk.Hex.ink, "#392A18")
        XCTAssertEqual(LineupInk.Hex.accent, "#C8781E")
        XCTAssertEqual(LineupInk.Hex.muted, "#7E6F5D")
        XCTAssertEqual(LineupInk.Step.allCases.count, 6)
        XCTAssertEqual(LineupArt.controlFace, "tpt_ControlFace")
        XCTAssertEqual(LineupArt.dealStamp, "tpt_DealStamp")
        XCTAssertEqual(LineupSheet.allCases.count, 4)
        XCTAssertFalse(LineupSheet.allCases.map(\.rawValue).contains("game"))
        XCTAssertEqual(LineupRadius.card, 12)
        XCTAssertEqual(LineupRadius.chip, 8)
        XCTAssertEqual(CatalogClient.metHomeURL.absoluteString, "https://www.metmuseum.org")
    }
}
