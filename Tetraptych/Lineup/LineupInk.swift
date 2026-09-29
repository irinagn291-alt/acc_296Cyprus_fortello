import SwiftUI

/// Role: Lineup. Named colours and SF Pro. Hex lives only here: #FAF8F5 #FEFEFD #392A18 #C8781E #7E6F5D.
enum LineupInk {
    static let face = "SF Pro"

    enum Hex {
        static let background = "#FAF8F5"
        static let surface = "#FEFEFD"
        static let ink = "#392A18"
        static let accent = "#C8781E"
        static let muted = "#7E6F5D"
    }

    enum Palette {
        static let background = Color("background")
        static let surface = Color("surface")
        static let ink = Color("ink")
        static let accent = Color("lineupAccent")
        static let muted = Color("muted")
    }

    enum Step: CaseIterable {
        case display
        case title
        case headline
        case body
        case caption
        case micro
    }

    /// SF Pro via Font.system. Caption and micro are monospaced. Display is Heavy, never above 34pt.
    static func font(_ step: Step, axle: DynamicTypeSize = .large) -> Font {
        switch step {
        case .display:
            if axle >= .accessibility3 {
                return .system(.title, design: .default).weight(.heavy)
            }
            return .system(.largeTitle, design: .default).weight(.black)
        case .title:
            return .system(.title2, design: .default).weight(.heavy)
        case .headline:
            return .system(.headline, design: .default).weight(.bold)
        case .body:
            return .system(.body, design: .default)
        case .caption:
            return .system(.footnote, design: .monospaced).weight(.semibold)
        case .micro:
            return .system(.caption, design: .monospaced)
        }
    }
}
