import SwiftUI

/// Role: Lineup. Space, radius, motion, cutout names, dry copy. Colour and type stay on LineupInk. Views never pick a second kit.
enum LineupSpace {
    static let unit: CGFloat = 4
    static func step(_ n: Int) -> CGFloat { unit * CGFloat(n) }

    static let hit: CGFloat = step(11)
    static let outer: CGFloat = step(4)
    static let card: CGFloat = step(3)
    static let chip: CGFloat = step(2)
    static let gap: CGFloat = step(2)
    static let tight: CGFloat = step(1)
    static let loose: CGFloat = step(4)
    static let rule: CGFloat = 1
    static let heroRule: CGFloat = step(2)
    static let art: CGFloat = step(40)
    static let headerBand: CGFloat = step(14)
}

enum LineupRadius {
    static let card: CGFloat = 12
    static let chip: CGFloat = 8
}

enum LineupMotion {
    static let snap = Animation.easeOut(duration: 0.16)

    static func swap(_ reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : snap
    }

    static func sheet(_ reduceMotion: Bool) -> Animation {
        .easeOut(duration: 0.16)
    }
}

enum LineupArt {
    static let splash = "tpt_Splash"
    static let onboarding1 = "tpt_Onboarding1"
    static let onboarding2 = "tpt_Onboarding2"
    static let onboarding3 = "tpt_Onboarding3"
    static let emptyHome = "tpt_EmptyHome"
    static let emptyList = "tpt_EmptyList"
    static let cardBackdrop = "tpt_CardBackdrop"
    static let controlFace = "tpt_ControlFace"
    static let twistHero = "tpt_TwistHero"
    static let successMark = "tpt_SuccessMark"
    static let headerDecor = "tpt_HeaderDecor"
    static let panelBoard = "tpt_PanelBoard"
    static let letterBar = "tpt_LetterBar"
    static let dealStamp = "tpt_DealStamp"
}

enum LineupStatusInk {
    static func stamp(_ status: LineupStatus) -> String {
        switch status {
        case .idle: "IDLE"
        case .cued: "CUED"
        case .called: "CALLED"
        case .fault: "FAULT"
        }
    }
}

enum LineupCueInk {
    static func stamp(_ kind: CueKind) -> String {
        switch kind {
        case .artist: "ARTIST"
        case .title: "TITLE"
        }
    }
}

enum LineupCopy {
    static let crateShortHeadline = "Crate short."
    static let crateShortLine = "Save four works, then deal."

    static func fault(_ error: Error) -> String {
        guard let fault = error as? LineupFault else {
            return "Write failed. Deal or Undo again."
        }
        switch fault {
        case .alreadyCued:
            return "The line stays. Call the matching canvas."
        case .notCued:
            return "Deal a line first."
        case .alreadyCalled:
            return "Already called. Deal another, or Undo."
        case .unknownFace:
            return "That canvas is not hanging."
        case .faceIsDecoy:
            return "That canvas misses. The line stays."
        case .missOnTrue:
            return "Call the match. Do not miss it."
        case .faceSpent:
            return "Already dimmed."
        case .nothingToPeel:
            return "Nothing to Undo."
        case .emptyObject:
            return "No object ID."
        }
    }

    static func seek(_ fault: SeekFault) -> String {
        switch fault {
        case .cancelled:
            return "Search cancelled."
        case .missing:
            return "Search missed. Local shelf is hanging."
        case .transport:
            return "Search failed. Local shelf is hanging."
        case .malformed:
            return "Search could not be read. Local shelf is hanging."
        }
    }

    static func nextTap(_ status: LineupStatus) -> String {
        switch status {
        case .idle:
            return crateShortLine
        case .cued:
            return "Tap the matching canvas."
        case .called:
            return "Called. Deal another, or Undo."
        case .fault:
            return "Miss stays. Tap the true canvas."
        }
    }

    static let calledFile = "Called"
    static let missFile = "Misses"

    static func missSpeak(title: String, cue: Cue, day: String) -> String {
        "\(title). \(LineupCueInk.stamp(cue.kind)) \(cue.line). \(day)."
    }

    static func canvasSpeak(title: String?, artist: String?, hiding kind: CueKind) -> String {
        switch kind {
        case .artist:
            return title ?? "Canvas"
        case .title:
            return artist ?? "Canvas"
        }
    }
}

/// Role: Lineup. CallMark counts, FaultMark counts, daykeys, and the go clock go through NumberFormatter.
enum LineupFigures {
    static func whole(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func seconds(_ value: TimeInterval) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func score(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0%"
    }

    static func daykey(_ value: Int) -> String {
        var parts = DateComponents()
        parts.year = value / 10_000
        parts.month = (value / 100) % 100
        parts.day = value % 100
        guard let date = Calendar.current.date(from: parts) else {
            return whole(value)
        }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMMd")
        return formatter.string(from: date)
    }
}

extension View {
    func lineupHit() -> some View {
        frame(minWidth: LineupSpace.hit, minHeight: LineupSpace.hit)
            .contentShape(Rectangle())
    }

    func lineupPlate(_ radius: CGFloat = LineupRadius.card) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return self
            .background(LineupInk.Palette.surface, in: shape)
            .overlay(shape.stroke(LineupInk.Palette.ink.opacity(0.18), lineWidth: LineupSpace.rule))
    }

    @ViewBuilder
    func lineupTick(_ reduceMotion: Bool) -> some View {
        if reduceMotion {
            self
        } else {
            self.contentTransition(.numericText())
        }
    }

    func lineupKeyboardDone(focused: FocusState<Bool>.Binding) -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused.wrappedValue = false }
                    .font(LineupInk.font(.caption))
                    .foregroundStyle(LineupInk.Palette.ink)
                    .lineupHit()
                    .accessibilityLabel("Done")
            }
        }
    }

    func lineupSheetReveal(_ reduceMotion: Bool) -> some View {
        modifier(LineupSheetReveal(reduceMotion: reduceMotion))
    }

    func lineupSheetChrome() -> some View {
        self
            .presentationBackground(LineupInk.Palette.background)
            .presentationCornerRadius(LineupRadius.card)
            .presentationDragIndicator(.visible)
            .presentationDetents([.large])
    }
}

private struct LineupSheetReveal: ViewModifier {
    var reduceMotion: Bool
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .scaleEffect(reduceMotion ? 1 : (shown ? 1 : 0.96))
            .onAppear {
                withAnimation(LineupMotion.sheet(reduceMotion)) {
                    shown = true
                }
            }
    }
}

extension Image {
    @MainActor
    func lineupCutout(maxWidth: CGFloat, maxHeight: CGFloat) -> some View {
        self
            .resizable()
            .scaledToFit()
            .padding(LineupSpace.card)
            .frame(maxWidth: maxWidth, maxHeight: maxHeight, alignment: .leading)
            .background(
                LineupInk.Palette.surface,
                in: RoundedRectangle(cornerRadius: LineupRadius.card, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}
