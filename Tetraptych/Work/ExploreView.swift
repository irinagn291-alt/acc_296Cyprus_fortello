import SwiftUI

/// Role: Work. Explore sheet. Met search writes a Loose Work. Local crate shelf when query is empty or search fails.
struct ExploreView: View {
    @Bindable var rail: LineupRail
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var axle
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if rail.exploreIsEmpty, rail.seekFault != nil {
                    errorPage
                } else if rail.exploreIsEmpty {
                    emptyPage
                } else {
                    populated
                }
            }
            .background(LineupInk.Palette.background.ignoresSafeArea())
            .navigationTitle("Explore")
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
            .safeAreaInset(edge: .top, spacing: LineupSpace.gap) {
                searchField
            }
            .lineupKeyboardDone(focused: $searchFocused)
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(TapGesture().onEnded { searchFocused = false })
        }
        .preferredColorScheme(.light)
        .lineupSheetChrome()
        .task {
            if rail.seekHits.isEmpty {
                rail.scheduleSeek()
            }
        }
    }

    private var searchField: some View {
        VStack(alignment: .leading, spacing: LineupSpace.tight) {
            Text("THE METROPOLITAN MUSEUM OF ART")
                .font(LineupInk.font(.micro, axle: axle))
                .foregroundStyle(LineupInk.Palette.muted)
                .padding(.horizontal, LineupSpace.outer)
            HStack(spacing: LineupSpace.gap) {
                TextField("Search a work", text: $rail.query)
                    .font(LineupInk.font(.body, axle: axle))
                    .foregroundStyle(LineupInk.Palette.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .onChange(of: rail.query) { _, _ in
                        rail.scheduleSeek()
                    }
                    .onSubmit {
                        searchFocused = false
                    }
                if rail.isSeeking {
                    ProgressView()
                        .tint(LineupInk.Palette.ink)
                        .frame(width: LineupSpace.hit, height: LineupSpace.hit)
                }
            }
            .padding(LineupSpace.card)
            .frame(minHeight: LineupSpace.hit)
            .lineupPlate()
            .padding(.horizontal, LineupSpace.outer)
            if let note = rail.stockNote {
                Text(note)
                    .font(LineupInk.font(.micro, axle: axle))
                    .foregroundStyle(LineupInk.Palette.ink)
                    .padding(.horizontal, LineupSpace.outer)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let fault = rail.seekFault, !rail.seekHits.isEmpty {
                Text(fault)
                    .font(LineupInk.font(.micro, axle: axle))
                    .foregroundStyle(LineupInk.Palette.ink)
                    .padding(LineupSpace.chip)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineupPlate()
                    .padding(.horizontal, LineupSpace.outer)
            }
        }
        .padding(.bottom, LineupSpace.gap)
        .background(LineupInk.Palette.background)
    }

    private var populated: some View {
        List {
            Section {
                ForEach(rail.seekHits) { row in
                    Button {
                        searchFocused = false
                        Task { await rail.stockLoose(row) }
                    } label: {
                        HStack(alignment: .center, spacing: LineupSpace.gap) {
                            VStack(alignment: .leading, spacing: LineupSpace.tight) {
                                Text(row.title)
                                    .font(LineupInk.font(.body, axle: axle))
                                    .foregroundStyle(LineupInk.Palette.ink)
                                    .lineLimit(2)
                                Text(row.artist)
                                    .font(LineupInk.font(.caption, axle: axle))
                                    .foregroundStyle(LineupInk.Palette.ink)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: LineupSpace.gap)
                            saveMark(for: row)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(CrateRowStyle())
                    .disabled(rail.stockingObjectID != nil)
                    .listRowBackground(LineupInk.Palette.surface)
                    .listRowSeparatorTint(LineupInk.Palette.muted.opacity(0.35))
                    .listRowInsets(
                        EdgeInsets(
                            top: LineupSpace.gap,
                            leading: LineupSpace.outer,
                            bottom: LineupSpace.gap,
                            trailing: LineupSpace.outer
                        )
                    )
                    .accessibilityLabel("\(row.title), \(row.artist)")
                    .accessibilityHint("Saves this work as Loose.")
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, LineupSpace.outer)
    }

    @ViewBuilder
    private func saveMark(for row: CatalogRow) -> some View {
        if rail.stockingObjectID == row.objectID {
            ProgressView()
                .tint(LineupInk.Palette.surface)
                .frame(width: LineupSpace.hit, height: LineupSpace.hit)
                .background(
                    LineupInk.Palette.accent,
                    in: RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                )
        } else {
            Text("Save")
                .font(LineupInk.font(.caption, axle: axle))
                .foregroundStyle(LineupInk.Palette.surface)
                .padding(.horizontal, LineupSpace.chip)
                .frame(minWidth: LineupSpace.hit, minHeight: LineupSpace.hit)
                .background(
                    LineupInk.Palette.accent,
                    in: RoundedRectangle(cornerRadius: LineupRadius.chip, style: .continuous)
                )
        }
    }

    private var emptyPage: some View {
        CrateVacant(
            art: LineupArt.emptyList,
            headline: "Shelf quiet.",
            line: "Search the Met, or save from the local shelf.",
            actionTitle: "Show shelf"
        ) {
            rail.query = ""
            rail.scheduleSeek()
        }
    }

    private var errorPage: some View {
        CrateVacant(
            art: LineupArt.emptyList,
            headline: "Search failed.",
            line: rail.seekFault ?? "Try again, or save from the local shelf.",
            actionTitle: "Retry"
        ) {
            rail.scheduleSeek()
        }
    }
}
