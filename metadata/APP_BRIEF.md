<!-- gf-brief source=e158078544713b723a33e84264851e23ea59601a0f974bda37f5771a8fc159de written=2026-09-30T01:29:50+03:00 -->
# Fortello

## What it is
Fortello is a four-canvas art lineup. You deal one written line — an artist name or a work title — then tap the painting that matches it among four hanging canvases. It is for people who want a short, on-device quiz using public-domain works from The Metropolitan Museum of Art.

## Launch and onboarding
After the icon is tapped, the screen may stay empty for a few seconds. Wait. A full-screen splash illustration then appears. It has no text and no buttons. Appearance is light.

If onboarding has not been finished, three pages follow. Page dots are VoiceOver-only as **"Page 1 of 3"**, **"Page 2 of 3"**, and **"Page 3 of 3"**.

1. Headline **"Four canvases. One line."** Body **"Deal writes an artist line or a title line. Home is the lineup, not a gallery list."** Top-right **"Skip"** (VoiceOver **"Skip onboarding"**) finishes onboarding and goes to home. Bottom **"Continue"** goes to page 2.
2. Headline **"Call the matching canvas."** Body **"Tap the true canvas. A miss dims that canvas, strikes it, and keeps the line."** **"Skip"** and **"Continue"** work the same way. **"Continue"** goes to page 3.
3. Headline **"Called works rest."** Body **"They leave the deal pool. Misses stay on Saved. Undo peels the latest mark."** There is no **"Skip"**. **"Continue"** finishes onboarding and opens home.

On a later launch, if onboarding was already finished, splash leads straight to home. The crate, an open line, calls, misses, Undo order, and the onboarding-finished flag persist on this device, so an unfinished lineup comes back as you left it.

## Screens

### Home (no tab bar)
There is no tab bar. Home is the lineup. The top label is **"CALL THE LINEUP"**.

Always on this screen:
- **"How to call"** opens the How to call sheet.
- **"Explore"** opens the Explore sheet.
- **"Saved"** opens the Saved sheet.
- **"Settings"** opens the Settings sheet.

**Empty home (no open line).** This page shows whenever there is no open or just-called line, even if Loose works are already saved. Headline **"Crate short."** Body **"Save four works, then deal."** Full-width **"Explore"** opens Explore. There is no **"Deal"** on this empty page.

If the crate could not be read, the empty page instead shows **"Crate could not be read."** / **"Start a fresh crate. Save four works, then deal."** / **"Explore"**.

**Open or just-called line.** A billboard sits above a 2×2 of four canvases.

On the billboard:
- A kind stamp, either **"ARTIST"** or **"TITLE"**.
- The written line itself (the artist’s name, or the work’s title). Never both at once.
- A next-tap line that changes with status:
  - **"Tap the matching canvas."** when the status is **"CUED"**
  - **"Miss stays. Tap the true canvas."** when the status is **"FAULT"**
  - **"Called. Deal another, or Undo."** when the status is **"CALLED"**
  - **"Save four works, then deal."** when the status is **"IDLE"**
- Status stamp **"IDLE"**, **"CUED"**, **"CALLED"**, or **"FAULT"**
- **"LOOSE"** plus the count of loose works still in the deal pool
- A go clock: a countdown in tenths of a second, then **"GO"**, while a line is open (**"CUED"** or **"FAULT"**); **"HOLD"** when it is not
- After a correct call, a punctuality percent on this plate (device locale)

The four canvases are paintings. They show no title or artist type on the tile. Tapping a canvas is the call. VoiceOver names the canvas by the field that is not written on the line (title when the stamp is **"ARTIST"**, artist when the stamp is **"TITLE"**). A miss dims that canvas, draws a strike, and stamps **"MISS"** on it; that canvas will not take another tap. The line stays until the matching canvas is tapped. After a correct call, a success mark flashes on the board with no text; the matching canvas stays as the called canvas.

While the status is **"CUED"** or **"FAULT"**, **"Deal"** and **"Undo"** are not on the dock. The four canvases are the only primary controls. **"Undo"** is still available in Settings.

After **"CALLED"** (and whenever a line is not open but home is not on the empty page), a bottom dock appears:
- **"Undo"** peels the latest call or miss. Disabled when there is nothing to peel. VoiceOver hint: **"Peels the latest call or miss."**
- **"Deal"** writes a new artist or title line and hangs four new canvases. Disabled without four loose works, while a line is still open, or while a deal is already running. VoiceOver hint when disabled: **"Needs four loose works, and refuses while a line is open."**

If a write failed, a plate on home quotes the fault (see Behaviours). If the crate was recovered from a backup and a line is showing, a line reads **"Crate recovered from backup."**

### How to call
Sheet title **"How to call"**. Toolbar close control (X; VoiceOver **"Close"**). Drag indicator at the top.

Copy:
- **"Read the line. Tap the match."**
- **"Deal writes an artist line or a title line and hangs four canvases. Tap the match. A miss dims that canvas and keeps the line."**

Counts **"CALLS"** and **"FAULTS"**. A status plate repeats **"IDLE"** / **"CUED"** / **"CALLED"** / **"FAULT"** and the same next-tap sentence as home. If a punctuality percent exists, it appears here too.

Bottom button:
- **"Deal"** if four loose works are ready and no line is open. Tapping it closes the sheet and deals.
- **"Call from Quiz"** otherwise. Tapping it only closes the sheet so you can call from home.

This is the usual first-deal path on a device: empty home has no **"Deal"**, so you open **"How to call"** and tap **"Deal"** after four saves.

### Explore
Sheet title **"Explore"**. Toolbar close control (X; VoiceOver **"Close"**). Caption **"THE METROPOLITAN MUSEUM OF ART"**. Field placeholder **"Search a work"**. Keyboard **"Done"** dismisses the keyboard.

With a quiet query, the list is the local shelf (see Starter content). Each row shows that work’s title and artist, plus **"Save"**. Tapping the row or **"Save"** files it as Loose. While a save is running, that row shows a spinner and other rows will not save. A note under the field can read **"Saved as Loose."** or **"Already in the crate."**

Typing a query searches The Metropolitan Museum of Art after a short pause. Matching public-domain works with images are preferred. If search is empty or fails, the local shelf hangs instead, and a small fault line can read **"Search missed. Local shelf is hanging."**, **"Search failed. Local shelf is hanging."**, or **"Search could not be read. Local shelf is hanging."**

Rare full-page empty: **"Shelf quiet."** / **"Search the Met, or save from the local shelf."** / **"Show shelf"** (clears the query and shows the shelf). Rare full-page error: **"Search failed."** plus the fault line, or **"Try again, or save from the local shelf."** / **"Retry"**.

### Saved
Sheet title **"Saved"**. Toolbar close control (X; VoiceOver **"Close"**).

Empty: **"No calls filed."** / **"Deal a line, then tap the matching canvas."** / **"Deal"** closes Saved and deals if a deal is allowed.

If Saved cannot load and there are no rows: **"Saved could not load."** plus the fault / **"Close"**.

When there are marks:
- Tally plates **"CALLS"** and **"FAULTS"** with counts
- Section **"Called"**: each called work’s title, artist, and a localized date. Rows are not buttons.
- Section **"Misses"**: newest first. Thumbnail, title (or the cue line if the work is gone), localized date, kind stamp **"ARTIST"** or **"TITLE"**, and the cue line. Rows are not buttons.

### Settings
Sheet title **"Settings"**. Toolbar close control (X; VoiceOver **"Close"**).

If the crate is empty: **"Crate empty."** / **"Save four works, then deal."** / **"Explore"** opens Explore.

Otherwise section **"Crate"** with **"Calls"** and **"Misses"** counts.

If a write fault is showing, section **"Write"** repeats that sentence.

Section **"Collection"**:
- **"The Metropolitan Museum of Art"** with **"metmuseum.org"** opens that page
- **"Open access"** with **"metmuseum.org/policies/open-access"** opens that page
- Footer **"Public-domain works hang from The Metropolitan Museum of Art."**

Section **"Support"**:
- **"Contact"** with **"tetraptych-lineup.pro/contact-us"** opens the support page

Then:
- **"Undo"** peels the latest call or miss (disabled when there is nothing to peel). Footer **"Undo peels the latest call or miss."**
- **"Re-run onboarding"** closes Settings and shows the three onboarding pages again
- **"Reset the crate"** asks **"Reset the crate?"** Message **"This removes works, calls, and misses on this device. It cannot be undone."** Buttons **"Keep"** (cancels) and **"Reset the crate"** (clears this device and returns to onboarding). Footer **"Reset removes the crate on this device."** VoiceOver hint on the reset button: **"Removes works and marks on this device."**

## Features
- Four-canvas lineup on home, labeled **"CALL THE LINEUP"**
- **"Deal"** writes one **"ARTIST"** or **"TITLE"** line and hangs four canvases
- Tap the matching canvas to call; a miss stamps **"MISS"**, dims that canvas, and keeps the line
- Called works rest and leave the deal pool; they file under **"Called"** on **"Saved"**
- Misses stay on **"Saved"** under **"Misses"**
- **"Undo"** peels the latest call or miss
- **"Explore"** search of The Metropolitan Museum of Art, **"Save"** as Loose, and a local shelf when search is quiet or fails
- Loose pool count **"LOOSE"** on the billboard
- Go clock (countdown, then **"GO"**; **"HOLD"** when no line is open) and a punctuality percent after a correct call
- **"How to call"** sheet
- **"Settings"** crate counts, collection credit, **"Contact"**, **"Re-run onboarding"**, **"Reset the crate"**
- Siri / Shortcuts phrases: **"Open Quiz in Fortello"**, **"Call the lineup in Fortello"**, **"Open Explore in Fortello"**, **"Open Saved in Fortello"**, **"Open Settings in Fortello"**, **"Deal a line in Fortello"**, **"How to call in Fortello"** (shortcut titles **"Quiz"**, **"Explore"**, **"Saved"**, **"Settings"**, **"Deal"**, **"Call"**; intent titles **"Open Quiz"**, **"Open Explore"**, **"Open Saved"**, **"Open Settings"**, **"Deal a line"**, **"How to call"**)

## Behaviours that can look like bugs
- A few seconds of empty screen after launch before the splash. Wait.
- Home empty CTA is **"Explore"**, not **"Deal"**, even after you have saved four works. The empty home still says **"Crate short."** / **"Save four works, then deal."** Deal from **"How to call"** (**"Deal"**), from empty **"Saved"** (**"Deal"**), or from the home dock after a line has already been called.
- **"Deal"** stays disabled until four Loose works are in the crate, and while a line is open (**"CUED"** or **"FAULT"**). The home dock is hidden while a line is open. Call the matching canvas first, or use **"Undo"** in Settings.
- Tapping **"Deal"** with fewer than four Loose works after a call does not start a new line; home can fall back to the empty crate page. Save more works in **"Explore"**.
- A miss does not end the round. Status becomes **"FAULT"**, next tap is **"Miss stays. Tap the true canvas."**, and the missed canvas shows **"MISS"**. Keep tapping other canvases until the match. Fault copy if you tap a spent canvas: **"Already dimmed."**
- After a correct call, Deal and Undo return. Next tap **"Called. Deal another, or Undo."** Tapping a canvas then shows **"Already called. Deal another, or Undo."** or **"Deal a line first."** if no line is open.
- **"Undo"** is faded and refuses when there is nothing to peel. Fault **"Nothing to Undo."**
- **"How to call"** bottom button becomes **"Call from Quiz"** when you cannot deal. It only closes the sheet.
- **"Save"** on a work already in the crate does not add a second copy. Note **"Already in the crate."** A new save notes **"Saved as Loose."**
- Search that misses, fails, or cannot be read still shows the local shelf plus **"Search missed. Local shelf is hanging."**, **"Search failed. Local shelf is hanging."**, or **"Search could not be read. Local shelf is hanging."** That is fallback, not an empty catalog. Typing waits a moment before results change.
- Called works leave the deal pool, so **"LOOSE"** shrinks. After enough calls you must **"Explore"** and **"Save"** again before **"Deal"** works.
- **"Re-run onboarding"** only shows the three pages. If you leave the app before **"Skip"** or **"Continue"**, home can return because onboarding was already finished.
- **"Reset the crate"** needs the alert **"Reset the crate?"** and a second tap on **"Reset the crate"**. **"Keep"** leaves the crate as it is. After reset, onboarding runs again and the crate is empty.
- Write faults on home, Saved, or Settings **"Write"**: **"Write failed. Deal or Undo again."**, **"The line stays. Call the matching canvas."**, **"That canvas is not hanging."**, **"That canvas misses. The line stays."**, **"Call the match. Do not miss it."**, **"No object ID."** Deal, Undo, or tap the true canvas as the sentence says.
- Home **"Crate could not be read."** means start fresh: **"Explore"**, save four works, then deal. **"Crate recovered from backup."** means the crate came back from a backup and you can keep going.
- Siri **"Deal a line in Fortello"** while a line is already open does not start a second line. Home may show **"The line stays. Call the matching canvas."**

## Starter content and resume
On a physical device the crate starts empty. Explore still lists a local shelf of ten public-domain Met works you can **"Save"**:
- Vincent van Gogh, Wheat Field with Cypresses
- Johannes Vermeer, Young Woman with a Water Pitcher
- Winslow Homer, The Gulf Stream
- John Singer Sargent, Madame X (Virginie Amélie Avegno Gautreau)
- Georges Seurat, Circus Sideshow (Parade de cirque)
- Jacques Louis David, The Death of Socrates
- Gustave Moreau, Oedipus and the Sphinx
- Edouard Manet, Boating
- Rembrandt (Rembrandt van Rijn), Aristotle with a Bust of Homer
- Joseph Mallord William Turner, Venice, from the Porch of Madonna della Salute

The iOS Simulator plants a demo crate once: eight of those works, six Loose and two already Called (Gustave Moreau, Edouard Manet), a line already dealt, two calls and three misses filed, onboarding skipped. A device never plants that demo.

Unfinished work resumes. The crate, an open line including dimmed misses, calls, misses, Undo order, and whether onboarding was finished all come back on the next launch. **"Reset the crate"** clears that resume.

## Permissions
None. The app does not ask for camera, photos, microphone, location, or tracking.

## Absent
Genuinely absent: login or accounts, in-app purchase, ads, analytics, user-generated content, account deletion flow, App Tracking Transparency prompt.

## Data and support
Works, calls, and misses stay on this device. **"Reset the crate"** removes them here. Explore looks up public Met works; it does not create an account.

On-screen support: Settings → **"Support"** → **"Contact"** (**"tetraptych-lineup.pro/contact-us"**). Collection credit is Settings → **"Collection"**.

## Scanning and health
None. The app does not scan barcodes or QR codes. It does not show health, medical, or product-health information. Collection credit for the paintings is in Settings, **"Collection"**.

## Platform
English copy. Counts and dates follow the device locale. No region lock. Light appearance only. Portrait only on iPhone and iPad. Full screen. iPhone and iPad. Minimum iOS 17.0.

## Category
Education
