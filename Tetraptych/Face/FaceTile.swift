import SwiftUI

/// Role: Face. One hanging canvas Button in the Quiz hero. The painting fills the cell. Miss dims and strikes. Colour is never the only miss signal.
struct FaceTile: View {
    let face: Face
    let work: Work?
    var cueKind: CueKind
    var isCalled: Bool
    var isBusy: Bool
    var callLive: Bool = false
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var axle

    var body: some View {
        Button(action: action) {
            Text("Call")
                .font(LineupInk.font(.body, axle: axle))
                .foregroundStyle(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    FaceRemotePane(url: work?.imageURL)
                        .allowsHitTesting(false)
                }
                .overlay {
                    if face.isStruck || face.isDimmed {
                        ZStack {
                            LineupInk.Palette.surface.opacity(0.45)
                            FaceStrike()
                                .stroke(LineupInk.Palette.ink, lineWidth: LineupSpace.heroRule)
                            Text("MISS")
                                .font(LineupInk.font(.caption, axle: axle))
                                .foregroundStyle(LineupInk.Palette.ink)
                                .padding(.horizontal, LineupSpace.chip)
                                .frame(minHeight: LineupSpace.hit)
                                .background(
                                    LineupInk.Palette.surface,
                                    in: RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                                        .stroke(LineupInk.Palette.ink, lineWidth: LineupSpace.rule)
                                )
                        }
                        .allowsHitTesting(false)
                    }
                }
                .clipped()
                .contentShape(Rectangle())
        }
        .buttonStyle(
            FaceTileStyle(
                isTrue: face.isTrue,
                isMiss: face.isDimmed,
                isBusy: isBusy,
                isCalled: isCalled && face.isTrue,
                isLive: callLive && !isCalled && !face.isDimmed
            )
        )
        .disabled(isCalled || face.isDimmed)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .accessibilityLabel(label)
        .accessibilityHint(face.isDimmed ? "Missed. Dimmed." : "Call this canvas if it matches the written line.")
        .accessibilityAddTraits(.isButton)
    }

    private var label: String {
        let spoken: String
        if isCalled {
            let title = work?.title ?? "Unknown work"
            let artist = work?.artist ?? "Unknown artist"
            spoken = "\(title) by \(artist)"
        } else {
            spoken = LineupCopy.canvasSpeak(title: work?.title, artist: work?.artist, hiding: cueKind)
        }
        if face.isDimmed {
            return "Missed canvas. \(spoken)."
        }
        if isCalled && face.isTrue {
            return "Called canvas. \(spoken)."
        }
        return spoken
    }
}

/// Role: Face. Remote pane for a Face tile. Spinner waits 150 ms. The painting fills the proposed cell.
struct FaceRemotePane: View {
    let url: URL?
    @State private var showSpin = false

    var body: some View {
        Color.clear
            .overlay {
                pane
            }
            .clipped()
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var pane: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    FacePlate()
                case .empty:
                    LineupInk.Palette.surface
                        .overlay {
                            if showSpin {
                                ProgressView()
                                    .tint(LineupInk.Palette.ink)
                            }
                        }
                        .task(id: url) {
                            showSpin = false
                            try? await Task.sleep(for: .milliseconds(150))
                            if !Task.isCancelled {
                                showSpin = true
                            }
                        }
                @unknown default:
                    FacePlate()
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .clipped()
        } else {
            FacePlate()
        }
    }
}

private struct FacePlate: View {
    var body: some View {
        Image(LineupArt.panelBoard)
            .resizable()
            .scaledToFill()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .clipped()
            .accessibilityHidden(true)
    }
}
