import SwiftUI

/// Role: Cue. Billboard over the dense 2x2. One offset kind sticker. Clock stays on this plate.
struct CueBoard: View {
    let cue: Cue
    var nextTap: String
    var status: LineupStatus
    var looseCount: Int
    var goStamp: (Date) -> String
    var punctuality: Double?
    @Environment(\.dynamicTypeSize) private var axle
    @ScaledMetric(relativeTo: .body) private var stickerLift: CGFloat = LineupSpace.gap

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: LineupSpace.gap) {
                HStack(alignment: .top, spacing: LineupSpace.gap) {
                    Image(LineupArt.letterBar)
                        .resizable()
                        .scaledToFit()
                        .frame(width: LineupSpace.step(10), height: LineupSpace.step(10))
                        .accessibilityHidden(true)
                    Text(cue.line)
                        .font(LineupInk.font(.display, axle: axle))
                        .foregroundStyle(LineupInk.Palette.ink)
                        .lineLimit(axle >= .accessibility3 ? 4 : 3)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text(nextTap)
                    .font(LineupInk.font(.headline, axle: axle))
                    .foregroundStyle(LineupInk.Palette.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                metaRail
            }
            .padding(LineupSpace.card)
            .padding(.trailing, LineupSpace.step(10))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LineupInk.Palette.surface,
                in: RoundedRectangle(cornerRadius: LineupRadius.card, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LineupRadius.card, style: .continuous)
                    .stroke(LineupInk.Palette.ink.opacity(0.18), lineWidth: LineupSpace.rule)
            )

            Text(LineupCueInk.stamp(cue.kind))
                .font(LineupInk.font(.caption, axle: axle))
                .foregroundStyle(LineupInk.Palette.surface)
                .padding(.horizontal, LineupSpace.chip)
                .frame(minHeight: LineupSpace.hit)
                .background(
                    LineupInk.Palette.ink,
                    in: RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                        .stroke(LineupInk.Palette.ink, lineWidth: LineupSpace.rule)
                )
                .offset(x: stickerLift, y: -stickerLift)
                .accessibilityLabel(LineupCueInk.stamp(cue.kind))
        }
        .padding(.top, stickerLift)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(boardSpeak)
    }

    private var metaRail: some View {
        Group {
            if axle.isAccessibilitySize {
                VStack(alignment: .leading, spacing: LineupSpace.tight) {
                    Text(LineupStatusInk.stamp(status))
                    Text("LOOSE \(LineupFigures.whole(looseCount))")
                    TimelineView(.periodic(from: .now, by: 0.25)) { context in
                        Text(goStamp(context.date))
                    }
                    if let punctuality {
                        Text(LineupFigures.score(punctuality))
                    }
                }
                .font(LineupInk.font(.caption, axle: axle))
                .foregroundStyle(LineupInk.Palette.ink)
                .monospacedDigit()
            } else {
                HStack(alignment: .firstTextBaseline, spacing: LineupSpace.gap) {
                    Text(LineupStatusInk.stamp(status))
                        .foregroundStyle(LineupInk.Palette.ink)
                    Text("LOOSE \(LineupFigures.whole(looseCount))")
                        .foregroundStyle(LineupInk.Palette.muted)
                    Spacer(minLength: LineupSpace.tight)
                    TimelineView(.periodic(from: .now, by: 0.25)) { context in
                        Text(goStamp(context.date))
                    }
                    .foregroundStyle(LineupInk.Palette.ink)
                    if let punctuality {
                        Text(LineupFigures.score(punctuality))
                            .foregroundStyle(LineupInk.Palette.muted)
                    }
                }
                .font(LineupInk.font(.caption, axle: axle))
                .monospacedDigit()
                .lineLimit(1)
            }
        }
    }

    private var boardSpeak: String {
        let clock = goStamp(Date())
        return "\(LineupCueInk.stamp(cue.kind)). \(cue.line). \(nextTap). \(LineupStatusInk.stamp(status)). \(LineupFigures.whole(looseCount)) loose. Go clock \(clock)."
    }
}
