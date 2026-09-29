# Tetraptych

Tap the canvas that matches the written cue.

Tetraptych is for people who remember an artist name or a title and want to find that face among works they already saved. It is not a museum browser, and it is not a one-easel name-the-hanging-work drill.

## Architecture

Lineup is a closed algebraic fold: `Idle`, `Cued`, or `Called`. A fourth case is a defect.

The pinacotheca is a fold over Works. `dealCue()` samples a Work that is not Called, writes one Cue as Artist or as Title (never both), and hangs four Faces, one true and three Loose decoys. Deal on a crate under four Loose Works writes Idle. A second Deal while Cued is refused.

- A matching Call writes a `CallMark`, files that Work as Called so it leaves the deal pool, and folds Cued to Called.
- A miss writes a `FaultMark`, dims that Face, and keeps the Cue.
- `peelLatestMark()` peels the newest CallMark or FaultMark. A CallMark returns that Work to Loose and folds Called back to Cued with the same Cue and Faces. A FaultMark undims that Face.

This pattern fits the product because the job is one written line and four hanging faces, not a catalog of records. One observable `LineupStore` pattern-matches the fold. Views call `dealCue`, `callFace`, `missFace`, and `peelLatestMark` and never keep a second lineup enum. Persistence is a Codable `PinacothecaDocument` in UserDefaults plus an atomic Application Support file. Memory is the source of truth.

## Cue then call

Cue-then-call is why someone picks this app. Home is the locked four-face lineup. Deal writes a Cue as Artist or Title and hangs four Faces from Loose Works. The learner taps the matching Face so a CallMark files that Work as Called. A wrong tap writes a FaultMark, dims that Face, and the Cue stays so the lineup does not advance.

Called works rest on Saved and exit the deal pool. FaultMarks stay reviewable there. Undo lifts the latest CallMark or FaultMark from the dock. Explore only stocks Loose works from The Metropolitan Museum of Art or the local crate shelf.

The twist is visible on Quiz (billboard, 2x2 Faces, Deal and Undo) and has its own Cue then call sheet.

## Navigation

Quiz is the locked lineup and never leaves. Explore, Saved, and Settings arrive as sheets. Four destinations, never a three-tab bar. App Intents and `tetraptych://quiz|explore|saved|settings` (plus `https://tetraptych-lineup.pro` paths) open those jobs or fire Deal in place. Contact lives on Settings at https://tetraptych-lineup.pro/contact-us.

## Design

Chartreuse bold accent. Light. SF Pro. Neobrutal thick-frame: Cue billboard with one offset ARTIST or TITLE sticker, raw 2x2 grid, thick rule on the lineup hero. Snap motion: press scale 0.97 in 160 ms ease-out. Sheets scale 0.96 to 1 plus fade. Reduce Motion is opacity only. Tokens live behind `LineupInk` (colour, type) and `LineupSpace` / `LineupRadius` (space, radius 12 / 8, hairline plus fill).

Named colours: background `#FAF8F5`, surface `#FEFEFD`, ink `#392A18`, accent `#C8781E`, muted `#7E6F5D`.

## Art

Style: 3D glass render, glassmorphism, studio-lit tetraptych of four hanging faces. Base prompt reused for every asset:

```
3D glass render, glassmorphism, studio-lit tetraptych of four hanging faces, refractive panes and soft bloom, isolated subjects, quiet uncluttered ground, no text, no letters, no logo, no photoreal stock, no specified colours, four faces in one lineup not a single easel and not a museum corridor
```

| Image set | Prompt |
| --- | --- |
| `tpt_AppIcon` | A single 3D glass tetraptych of four square panes in a tight 2x2, glassmorphism, subject centred filling the canvas edge to edge, no text, no letters, no words, no alpha, no transparency, no rounded corners, no drop shadow outside the canvas |
| `tpt_Splash` | A tall vertical 3D glass lineup of four hanging panes, quiet uncluttered centre band for a wordmark, glassmorphism, no readable text |
| `tpt_Onboarding1` | Solid painted 2x2 panel board, four opaque canvases as one object, the product in one glance, isolated cutout, opaque paint and wood in the center, transparent corners, no glass box, no text |
| `tpt_Onboarding2` | A hand tapping one solid painted panel in a four-face board under a solid letter bar, isolated cutout, opaque subject in the center, no hollow frame, no text |
| `tpt_Onboarding3` | A small stack of solid called panels on a crate shelf, meaning accumulated, isolated cutout, opaque wood and paint, no text |
| `tpt_EmptyHome` | A solid empty wooden crate with no canvases, waiting, calm and inviting, never sad, isolated cutout, opaque wood in the center, no hollow glass, no text |
| `tpt_EmptyList` | A solid empty crate shelf with no panels, calm, isolated cutout, opaque wood, no text |
| `tpt_CardBackdrop` | Abstract low-contrast 3D frosted glass lineup bloom, quiet enough for text on top, filling the canvas, no letters |
| `tpt_ControlFace` | The face of a small solid rubber deal stamp as a physical control, isolated cutout, opaque rubber, no text |
| `tpt_TwistHero` | Solid four-panel tetraptych board beside a letter bar, cue-then-call emblem, isolated cutout, opaque painted panels, no hollow glass, no text |
| `tpt_SuccessMark` | A small solid rubber stamp seated on a painted panel after a true call, confirmation not fireworks, isolated cutout, no letters |
| `tpt_HeaderDecor` | A wide low solid stretcher bar with four taped panel edges, isolated cutout, opaque wood and cloth in the center, transparent corners, no glass pane, no readable text |
| `tpt_PanelBoard` | Isolated solid 2x2 painted panel board, cutout, transparent corners, opaque paint and wood filling the center, no plate, no hollow frame, no text |
| `tpt_LetterBar` | Isolated solid painted letter bar, cutout, opaque wood, transparent corners, no plate, no readable letters, no text |
| `tpt_DealStamp` | Isolated solid rubber deal stamp, cutout, opaque rubber, transparent corners, no plate, no text |

## Why this is not a repeat

Cartellino sits one hanging work and names it with artist chips then title chips. This app inverts that tap: the cue is a written artist line or a written title line, and the learner picks one face among four. Home is a lime athletic lineup with a billboard cue and a dock, not a charcoal easel. Called is a single-field file. FaultMarks replace sequential miss-and-keep-the-same-work naming. The Met is the collection voice, not the Art Institute of Chicago. There is no shop, no stars, no shopping list, no Game tab, and no WebView museum.

## Build

```bash
cd Tetraptych
xcodegen generate
xcodebuild build-for-testing -scheme Tetraptych -destination 'generic/platform=iOS Simulator'
xcodebuild -scheme Tetraptych -destination 'generic/platform=iOS' build
```

Simulator seed (`tpt.demo.v1`) stores six Loose Works, deals so four Faces already hang, files CallMarks and FaultMarks so Saved is a used product, and marks onboarding complete. Never seeds on a device. `-ReviewScreen today|log|goals|explore` open Quiz, Saved, Settings, and Explore after onboarding.
