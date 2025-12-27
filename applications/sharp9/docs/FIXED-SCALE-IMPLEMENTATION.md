# Fixed-Scale Timeline Implementation

## Overview
Implemented a fixed-scale, scrollable waveform timeline with a centered playhead and time ruler.

## Key Changes

### 1. Fixed Zoom Level
- **Constant:** `pixelsPerSecond: CGFloat = 40`
- **What it means:** 1 second of audio = 40 pixels on canvas
- **For 76.13s track:** Canvas width = 3045 pixels

### 2. Canvas-Based Coordinate System
The waveform is drawn on a wide canvas that scrolls under the fixed playhead:

```
Canvas Width = trackDuration * pixelsPerSecond
Scroll Offset = -(currentTime * pixelsPerSecond) + (viewportWidth / 2)
```

### 3. Delta-Based Dragging
Uses `@GestureState` to capture drag start time, then applies translation delta:

```swift
deltaTime = -translation.width / pixelsPerSecond
newTime = startTime + deltaTime
```

**Result:** Dragging 40px moves exactly 1 second, regardless of track length.

### 4. Time Ruler
New `TimeRuler` component displays:
- Major ticks every 1 second
- Minor ticks every 0.2s (when zoom ≥ 30 px/s)
- Labels every 5 seconds
- Uses same `pixelsPerSecond` scale as waveform

## Math Formulas

### Time → Canvas Position
```swift
canvasX = timeSec * pixelsPerSecond
```

### Screen Position → Time (for tap)
```swift
canvasX = screenX - scrollOffset
time = canvasX / pixelsPerSecond
```

### Scroll Offset (to center playhead)
```swift
scrollOffset = -(currentTime * pixelsPerSecond) + (viewportWidth / 2)
```

## Tuning Zoom Level

Change `pixelsPerSecond` to adjust zoom:

| px/s | Feel | 100px drag | Notes |
|------|------|------------|-------|
| 40 | Fine editing | 2.5s | ⭐ Recommended default |
| 30 | Moderate | 3.3s | Good balance |
| 25 | Comfortable | 4.0s | More context |
| 20 | Navigation | 5.0s | Fast travel |

### Adaptive Formula
```swift
// Show ~15% of track in viewport
let pixelsPerSecond = viewportWidth / (trackDuration * 0.15)
```

## Files Changed

1. **WaveformView.swift** - Complete rewrite with fixed-scale system
   - Delta-based drag gesture
   - Canvas-based scrolling
   - Fixed playhead at center
   - Integrated TimeRuler

2. **TimeRuler.swift** - New component
   - 1-second major ticks
   - 0.2-second minor ticks (when visible)
   - Labels every 5 seconds
   - Aligned with waveform scale

## Testing Acceptance Criteria

✅ **Playhead Fixed:** Red line stays at viewport center during all interactions

✅ **Predictable Delta:** At 40 px/s, dragging 40px = 1 second change

✅ **Ruler Alignment:** 1-second ticks match waveform time positions exactly

✅ **No Jitter:** Smooth scrolling without feedback loops

✅ **Zoom Consistency:** Changing `pixelsPerSecond` affects both waveform and ruler equally

## Example Calculations (40 px/s, 76.13s track)

- **Canvas width:** 76.13 × 40 = 3,045 pixels
- **At time 0s:** scrollOffset = 0 + 200 = +200px (waveform shifted right)
- **At time 38s (middle):** scrollOffset = -1520 + 200 = -1,320px
- **At time 76.13s:** scrollOffset = -3,045 + 200 = -2,845px (waveform shifted left)
- **Viewport shows:** ~10 seconds at a time (400px ÷ 40 px/s)
- **Drag sensitivity:** 100px = 2.5 seconds

## Future Enhancements

### Optional: Pinch-to-Zoom
```swift
.gesture(
    MagnificationGesture()
        .onChanged { scale in
            // Adjust pixelsPerSecond based on scale
            // Keep center time stable during zoom
        }
)
```

### Optional: Zoom Presets
```swift
enum ZoomLevel {
    case fine      // 40 px/s
    case moderate  // 30 px/s
    case comfortable // 25 px/s
    case overview  // track.duration / viewportWidth
}
```

### Optional: Velocity-Based Deceleration
Add momentum scrolling after drag release using `UIScrollView` physics or custom animation.

## Viewport Struct (Currently Unused)

The `Viewport` struct in `AppState` is **not used** in this fixed-scale implementation. It could be repurposed for:
- Zoom level state storage
- Saving scroll position across sessions
- Implementing viewport-based zoom later

For now, the fixed-scale approach meets the spec requirement of "one second per tick" with intuitive dragging.

