import SwiftUI

/// Role: Lineup. Full-page empty or error. Cutout, one headline, one line, bottom full-width CTA. Never a crumb in a Spacer.
struct CrateVacant: View {
    let art: String
    let headline: String
    let line: String
    let actionTitle: String
    var isLoading: Bool = false
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var axle

    var body: some View {
        VStack(alignment: .leading, spacing: LineupSpace.loose) {
            Image(art)
                .lineupCutout(maxWidth: LineupSpace.art, maxHeight: LineupSpace.art)
            Text(headline)
                .font(LineupInk.font(.display, axle: axle))
                .foregroundStyle(LineupInk.Palette.ink)
                .lineLimit(3)
            Text(line)
                .font(LineupInk.font(.body, axle: axle))
                .foregroundStyle(LineupInk.Palette.ink)
                .lineLimit(4)
            Spacer(minLength: LineupSpace.gap)
            Button(actionTitle, action: action)
                .buttonStyle(DealDockStyle(tone: .deal, isLoading: isLoading))
                .lineupHit()
        }
        .padding(.horizontal, LineupSpace.outer)
        .padding(.top, LineupSpace.card)
        .padding(.bottom, LineupSpace.outer)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(LineupInk.Palette.background)
    }
}
