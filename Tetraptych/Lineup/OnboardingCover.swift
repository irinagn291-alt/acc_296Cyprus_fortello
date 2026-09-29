import SwiftUI

/// Role: Lineup. One-shot cover. Three pages. Continue full width at the bottom. Skip writes defaults. Re-runnable from Settings.
struct OnboardingCover: View {
    var onSkip: () -> Void
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.dynamicTypeSize) private var axle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                if page < 2 {
                    Button("Skip", action: onSkip)
                        .font(LineupInk.font(.caption, axle: axle))
                        .foregroundStyle(LineupInk.Palette.ink)
                        .lineupHit()
                        .buttonStyle(GlyphChipStyle())
                        .accessibilityLabel("Skip onboarding")
                }
            }
            .padding(.horizontal, LineupSpace.outer)

            Group {
                switch page {
                case 0:
                    pageBody(
                        art: LineupArt.onboarding1,
                        headline: "Four canvases. One line.",
                        line: "Deal writes an artist line or a title line. Home is the lineup, not a gallery list."
                    )
                case 1:
                    pageBody(
                        art: LineupArt.onboarding2,
                        headline: "Call the matching canvas.",
                        line: "Tap the true canvas. A miss dims that canvas, strikes it, and keeps the line."
                    )
                default:
                    pageBody(
                        art: LineupArt.onboarding3,
                        headline: "Called works rest.",
                        line: "They leave the deal pool. Misses stay on Saved. Undo peels the latest mark."
                    )
                }
            }
            .id(page)
            .animation(LineupMotion.swap(reduceMotion), value: page)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            HStack(spacing: LineupSpace.gap) {
                ForEach(0 ..< 3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                        .fill(index == page ? LineupInk.Palette.ink : LineupInk.Palette.surface)
                        .frame(width: index == page ? LineupSpace.step(7) : LineupSpace.gap, height: LineupSpace.gap)
                        .overlay(
                            RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                                .stroke(LineupInk.Palette.ink.opacity(0.18), lineWidth: LineupSpace.rule)
                        )
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, LineupSpace.outer)
            .padding(.bottom, LineupSpace.chip)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page \(LineupFigures.whole(page + 1)) of \(LineupFigures.whole(3))")

            Button("Continue") {
                if page < 2 {
                    page += 1
                } else {
                    onFinish()
                }
            }
            .buttonStyle(DealDockStyle(tone: .deal, isLoading: false))
            .padding(.horizontal, LineupSpace.outer)
            .padding(.bottom, LineupSpace.outer)
        }
        .background(LineupInk.Palette.background.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    private func pageBody(art: String, headline: String, line: String) -> some View {
        VStack(alignment: .leading, spacing: LineupSpace.loose) {
            Image(art)
                .lineupCutout(maxWidth: .infinity, maxHeight: LineupSpace.step(72))
            Text(headline)
                .font(LineupInk.font(.display, axle: axle))
                .foregroundStyle(LineupInk.Palette.ink)
                .lineLimit(3)
            Text(line)
                .font(LineupInk.font(.body, axle: axle))
                .foregroundStyle(LineupInk.Palette.ink)
                .lineLimit(4)
            Spacer(minLength: LineupSpace.gap)
        }
        .padding(.horizontal, LineupSpace.outer)
        .padding(.top, LineupSpace.card)
    }
}
