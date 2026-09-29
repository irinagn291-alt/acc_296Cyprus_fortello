import SwiftUI

/// Role: Lineup. Twist screen. Cue-then-call is the fold. Home already shows the billboard and the four-face board.
struct CueCallSheet: View {
    @Bindable var rail: LineupRail
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var axle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: LineupSpace.loose) {
                        Image(LineupArt.twistHero)
                            .lineupCutout(maxWidth: .infinity, maxHeight: LineupSpace.art)
                        Text("Read the line. Tap the match.")
                            .font(LineupInk.font(.display, axle: axle))
                            .foregroundStyle(LineupInk.Palette.ink)
                            .lineLimit(2)
                        Text("Deal writes an artist line or a title line and hangs four canvases. Tap the match. A miss dims that canvas and keeps the line.")
                            .font(LineupInk.font(.body, axle: axle))
                            .foregroundStyle(LineupInk.Palette.ink)
                            .lineLimit(6)
                        counts
                        statusPlate
                    }
                    .padding(.horizontal, LineupSpace.outer)
                    .padding(.top, LineupSpace.card)
                    .padding(.bottom, LineupSpace.card)
                }
                .scrollDismissesKeyboard(.interactively)
                Button {
                    dismiss()
                    if rail.pinacotheca.canDeal {
                        Task { await rail.dealCue() }
                    }
                } label: {
                    HStack(spacing: LineupSpace.gap) {
                        Image(LineupArt.dealStamp)
                            .resizable()
                            .scaledToFit()
                            .padding(LineupSpace.tight)
                            .frame(width: LineupSpace.step(8), height: LineupSpace.step(8))
                            .background(
                                LineupInk.Palette.surface,
                                in: RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                            )
                            .accessibilityHidden(true)
                        Text(rail.pinacotheca.canDeal ? "Deal" : "Call from Quiz")
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .buttonStyle(DealDockStyle(tone: .deal, isLoading: rail.dealBusy))
                .disabled(rail.pinacotheca.canDeal && !rail.dealEnabled)
                .lineupHit()
                .padding(.horizontal, LineupSpace.outer)
                .padding(.bottom, LineupSpace.outer)
            }
            .background(LineupInk.Palette.background)
            .navigationTitle("How to call")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(LineupInk.font(.headline, axle: axle))
                            .foregroundStyle(LineupInk.Palette.ink)
                            .lineupHit()
                    }
                    .buttonStyle(GlyphChipStyle())
                    .accessibilityLabel("Close")
                }
            }
        }
        .preferredColorScheme(.light)
        .lineupSheetChrome()
    }

    private var counts: some View {
        Group {
            if axle.isAccessibilitySize {
                VStack(alignment: .leading, spacing: LineupSpace.gap) {
                    countBlock(title: "CALLS", value: rail.pinacotheca.callMarks.count, step: .title)
                    countBlock(title: "FAULTS", value: rail.pinacotheca.reviewableFaults.count, step: .headline)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: LineupSpace.loose) {
                    countBlock(title: "CALLS", value: rail.pinacotheca.callMarks.count, step: .title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    countBlock(title: "FAULTS", value: rail.pinacotheca.reviewableFaults.count, step: .headline)
                        .frame(width: LineupSpace.step(22), alignment: .leading)
                }
            }
        }
        .padding(LineupSpace.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineupPlate()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(LineupFigures.whole(rail.pinacotheca.callMarks.count)) calls. \(LineupFigures.whole(rail.pinacotheca.reviewableFaults.count)) misses."
        )
    }

    private func countBlock(title: String, value: Int, step: LineupInk.Step) -> some View {
        VStack(alignment: .leading, spacing: LineupSpace.tight) {
            Text(title)
                .font(LineupInk.font(.micro, axle: axle))
                .foregroundStyle(LineupInk.Palette.muted)
            Text(LineupFigures.whole(value))
                .font(LineupInk.font(step, axle: axle))
                .foregroundStyle(LineupInk.Palette.ink)
                .monospacedDigit()
                .lineupTick(reduceMotion)
                .layoutPriority(1)
        }
    }

    private var statusPlate: some View {
        VStack(alignment: .leading, spacing: LineupSpace.gap) {
            Text(LineupStatusInk.stamp(rail.pinacotheca.status))
                .font(LineupInk.font(.caption, axle: axle))
                .foregroundStyle(LineupInk.Palette.surface)
                .padding(.horizontal, LineupSpace.chip)
                .frame(minHeight: LineupSpace.hit)
                .background(
                    LineupInk.Palette.ink,
                    in: RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                )
            Text(LineupCopy.nextTap(rail.pinacotheca.status))
                .font(LineupInk.font(.body, axle: axle))
                .foregroundStyle(LineupInk.Palette.ink)
                .lineLimit(3)
            if let score = rail.cueRun?.lastPunctuality {
                Text(LineupFigures.score(score))
                    .font(LineupInk.font(.caption, axle: axle))
                    .foregroundStyle(LineupInk.Palette.muted)
                    .monospacedDigit()
            }
        }
        .padding(LineupSpace.card)
        .frame(maxWidth: .infinity, minHeight: LineupSpace.step(28), alignment: .topLeading)
        .lineupPlate()
    }
}
