import SwiftUI

/// Role: Lineup. Primary Deal. Default, pressed, disabled, and loading. resetAllData uses the wipe tone, not accent.
struct DealDockStyle: ButtonStyle {
    enum Tone {
        case deal
        case undo
        case wipe
    }

    var tone: Tone = .deal
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        DealDockBody(configuration: configuration, tone: tone, isLoading: isLoading)
    }
}

private struct DealDockBody: View {
    let configuration: ButtonStyle.Configuration
    let tone: DealDockStyle.Tone
    let isLoading: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.dynamicTypeSize) private var axle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed
        HStack(spacing: LineupSpace.tight) {
            if isLoading {
                ProgressView()
                    .tint(labelInk)
            }
            configuration.label
        }
        .font(LineupInk.font(.headline, axle: axle))
        .foregroundStyle(labelInk)
        .frame(maxWidth: .infinity)
        .frame(minHeight: LineupSpace.hit)
        .padding(.horizontal, LineupSpace.card)
        .background(fill, in: RoundedRectangle(cornerRadius: LineupRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LineupRadius.card, style: .continuous)
                .stroke(border, lineWidth: borderWidth)
        )
        .contentShape(RoundedRectangle(cornerRadius: LineupRadius.card, style: .continuous))
        .scaleEffect(pressed && isEnabled && !reduceMotion ? 0.97 : 1)
        .opacity(visualOpacity(pressed: pressed))
        .animation(LineupMotion.swap(reduceMotion), value: pressed)
        .animation(LineupMotion.swap(reduceMotion), value: isEnabled)
        .animation(LineupMotion.swap(reduceMotion), value: isLoading)
        .animation(LineupMotion.swap(reduceMotion), value: isFocused)
    }

    private var fill: Color {
        switch tone {
        case .deal: LineupInk.Palette.accent
        case .undo: LineupInk.Palette.surface
        case .wipe: LineupInk.Palette.ink
        }
    }

    private var labelInk: Color {
        switch tone {
        case .deal: LineupInk.Palette.surface
        case .undo: LineupInk.Palette.ink
        case .wipe: LineupInk.Palette.surface
        }
    }

    private var border: Color {
        if isFocused { return LineupInk.Palette.ink }
        switch tone {
        case .deal: return LineupInk.Palette.ink
        case .undo: return LineupInk.Palette.ink.opacity(0.18)
        case .wipe: return LineupInk.Palette.ink
        }
    }

    private var borderWidth: CGFloat {
        if isFocused { return 2 }
        switch tone {
        case .deal: return 2
        case .undo: return LineupSpace.rule
        case .wipe: return 2
        }
    }

    private func visualOpacity(pressed: Bool) -> Double {
        if !isEnabled { return 0.42 }
        if isLoading { return 0.7 }
        if pressed { return 0.88 }
        return 1
    }
}

/// Role: Lineup. Whole-chrome Face. Covers default, pressed, focused, disabled, selected, live call, and miss.
struct FaceTileStyle: ButtonStyle {
    var isTrue: Bool
    var isMiss: Bool
    var isBusy: Bool
    var isCalled: Bool
    var isLive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        FaceTileBody(
            configuration: configuration,
            isTrue: isTrue,
            isMiss: isMiss,
            isBusy: isBusy,
            isCalled: isCalled,
            isLive: isLive
        )
    }
}

private struct FaceTileBody: View {
    let configuration: ButtonStyle.Configuration
    let isTrue: Bool
    let isMiss: Bool
    let isBusy: Bool
    let isCalled: Bool
    let isLive: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .overlay(alignment: .topTrailing) {
                if isBusy {
                    ProgressView()
                        .tint(LineupInk.Palette.ink)
                        .padding(LineupSpace.tight)
                }
            }
            .overlay {
                if strokeWidth > 0 {
                    Rectangle()
                        .strokeBorder(stroke, lineWidth: strokeWidth)
                }
            }
            .contentShape(Rectangle())
            .scaleEffect(pressed && isEnabled && !reduceMotion ? 0.97 : 1)
            .opacity(tileOpacity(pressed: pressed))
            .animation(LineupMotion.swap(reduceMotion), value: pressed)
            .animation(LineupMotion.swap(reduceMotion), value: isMiss)
            .animation(LineupMotion.swap(reduceMotion), value: isCalled)
            .animation(LineupMotion.swap(reduceMotion), value: isFocused)
            .animation(LineupMotion.swap(reduceMotion), value: isEnabled)
            .animation(LineupMotion.swap(reduceMotion), value: isLive)
    }

    private var stroke: Color {
        if isFocused { return LineupInk.Palette.ink }
        if isCalled && isTrue { return LineupInk.Palette.accent }
        if isLive { return LineupInk.Palette.accent }
        if isMiss { return LineupInk.Palette.ink }
        return LineupInk.Palette.ink.opacity(0)
    }

    private var strokeWidth: CGFloat {
        if isFocused || (isCalled && isTrue) || isLive { return LineupSpace.heroRule }
        if isMiss { return LineupSpace.rule }
        return 0
    }

    private func tileOpacity(pressed: Bool) -> Double {
        if isMiss { return 0.42 }
        if !isEnabled { return 0.55 }
        if pressed { return 0.88 }
        return 1
    }
}

/// Role: Lineup. Pressed chrome for icon-only sheet controls. VoiceOver labels live on the Button.
struct GlyphChipStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        GlyphChipBody(configuration: configuration)
    }
}

private struct GlyphChipBody: View {
    let configuration: ButtonStyle.Configuration
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                    .stroke(LineupInk.Palette.ink, lineWidth: isFocused ? 2 : 0)
            )
            .scaleEffect(pressed && isEnabled && !reduceMotion ? 0.97 : 1)
            .opacity(glyphOpacity(pressed: pressed))
            .animation(LineupMotion.swap(reduceMotion), value: pressed)
            .animation(LineupMotion.swap(reduceMotion), value: isEnabled)
            .animation(LineupMotion.swap(reduceMotion), value: isFocused)
    }

    private func glyphOpacity(pressed: Bool) -> Double {
        if !isEnabled { return 0.42 }
        if pressed { return 0.88 }
        return 1
    }
}

/// Role: Lineup. Pressed row for Explore crate and Form rows.
struct CrateRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        CrateRowBody(configuration: configuration)
    }
}

private struct CrateRowBody: View {
    let configuration: ButtonStyle.Configuration
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed
        configuration.label
            .scaleEffect(pressed && isEnabled && !reduceMotion ? 0.97 : 1)
            .opacity(!isEnabled ? 0.55 : (pressed ? 0.88 : 1))
            .animation(LineupMotion.swap(reduceMotion), value: pressed)
            .animation(LineupMotion.swap(reduceMotion), value: isEnabled)
    }
}
