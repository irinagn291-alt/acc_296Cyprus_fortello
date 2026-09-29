import SwiftUI

/// Role: Lineup. Locked Quiz. On a Cued hang the four Face Buttons are the only live primary. Deal docks after a Call.
struct QuizView: View {
    @Bindable var rail: LineupRail
    @Environment(\.dynamicTypeSize) private var axle
    @Environment(\.horizontalSizeClass) private var span
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if rail.quizIsEmpty {
                idlePage
            } else {
                populated
            }
        }
        .background(LineupInk.Palette.background.ignoresSafeArea())
        .sensoryFeedback(.success, trigger: rail.callPulse)
        .animation(LineupMotion.swap(reduceMotion), value: rail.pinacotheca.status)
        .animation(LineupMotion.swap(reduceMotion), value: rail.pinacotheca.lineup.trueWorkID)
        .safeAreaInset(edge: .bottom, spacing: LineupSpace.gap) {
            if showsDealDock {
                dock
            }
        }
        .sheet(item: $rail.cover) { cover in
            coverPage(cover)
                .lineupSheetReveal(reduceMotion)
        }
    }

    private var stacksChrome: Bool {
        axle.isAccessibilitySize || span == .compact
    }

    private var callLive: Bool {
        switch rail.pinacotheca.status {
        case .cued, .fault:
            return true
        case .idle, .called:
            return false
        }
    }

    private var showsDealDock: Bool {
        !rail.quizIsEmpty && !callLive && (rail.dealEnabled || rail.dealBusy || rail.pinacotheca.status == .called)
    }

    @ViewBuilder
    private func coverPage(_ cover: LineupCover) -> some View {
        switch cover {
        case .explore:
            ExploreView(rail: rail)
        case .saved:
            SavedView(rail: rail)
        case .settings:
            SettingsView(rail: rail)
        case .cueCall:
            CueCallSheet(rail: rail)
        }
    }

    private var idlePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            topChrome
                .padding(.horizontal, LineupSpace.outer)
                .padding(.top, LineupSpace.gap)
            CrateVacant(
                art: LineupArt.emptyHome,
                headline: rail.recoveredNotice ? "Crate could not be read." : LineupCopy.crateShortHeadline,
                line: rail.recoveredNotice
                    ? "Start a fresh crate. Save four works, then deal."
                    : LineupCopy.crateShortLine,
                actionTitle: "Explore"
            ) {
                rail.present(.explore)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: LineupSpace.gap) {
            topChrome
            if let fault = rail.hangFault {
                faultRule(fault)
            }
            if rail.recoveredNotice {
                recoverRule
            }
            if let card = rail.pinacotheca.lineup.card {
                CueBoard(
                    cue: card.cue,
                    nextTap: LineupCopy.nextTap(rail.pinacotheca.status),
                    status: rail.pinacotheca.status,
                    looseCount: rail.pinacotheca.loosePool.count,
                    goStamp: { rail.goStamp(at: $0) },
                    punctuality: rail.cueRun?.lastPunctuality
                )
                LineupHero(
                    card: card,
                    crate: rail.pinacotheca,
                    busyID: rail.faceBusy,
                    isCalled: rail.pinacotheca.status == .called,
                    showSuccess: rail.showSuccess,
                    callLive: callLive
                ) { face in
                    Task { await rail.tapFace(face) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
            }
        }
        .padding(.horizontal, LineupSpace.outer)
        .padding(.top, LineupSpace.tight)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var topChrome: some View {
        VStack(alignment: .leading, spacing: LineupSpace.gap) {
            if stacksChrome {
                jobStack
                sheetButtons
            } else {
                HStack(alignment: .center, spacing: LineupSpace.gap) {
                    jobStack
                    sheetButtons
                        .frame(maxWidth: LineupSpace.step(70), alignment: .trailing)
                }
            }
        }
    }

    private var jobStack: some View {
        HStack(alignment: .center, spacing: LineupSpace.gap) {
            Text("CALL THE LINEUP")
                .font(LineupInk.font(.caption, axle: axle))
                .foregroundStyle(LineupInk.Palette.muted)
                .lineLimit(1)
            Button("How to call") {
                rail.present(.cueCall)
            }
            .font(LineupInk.font(.micro, axle: axle))
            .foregroundStyle(LineupInk.Palette.ink)
            .padding(.horizontal, LineupSpace.chip)
            .frame(minHeight: LineupSpace.hit)
            .background(
                LineupInk.Palette.surface,
                in: RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                    .stroke(LineupInk.Palette.ink.opacity(0.18), lineWidth: LineupSpace.rule)
            )
            .contentShape(RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous))
            .buttonStyle(GlyphChipStyle())
            .accessibilityLabel("How to call")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Call the lineup. \(LineupCopy.nextTap(rail.pinacotheca.status))")
    }

    @ViewBuilder
    private var sheetButtons: some View {
        if axle.isAccessibilitySize {
            VStack(alignment: .leading, spacing: LineupSpace.gap) {
                destButton("Explore", flex: true) {
                    rail.present(.explore)
                }
                HStack(spacing: LineupSpace.gap) {
                    destButton("Saved", flex: true) {
                        rail.present(.saved)
                    }
                    destButton("Settings", flex: true) {
                        rail.present(.settings)
                    }
                }
            }
        } else {
            HStack(spacing: LineupSpace.gap) {
                destButton("Explore", flex: true) {
                    rail.present(.explore)
                }
                destButton("Saved", flex: false) {
                    rail.present(.saved)
                }
                destButton("Settings", flex: false) {
                    rail.present(.settings)
                }
            }
        }
    }

    private func destButton(_ title: String, flex: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(LineupInk.font(.caption, axle: axle))
                .foregroundStyle(LineupInk.Palette.ink)
                .padding(.horizontal, LineupSpace.card)
                .frame(maxWidth: flex ? .infinity : nil)
                .frame(minWidth: LineupSpace.hit, minHeight: LineupSpace.hit)
                .background(
                    LineupInk.Palette.surface,
                    in: RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                        .stroke(LineupInk.Palette.ink.opacity(0.18), lineWidth: LineupSpace.rule)
                )
                .contentShape(RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous))
        }
        .buttonStyle(GlyphChipStyle())
        .accessibilityLabel(title)
    }

    private var dock: some View {
        Group {
            if axle.isAccessibilitySize {
                VStack(alignment: .leading, spacing: LineupSpace.gap) {
                    peelControl
                    dealControl
                }
            } else {
                HStack(alignment: .center, spacing: LineupSpace.gap) {
                    peelControl
                        .frame(maxWidth: LineupSpace.step(22))
                    dealControl
                }
            }
        }
        .padding(LineupSpace.card)
        .lineupPlate()
        .padding(.horizontal, LineupSpace.outer)
        .padding(.bottom, LineupSpace.chip)
    }

    private var peelControl: some View {
        Button("Undo") {
            Task { await rail.peelLatestMark() }
        }
        .buttonStyle(DealDockStyle(tone: .undo, isLoading: rail.peelBusy))
        .disabled(!rail.peelEnabled)
        .accessibilityLabel("Undo")
        .accessibilityHint("Peels the latest call or miss.")
    }

    private var dealControl: some View {
        Button {
            Task { await rail.dealCue() }
        } label: {
            HStack(spacing: LineupSpace.gap) {
                Image(LineupArt.controlFace)
                    .resizable()
                    .scaledToFit()
                    .padding(LineupSpace.tight)
                    .frame(width: LineupSpace.step(8), height: LineupSpace.step(8))
                    .background(
                        LineupInk.Palette.surface,
                        in: RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                    )
                    .accessibilityHidden(true)
                Text("Deal")
                    .font(LineupInk.font(.headline, axle: axle))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(DealDockStyle(tone: .deal, isLoading: rail.dealBusy))
        .disabled(!rail.dealEnabled)
        .accessibilityLabel("Deal")
        .accessibilityHint(rail.dealEnabled ? "Writes a line and hangs four canvases." : "Needs four loose works, and refuses while a line is open.")
    }

    private func faultRule(_ fault: String) -> some View {
        Text(fault)
            .font(LineupInk.font(.caption, axle: axle))
            .foregroundStyle(LineupInk.Palette.ink)
            .padding(LineupSpace.chip)
            .frame(maxWidth: .infinity, minHeight: LineupSpace.hit, alignment: .leading)
            .lineupPlate()
            .accessibilityLabel(fault)
    }

    private var recoverRule: some View {
        Text("Crate recovered from backup.")
            .font(LineupInk.font(.micro, axle: axle))
            .foregroundStyle(LineupInk.Palette.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
