import SwiftUI

/// Role: Lineup. Corner ticks on the Quiz hero only. Internal grid is layout, not a second cross.
struct LineupBoard: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tick = min(rect.width, rect.height) * 0.08
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + tick))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + tick, y: rect.minY))
        path.move(to: CGPoint(x: rect.maxX - tick, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + tick))
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - tick))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + tick, y: rect.maxY))
        path.move(to: CGPoint(x: rect.maxX - tick, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - tick))
        return path
    }
}

struct FaceStrike: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let pad = min(rect.width, rect.height) * 0.12
        path.move(to: CGPoint(x: rect.minX + pad, y: rect.minY + pad))
        path.addLine(to: CGPoint(x: rect.maxX - pad, y: rect.maxY - pad))
        return path
    }
}

/// Role: Lineup. Dense 2x2 of four Face Buttons filling remaining height and the iPad width. Call fuses on the tiles.
struct LineupHero: View {
    let card: LineupCard
    let crate: Pinacotheca
    var busyID: UUID?
    var isCalled: Bool
    var showSuccess: Bool
    var callLive: Bool = false
    var onTap: (Face) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let rule = LineupSpace.heroRule
            let innerW = max(0, geo.size.width - rule * 2)
            let innerH = max(0, geo.size.height - rule * 2)
            let cellW = max(0, (innerW - rule) / 2)
            let cellH = max(0, (innerH - rule) / 2)
            let faces = card.faces
            ZStack {
                LineupInk.Palette.ink
                VStack(spacing: rule) {
                    HStack(spacing: rule) {
                        pane(at: 0, faces: faces, width: cellW, height: cellH)
                        pane(at: 1, faces: faces, width: cellW, height: cellH)
                    }
                    HStack(spacing: rule) {
                        pane(at: 2, faces: faces, width: cellW, height: cellH)
                        pane(at: 3, faces: faces, width: cellW, height: cellH)
                    }
                }
                .padding(rule)
                LineupBoard()
                    .stroke(LineupInk.Palette.ink, lineWidth: rule)
                    .allowsHitTesting(false)
                if showSuccess {
                    Image(LineupArt.successMark)
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(geo.size.width, geo.size.height) * 0.28)
                        .accessibilityHidden(true)
                        .transition(.opacity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(RoundedRectangle(cornerRadius: LineupRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LineupRadius.card, style: .continuous)
                    .stroke(LineupInk.Palette.ink, lineWidth: rule)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .layoutPriority(1)
        .animation(LineupMotion.swap(reduceMotion), value: showSuccess)
        .animation(LineupMotion.swap(reduceMotion), value: card.cue.workID)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Four canvases. Tap the match.")
    }

    @ViewBuilder
    private func pane(at index: Int, faces: [Face], width: CGFloat, height: CGFloat) -> some View {
        Group {
            if faces.indices.contains(index) {
                let face = faces[index]
                FaceTile(
                    face: face,
                    work: crate.works.first { $0.id == face.workID },
                    cueKind: card.cue.kind,
                    isCalled: isCalled,
                    isBusy: busyID == face.id,
                    callLive: callLive
                ) {
                    onTap(face)
                }
            } else {
                LineupInk.Palette.surface
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .contentShape(Rectangle())
    }
}
