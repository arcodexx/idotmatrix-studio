# 002: Fix Music Art Marquee GIF Streaming & Buffer Collision

**Date**: 2026-11-11  
**Target Device**: iDotMatrix 32×32 RGB LED Display (`IDM-A8CD90`)  
**Scope**: `ViewModel/MusicIntegration.swift`, `ViewModel/Gif.swift`, `ViewModel/ViewModel.swift`

---

## 1. Problem Statement
When Spotify music visualizer was active, static album artwork (`showSongTitle = false`) displayed properly, but turning on "Show Song Title Overlay" (`showSongTitle = true`) — as well as sending GIFs from Assets or Divoom — resulted in:
1. No visible change (display remained on the previous static image or clock).
2. Blank black screen on the display when DIY mode packets were sent beforehand.
3. Persistent SPI flash lockup that survived USB-C power-cycling (`FA03` returning `[05 00 01 00 00]` on single-chunk GIFs and ignoring completed `05 00 01 00 03` uploads) until a **Device Reset** was triggered in the official iDotMatrix app.

---

## 2. Root Cause Analysis
1. **Mode Packet Conflict (`[5, 0, 4, 1, 1]`)**:
   `Data([5, 0, 4, 1, 1])` is **DIY Mode** used specifically for static PNG uploads (`sendPhoto`). When sent prior to native GIF streaming, it forces the hardware MCU to blank the screen for PNG reception rather than GIF flash playback.
2. **BLE Characteristic MTU & Write Type (`FA02` `maxWriteWithResp = 512`)**:
   `IDM-A8CD90` exposes `FA02` (`props=12`, max write length 512 bytes) and `FA03` (`props=16`, notify). Sending entire 4,112-byte GIF chunks in a single `.withoutResponse` write risks silent CoreBluetooth truncation/packet loss. Splitting each 4 KB GIF block into `<= 500 B` `.withResponse` slices (with `30 ms` slice spacing) and enabling `FA03` notifications ensures reliable block ACKs (`05 00 01 00 01` / `05 00 01 00 03`).
3. **Mid-Stream Task Cancellation & SPI Flash Lockup**:
   Spotify continuously posts `com.spotify.client.PlaybackStateChanged` distributed notifications (volume, position slider ticks). Canceling `currentSpotifyTask` on every progress notification interrupted GIF uploads mid-transfer, wedging the display's SPI flash state machine so thoroughly that even the official app couldn't upload GIFs until a **Device Reset** was run from settings.
4. **Missing Animation Flush (`blankGif`)**:
   Embedded iDotMatrix display firmware uses a 1-frame blank GIF flush (`delay: 0`, followed by `250 ms` sleep) before streaming multi-frame marquee GIFs to clear previous display buffers cleanly.

---

## 3. Implemented Fixes
1. **`Gif.swift`**:
   - Removed `Data([5, 0, 4, 1, 1])` from `sendGif`. Native GIF streams are transmitted directly with the protocol header `[255, 255, 1, 0, 0, ...]`.
   - Sliced each 4 KB GIF chunk into `<= 500 B` `.withResponse` BLE writes (`30 ms` between slices) to stay strictly within `maximumWriteValueLength` (`512 B`).
   - Preserved inter-chunk delay (`50_000_000` ns default).
2. **`MusicIntegration.swift`**:
   - Restored `getBlankGif()` with zero delay and a `250 ms` buffer stabilization pause before streaming the marquee GIF at `40 ms` chunk delay.
   - Restored standard CoreGraphics/ImageIO `generateMarqueeGif` renderer at `speed: 1.0` and `0.1s` frame delay.
   - Added duplicate notification guard: if `trackID == currentArtworkUrlString && currentSpotifyTask != nil`, in-flight uploads for the same track are protected from mid-stream cancellation.
   - Deferred updating `currentArtworkUrlString = trackID` until transmission completes without cancellation.
3. **`ViewModel.swift`**:
   - Subscribes to `FA03` notifications (`setNotifyValue(true, for: notifyChar)`) upon connection and clears `notifyCharacter` on disconnect.
   - When disabling `isSpotifyEnabled`, cancels any active in-flight task before reverting display to clock.
   - When toggling `showSongTitle` or re-enabling `isSpotifyEnabled`, resets `currentArtworkUrlString = ""` to immediately force re-rendering and transmission.
