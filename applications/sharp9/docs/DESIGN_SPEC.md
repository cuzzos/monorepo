# sharp9 — iOS Design Specification

This document defines the **visual design and UX** for **sharp9**, a single-screen audio slow/pitch/loop tool inspired by BandLab's AudioStretch.

**App naming:**
- Code/folders: `Sharp9` (PascalCase for Swift)
- UI display: "sharp9" (lowercase, no space)
- Project: sharp9 (lowercase, no space)

**Document purpose:**
- **This file (DESIGN_SPEC.md)**: Colors, typography, layout, UX behaviors, visual tokens
- **SPEC.md**: Technical architecture, file structure, implementation details, business logic

---

## 1) Platform & Design Approach

**Platform:** iOS 18+ minimum  
**UI Framework:** SwiftUI with `Canvas` for waveform rendering  
**Visual Style:** Dark, high-contrast (BandLab-inspired)  
**Storage:** Local-only v1 (no accounts)

---

## 2) Visual Design Tokens (approx from video)

> The reference UI is a dark, high-contrast “BandLab” style.

### 2.1 Colors
- `bg`: #0B0C0E (near-black)
- `panel`: #111317 (slightly lighter black)
- `waveformFill`: #C9CED6 (cool light gray)
- `gridLine`: #2A2E36 (very subtle)
- `playheadRed`: #FF3B30 (iOS system red works)
- `loopBlue`: #2F6DFF (selection + A/B markers)
- `loopBlueFill`: rgba(47,109,255,0.30)
- `markerPurple`: #A855F7 (or #B266FF)
- `textPrimary`: #FFFFFF
- `textSecondary`: rgba(255,255,255,0.70)
- `textTertiary`: rgba(255,255,255,0.45)

### 2.2 Typography
- Use `SF Pro` default.
- App title: `.headline` (bold)
- Track title: `.subheadline` (semibold)
- Time labels: `.caption` (monospaced digits recommended)
- Control values (speed/pitch): `.caption` / `.footnote` (monospaced digits)

### 2.3 Corners / Shadows
- Controls sit in a **rounded pill bar**:
  - corner radius: 14–18
  - subtle shadow: black @ 20% blur 10

---

## 3) Screen Layout (top → bottom)

### 3.1 Safe Area / Status Bar
- Status bar visible (time, battery) in reference.
- Background extends under status bar.

### 3.2 Top Nav Row
Left: **X** (close)  
Center: **sharp9**  
Right: **crown icon** (Pro) + **overflow/menu** (three horizontal lines in reference)

**Spacing:** ~12–16pt horizontal padding.  
**Tap targets:** 44×44.

### 3.3 Track Row (beneath nav)
Left: **“+”** + track name (single line, truncates middle/ends).  
Right: **download/export** icon and **sliders/settings** icon.

In reference, the track title resembles:
`Stevie Wonder Superstition (… )` (file name / stem).

### 3.4 Keyboard Strip
Full width **piano keyboard** (white/black keys), fixed height ~54–70pt.
- Subtle vertical black key blocks.
- Above keyboard: occasional tiny bars/spikes (optional visualization).
- In reference, keyboard is always visible once track loaded.

### 3.5 Main Waveform Area
- Large waveform centered vertically.
- Background same as `bg`.
- **Selection region** appears as a translucent blue block spanning full waveform height from **A → B**.
- **Playhead**: thin vertical red line.
- **Markers**:
  - **Purple vertical lines** at various times.
  - Each marker has a small purple dot/handle at the top.
- **A/B labels** appear as small letters at bottom mode bar, not necessarily at the waveform line, but implement optional small `A`/`B` badges at top for clarity.

### 3.6 Overview Strip
A tiny waveform overview strip under the main waveform (height ~10–14pt).
- Shows global waveform silhouette.
- Shows selection overlay and marker ticks.

### 3.7 Mode Bar (A/Loop/B)
A segmented control-like bar, full width with four items:
- **marker icon** (pin)  |  **A**  |  **loop icon** (↔ / circular)  |  **B**
The **selected mode** is highlighted with a blue background fill on that segment.

Reference shows the **loop icon segment** highlighted during loop editing.

### 3.8 Transport / Controls Bar
A rounded dark pill bar with:
- Left cluster: **speed controls**
  - minus button, value label `1.00 x`, plus button
  - small `SPEED` label under the value
- Center cluster: transport
  - back/previous, play/pause, forward/next
- Right cluster: **pitch controls**
  - `b` (flat) button, value label `0.00 st`, `#` (sharp) button
  - small `PITCH` label under the value

---

## 4) States & Behaviors

### 4.1 App States
1. **Empty**
   - Show “Import File” button near top-left of content.
   - Everything else mostly blank/disabled.
2. **Loading**
   - After import, show spinner in waveform area.
3. **Ready**
   - Waveform, keyboard, controls enabled.
4. **Error**
   - Toast: “Unable to open file”.

### 4.2 Interaction Model

#### 4.2.1 Seeking / Scrubbing
- Tap on waveform: move playhead to that time.
- Drag left/right on waveform: scrubs continuously.
- Keep time readout visible centered above waveform (monospace).

#### 4.2.2 Loop Points A/B
- Mode = **A**: tap waveform sets **A**.
- Mode = **B**: tap waveform sets **B**.
- When both set:
  - Render selection overlay A→B.
  - If loop enabled, playback wraps at B to A.
- If user sets A > B: **swap** automatically.

#### 4.2.3 Loop Mode Segment
- When loop segment is selected:
  - Tapping play will loop if A and B exist.
  - If A/B missing, show toast “Set A and B”.

#### 4.2.4 Markers (Purple)
- Marker mode: tap waveform adds a marker at playhead time (or tap position).
- Long-press marker: delete.
- Markers rendered in main and overview.

#### 4.2.5 Speed
- Range: 0.25x … 2.00x
- Step: 0.01 (fine) internally, but buttons step 0.05
- Show toast near center of waveform: `Speed 1.18`
- Apply via `AVAudioUnitTimePitch.rate` (rate is 0.25–4.0; map directly).

#### 4.2.6 Pitch
- Range: -12.00 … +12.00 semitones
- Step: buttons +/− 1.00
- Fine adjustment: allow by long-press/drag for 0.01
- Show toast: `Pitch 0.03`
- Apply via `AVAudioUnitTimePitch.pitch` in cents (semitones * 100).

---

## 5) Audio Engine Overview

The audio engine uses:
- `AVAudioEngine` + `AVAudioPlayerNode` + `AVAudioUnitTimePitch`
- Time/pitch manipulation without quality loss
- Seamless A→B loop scheduling

**See SPEC.md Section 3 (Engine layer) for detailed implementation.**

---

## 6) Waveform Rendering Overview

Waveforms use:
- Precomputed min/max peak arrays
- SwiftUI `Canvas` for efficient drawing
- Multiple resolution levels for zoom
- Symmetric top/bottom rendering

Visual elements:
- Selection overlay (blue translucent) between A and B
- Playhead (red vertical line)
- Markers (purple vertical lines with top dots)
- Overview strip with global context

**See SPEC.md and WaveformView/WaveformPeaks implementation for details.**

---

## 7) SwiftUI View Hierarchy

```
ContentView (main screen)
  ├─ TopNavBar
  ├─ TrackRow
  ├─ KeyboardStrip
  ├─ WaveformStack
  │    ├─ TimeReadout
  │    ├─ WaveformCanvas (main)
  │    └─ OverviewCanvas
  ├─ ModeBar
  ├─ TransportBar
  └─ ToastOverlay (speed/pitch)
```

See SPEC.md for detailed component file structure and implementation details.

---

## 8) Exact Control Copy (strings)

**Navigation & Actions:**
- App title: `sharp9` (lowercase, no space)
- Import button: `Import File`

**Transport Controls:**
- Labels: `SPEED`, `PITCH`
- Units: `x`, `st`

**Toast Messages:**
- Speed change: `Speed {value}`
- Pitch change: `Pitch {value}`
- Loop error: `Set A and B`
- Import error: `Unable to open file`

---

## 9) Visual/UX Implementation Checklist (v1)

Layout & Components:
- [ ] Top nav bar with "sharp9" title, close button, menu icons
- [ ] Track row with "+" button and track name display
- [ ] Static keyboard strip (54-70pt height)
- [ ] Main waveform view with proper dark theme colors
- [ ] Overview waveform strip (10-14pt height)
- [ ] Mode bar (4 segments: marker | A | loop | B)
- [ ] Transport bar (rounded pill: speed | play/pause | pitch)
- [ ] Toast overlay centered above waveform

Visual Elements:
- [ ] Waveform fill color: #C9CED6
- [ ] Selection overlay: blue translucent (#2F6DFF @ 30%)
- [ ] Playhead: red vertical line (#FF3B30)
- [ ] Markers: purple vertical lines (#A855F7) with top dots
- [ ] Dark background theme (#0B0C0E / #111317)

Interactions:
- [ ] Tap waveform: seek or set A/B based on mode
- [ ] Drag waveform: continuous scrub
- [ ] Speed +/- buttons with toast feedback
- [ ] Pitch +/- buttons with toast feedback
- [ ] Mode bar segment selection highlighting
- [ ] Play/pause toggle
- [ ] File import button ("Import File")

Typography & Formatting:
- [ ] SF Pro with Dynamic Type
- [ ] Time display: monospaced, format "MM:SS.xx"
- [ ] Speed display: "1.00 x" (monospaced)
- [ ] Pitch display: "0.00 st" (monospaced)
- [ ] Toast messages: "Speed {value}" / "Pitch {value}"

**For technical implementation details, see SPEC.md.**

---
