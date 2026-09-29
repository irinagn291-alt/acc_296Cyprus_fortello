import SwiftUI
import UIKit

/// Role: Lineup. Settings Form. Collection credit, Undo, contact URL, re-run onboarding, confirmed resetAllData.
struct SettingsView: View {
    @Bindable var rail: LineupRail
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var axle
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                if rail.settingsIsEmpty {
                    Section {
                        Text("Crate empty.")
                            .font(LineupInk.font(.body, axle: axle))
                            .foregroundStyle(LineupInk.Palette.ink)
                        Text(LineupCopy.crateShortLine)
                            .font(LineupInk.font(.caption, axle: axle))
                            .foregroundStyle(LineupInk.Palette.ink)
                        Button("Explore") {
                            rail.present(.explore)
                        }
                        .buttonStyle(DealDockStyle(tone: .deal, isLoading: false))
                        .listRowInsets(
                            EdgeInsets(
                                top: LineupSpace.gap,
                                leading: LineupSpace.outer,
                                bottom: LineupSpace.gap,
                                trailing: LineupSpace.outer
                            )
                        )
                        .listRowBackground(LineupInk.Palette.background)
                    }
                } else {
                    Section {
                        countRow(title: "Calls", value: rail.pinacotheca.callMarks.count)
                        countRow(title: "Misses", value: rail.pinacotheca.reviewableFaults.count)
                    } header: {
                        Text("Crate")
                            .font(LineupInk.font(.caption, axle: axle))
                    }
                }

                if let fault = rail.hangFault {
                    Section {
                        Text(fault)
                            .font(LineupInk.font(.body, axle: axle))
                            .foregroundStyle(LineupInk.Palette.ink)
                    } header: {
                        Text("Write")
                            .font(LineupInk.font(.caption, axle: axle))
                    }
                }

                Section {
                    Button {
                        open(CatalogClient.metHomeURL)
                    } label: {
                        settingsRow(title: "The Metropolitan Museum of Art", detail: "metmuseum.org")
                    }
                    .buttonStyle(CrateRowStyle())
                    Button {
                        open(CatalogClient.metOpenAccessURL)
                    } label: {
                        settingsRow(title: "Open access", detail: "metmuseum.org/policies/open-access")
                    }
                    .buttonStyle(CrateRowStyle())
                } header: {
                    Text("Collection")
                        .font(LineupInk.font(.caption, axle: axle))
                } footer: {
                    Text("Public-domain works hang from The Metropolitan Museum of Art.")
                        .font(LineupInk.font(.micro, axle: axle))
                }

                Section {
                    Button {
                        open(CatalogClient.contactURL)
                    } label: {
                        settingsRow(title: "Contact", detail: "tetraptych-lineup.pro/contact-us")
                    }
                    .buttonStyle(CrateRowStyle())
                } header: {
                    Text("Support")
                        .font(LineupInk.font(.caption, axle: axle))
                }

                Section {
                    Button {
                        Task { await rail.peelLatestMark() }
                    } label: {
                        HStack {
                            Text("Undo")
                                .font(LineupInk.font(.body, axle: axle))
                                .foregroundStyle(LineupInk.Palette.ink)
                            Spacer()
                            if rail.peelBusy {
                                ProgressView()
                                    .tint(LineupInk.Palette.ink)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: LineupSpace.hit, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(CrateRowStyle())
                    .disabled(!rail.peelEnabled)
                    Button("Re-run onboarding") {
                        rail.replayOnboarding()
                    }
                    .font(LineupInk.font(.body, axle: axle))
                    .foregroundStyle(LineupInk.Palette.ink)
                    .frame(maxWidth: .infinity, minHeight: LineupSpace.hit, alignment: .leading)
                    .contentShape(Rectangle())
                    .buttonStyle(CrateRowStyle())
                } footer: {
                    Text("Undo peels the latest call or miss.")
                        .font(LineupInk.font(.micro, axle: axle))
                }

                Section {
                    Button("Reset the crate") {
                        confirmReset = true
                    }
                    .buttonStyle(DealDockStyle(tone: .wipe, isLoading: false))
                    .listRowInsets(
                        EdgeInsets(
                            top: LineupSpace.gap,
                            leading: LineupSpace.outer,
                            bottom: LineupSpace.gap,
                            trailing: LineupSpace.outer
                        )
                    )
                    .listRowBackground(LineupInk.Palette.background)
                    .accessibilityLabel("Reset the crate")
                    .accessibilityHint("Removes works and marks on this device.")
                } footer: {
                    Text("Reset removes the crate on this device.")
                        .font(LineupInk.font(.micro, axle: axle))
                }
            }
            .scrollContentBackground(.hidden)
            .background(LineupInk.Palette.background)
            .tint(LineupInk.Palette.accent)
            .navigationTitle("Settings")
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
            .alert("Reset the crate?", isPresented: $confirmReset) {
                Button("Keep", role: .cancel) {}
                Button("Reset the crate", role: .destructive) {
                    Task { await rail.resetAllData() }
                }
            } message: {
                Text("This removes works, calls, and misses on this device. It cannot be undone.")
            }
        }
        .preferredColorScheme(.light)
        .lineupSheetChrome()
    }

    private func countRow(title: String, value: Int) -> some View {
        HStack {
            Text(title)
                .font(LineupInk.font(.body, axle: axle))
                .foregroundStyle(LineupInk.Palette.ink)
                .lineLimit(1)
            Spacer(minLength: LineupSpace.gap)
            Text(LineupFigures.whole(value))
                .font(LineupInk.font(.headline, axle: axle))
                .foregroundStyle(LineupInk.Palette.ink)
                .monospacedDigit()
                .layoutPriority(1)
        }
        .frame(minHeight: LineupSpace.hit)
    }

    private func settingsRow(title: String, detail: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: LineupSpace.tight) {
                Text(title)
                    .font(LineupInk.font(.body, axle: axle))
                    .foregroundStyle(LineupInk.Palette.ink)
                Text(detail)
                    .font(LineupInk.font(.micro, axle: axle))
                    .foregroundStyle(LineupInk.Palette.muted)
            }
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(LineupInk.font(.caption, axle: axle))
                .foregroundStyle(LineupInk.Palette.muted)
                .accessibilityHidden(true)
        }
        .padding(.vertical, LineupSpace.tight)
        .contentShape(Rectangle())
        .lineupHit()
    }

    private func open(_ url: URL) {
        UIApplication.shared.open(url)
    }
}
