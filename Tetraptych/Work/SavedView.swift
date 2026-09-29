import SwiftUI

/// Role: Work. Saved sheet of Called works and FaultMarks. CallMarks file Called works, so they are not dumped twice.
struct SavedView: View {
    @Bindable var rail: LineupRail
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var axle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            Group {
                if rail.savedIsEmpty {
                    emptyPage
                } else if let fault = rail.hangFault,
                          rail.pinacotheca.calledWorks.isEmpty,
                          rail.pinacotheca.reviewableFaults.isEmpty {
                    CrateVacant(
                        art: LineupArt.emptyList,
                        headline: "Saved could not load.",
                        line: fault,
                        actionTitle: "Close"
                    ) {
                        dismiss()
                    }
                } else {
                    populated
                }
            }
            .background(LineupInk.Palette.background.ignoresSafeArea())
            .navigationTitle("Saved")
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

    private var emptyPage: some View {
        CrateVacant(
            art: LineupArt.emptyList,
            headline: "No calls filed.",
            line: "Deal a line, then tap the matching canvas.",
            actionTitle: "Deal"
        ) {
            dismiss()
            Task { await rail.dealCue() }
        }
    }

    private var populated: some View {
        GeometryReader { proxy in
            List {
                Section {
                    tally
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(LineupInk.Palette.background)
                        .listRowSeparator(.hidden)
                }
                if let fault = rail.hangFault {
                    Section {
                        Text(fault)
                            .font(LineupInk.font(.micro, axle: axle))
                            .foregroundStyle(LineupInk.Palette.ink)
                            .listRowBackground(LineupInk.Palette.surface)
                    }
                }
                if !rail.pinacotheca.calledWorks.isEmpty {
                    Section {
                        ForEach(rail.pinacotheca.calledWorks) { work in
                            calledRow(work)
                        }
                    } header: {
                        Text(LineupCopy.calledFile)
                            .font(LineupInk.font(.caption, axle: axle))
                            .foregroundStyle(LineupInk.Palette.muted)
                    }
                }
                if !rail.pinacotheca.reviewableFaults.isEmpty {
                    Section {
                        ForEach(rail.pinacotheca.reviewableFaults.reversed()) { mark in
                            faultRow(mark, floor: missFloor(in: proxy.size.height))
                        }
                    } header: {
                        Text(LineupCopy.missFile)
                            .font(LineupInk.font(.caption, axle: axle))
                            .foregroundStyle(LineupInk.Palette.muted)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, LineupSpace.outer)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func missFloor(in height: CGFloat) -> CGFloat {
        if axle.isAccessibilitySize {
            return LineupSpace.hit
        }
        let faults = CGFloat(max(rail.pinacotheca.reviewableFaults.count, 1))
        let called = CGFloat(rail.pinacotheca.calledWorks.count)
        let used =
            LineupSpace.step(28)
            + (rail.hangFault == nil ? 0 : LineupSpace.step(10))
            + LineupSpace.step(10)
            + called * LineupSpace.step(16)
            + LineupSpace.step(10)
            + LineupSpace.outer
        let share = (height - used) / faults
        return max(LineupSpace.step(24), share)
    }

    private var tally: some View {
        Group {
            if axle.isAccessibilitySize {
                VStack(alignment: .leading, spacing: LineupSpace.gap) {
                    callTally
                    faultTally
                }
            } else {
                HStack(alignment: .top, spacing: LineupSpace.gap) {
                    callTally
                    faultTally
                        .frame(width: LineupSpace.step(28), alignment: .leading)
                }
            }
        }
        .padding(.horizontal, LineupSpace.outer)
        .padding(.vertical, LineupSpace.gap)
        .animation(LineupMotion.swap(reduceMotion), value: rail.pinacotheca.callMarks.count)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(LineupFigures.whole(rail.pinacotheca.callMarks.count)) calls. \(LineupFigures.whole(rail.pinacotheca.reviewableFaults.count)) misses."
        )
    }

    private var callTally: some View {
        VStack(alignment: .leading, spacing: LineupSpace.tight) {
            Text("CALLS")
                .font(LineupInk.font(.micro, axle: axle))
                .foregroundStyle(LineupInk.Palette.muted)
            Text(LineupFigures.whole(rail.pinacotheca.callMarks.count))
                .font(LineupInk.font(.display, axle: axle))
                .foregroundStyle(LineupInk.Palette.ink)
                .monospacedDigit()
                .lineupTick(reduceMotion)
        }
        .padding(LineupSpace.card)
        .frame(maxWidth: .infinity, minHeight: LineupSpace.step(22), alignment: .leading)
        .lineupPlate()
    }

    private var faultTally: some View {
        VStack(alignment: .leading, spacing: LineupSpace.tight) {
            Text("FAULTS")
                .font(LineupInk.font(.micro, axle: axle))
                .foregroundStyle(LineupInk.Palette.muted)
            Text(LineupFigures.whole(rail.pinacotheca.reviewableFaults.count))
                .font(LineupInk.font(.title, axle: axle))
                .foregroundStyle(LineupInk.Palette.ink)
                .monospacedDigit()
                .lineupTick(reduceMotion)
        }
        .padding(LineupSpace.card)
        .frame(maxWidth: .infinity, minHeight: LineupSpace.step(22), alignment: .leading)
        .lineupPlate()
    }

    private func calledRow(_ work: Work) -> some View {
        VStack(alignment: .leading, spacing: LineupSpace.tight) {
            Text(work.title)
                .font(LineupInk.font(.body, axle: axle))
                .foregroundStyle(LineupInk.Palette.ink)
                .lineLimit(2)
            HStack {
                Text(work.artist)
                    .font(LineupInk.font(.caption, axle: axle))
                    .foregroundStyle(LineupInk.Palette.ink)
                    .lineLimit(1)
                Spacer(minLength: LineupSpace.gap)
                Text(LineupFigures.daykey(work.daykey))
                    .font(LineupInk.font(.micro, axle: axle))
                    .foregroundStyle(LineupInk.Palette.muted)
                    .monospacedDigit()
                    .lineLimit(1)
                    .layoutPriority(1)
            }
        }
        .padding(.vertical, LineupSpace.tight)
        .frame(maxWidth: .infinity, minHeight: LineupSpace.hit, alignment: .leading)
        .listRowBackground(LineupInk.Palette.surface)
        .listRowSeparatorTint(LineupInk.Palette.muted.opacity(0.35))
        .accessibilityElement(children: .combine)
    }

    private func faultRow(_ mark: FaultMark, floor: CGFloat) -> some View {
        let work = rail.pinacotheca.work(mark.workID)
        let title = work?.title ?? mark.cue.line
        let day = LineupFigures.daykey(mark.daykey)
        return HStack(alignment: .top, spacing: LineupSpace.gap) {
            FaceRemotePane(url: work?.imageURL)
                .frame(width: LineupSpace.step(18), height: LineupSpace.step(18))
                .clipShape(RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                        .stroke(LineupInk.Palette.ink.opacity(0.18), lineWidth: LineupSpace.rule)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: LineupSpace.tight) {
                HStack(alignment: .firstTextBaseline, spacing: LineupSpace.gap) {
                    Text(title)
                        .font(LineupInk.font(.body, axle: axle))
                        .foregroundStyle(LineupInk.Palette.ink)
                        .lineLimit(2)
                    Spacer(minLength: LineupSpace.gap)
                    Text(day)
                        .font(LineupInk.font(.micro, axle: axle))
                        .foregroundStyle(LineupInk.Palette.muted)
                        .monospacedDigit()
                        .lineLimit(1)
                        .layoutPriority(1)
                }
                Text(LineupCueInk.stamp(mark.cue.kind))
                    .font(LineupInk.font(.caption, axle: axle))
                    .foregroundStyle(LineupInk.Palette.ink)
                Text(mark.cue.line)
                    .font(LineupInk.font(.title, axle: axle))
                    .foregroundStyle(LineupInk.Palette.ink)
                    .lineLimit(axle >= .accessibility3 ? 4 : 3)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(LineupSpace.card)
        .frame(maxWidth: .infinity, minHeight: floor, alignment: .topLeading)
        .lineupPlate()
        .listRowInsets(
            EdgeInsets(
                top: LineupSpace.tight,
                leading: LineupSpace.outer,
                bottom: LineupSpace.tight,
                trailing: LineupSpace.outer
            )
        )
        .listRowBackground(LineupInk.Palette.background)
        .listRowSeparator(.hidden)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(LineupCopy.missSpeak(title: title, cue: mark.cue, day: day))
    }
}
