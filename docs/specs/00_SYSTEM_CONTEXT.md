# 00_SYSTEM_CONTEXT: Master Blueprint & Knowledge Base

> **Primary Audience**: Autonomous & Pair-Programming AI Agents (Antigravity, Claude Code, Codex, Cursor) and Human Maintainers.  
> **Last Updated**: November 2026 (v2.0.0 Release)  
> **Project**: `iDotMatrix Studio for macOS` (`com.arcodexx.idotmatrix-studio`)

---

## 1. High-Level Vision & Scope

**iDotMatrix Studio** is a native macOS application for managing and streaming content to Bluetooth Low Energy (BLE) 32×32 and 16×16 LED matrix displays (iDotMatrix hardware and compatible clones).

Unlike early menubar scripts, the app features a **Dual-Layer Interface**:
1. **MenuBar Quick View (`MenuBarQuickView.swift`)**: 295px popover living in the macOS status bar for zero-friction daily use (brightness slider, 4 instant mode pills: Clock, Music, Saturated Presets, Light Effects, and a real-time virtual LED mirror).
2. **Studio Workspace (`StudioView.swift`)**: Full-featured macOS desktop window (`NavigationSplitView`) housing:
   - **Live Display Mirror**: Hardware output mirrored in real-time.
   - **Pixel Art Studio**: 32×32 drawing canvas with Pen, Eraser, Fill Bucket, Eyedropper, Palette, and Hex picker.
   - **Divoom Community Library**: Cloud gallery browser with category filtering and instant device streaming.
   - **My Assets**: Local gallery of saved GIFs and PNGs.
   - **Daily Scheduler**: Automated time-slot triggers across the day.
   - **Device & Display Settings**: BLE reconnect, orientation flip, 12h/24h clock, text banner speed.

---

## 2. Architecture & State Management

```
┌─────────────────────────────────────────────────────────────────┐
│                      macOS Environment                          │
└───────────────▲─────────────────────────────────▲───────────────┘
                │                                 │
     MenuBar Status Extra              Dedicated Studio Window
    (MenuBarQuickView.swift)             (StudioView.swift)
                │                                 │
                └───────────────┬─────────────────┘
                                │
                                ▼
            ┌────────────────────────────────────────┐
            │       ViewModel.shared (Singleton)      │
            │   ObservableObject Central State Store  │
            └───────┬────────────┬─────────────┬─────┘
                    │            │             │
        ┌───────────▼──┐   ┌─────▼──────┐   ┌──▼──────────┐
        │ SwiftBluetooth│  │ Scripting  │  │ DivoomClient │
        │  (CoreBluetooth)│ │ Bridge     │  │ (Cloud API  │
        │  Peripheral   │  │ (Spotify)  │  │  + Python)   │
        └───────────────┘  └────────────┘  └──────────────┘
```

* **Single Source of Truth**: `ViewModel.swift` (`@Observable class ViewModel: ObservableObject`). Both the menubar popover and Studio window bind directly to `ViewModel.shared`.
* **Window Lifecycle**: Handled by `StudioWindowManager.swift`. It prevents multiple instances of the Studio window from opening and properly activates the app in the foreground without breaking `LSUIElement = YES` (menubar agent behavior).
* **Virtual LED Simulation**: `VirtualMatrixView.swift` renders a 32×32 matrix using SwiftUI `Canvas` and `TimelineView(.periodic)`. It calculates pixel coordinates and dot sizes dynamically, blinking colons every second and downsampling album artwork or preset colors.

---

## 3. Directory Map & Component Responsibilities

```
idotmatrix-swift/
├── App Entry & Windowing
│   ├── idotmatrix_swiftApp.swift      # @main entrypoint (MenuBarExtra + StudioWindow initialization)
│   ├── MenuBarQuickView.swift         # 295px popover quick controller with mini virtual matrix
│   ├── StudioView.swift               # Full Studio NavigationSplitView workspace
│   ├── StudioWindowManager.swift      # Singleton window controller for StudioView
│   ├── VirtualMatrixView.swift        # 32x32 LED Canvas live simulation engine
│   └── Content.swift                  # Legacy detailed controls wrapper
│
├── ViewModel (State & BLE Dispatch)
│   ├── ViewModel.swift                # Central state, BLE scanning, connection, and sendData
│   ├── DisplaySettings.swift          # Brightness, screen flip, on/off, time sync
│   ├── Clock.swift                    # 12h/24h modes, date formats, color styles
│   ├── Image.swift                    # PNG selection, sips resizing, 4096-byte chunking
│   ├── Gif.swift                      # Animated GIF parsing, frame delays, packet streaming
│   ├── FullscreenColor.swift          # Solid saturated RGB fills
│   ├── LightEffect.swift              # Built-in hardware lighting animations
│   ├── MusicIntegration.swift         # Spotify ScriptingBridge polling & art pipeline
│   ├── Text.swift                     # Marquee text banner rendering & chunking (20-byte MTU)
│   ├── Eco.swift                      # Auto sleep/wake timers & eco-brightness
│   └── DeviceStatusEnum.swift         # Connection status state machine
│
├── Studio Tabs
│   ├── PixelArtEditorView.swift       # 32x32 drawing canvas, tool picker, color picker ring
│   ├── AssetsView.swift               # Local saved assets browser
│   ├── SchedulerView.swift            # Daily automation time slots
│   └── Divoom/
│       ├── DivoomClient.swift         # Reverse-engineered Aurabox cloud API client
│       ├── DivoomLibraryView.swift    # Gallery grid, category filter, login sheet
│       └── DivoomWindowManager.swift  # Window helper for gallery
│
├── Scripts / Embedded Binaries
│   ├── Scripts/divoom_convert.py      # Python pipeline: decodes Apixoo/PIL formats to 32x32 GIF
│   └── Resources/gifsicle             # Embedded CLI binary for optimized GIF frame manipulation
│
└── Config & Metadata
    ├── Info.plist                     # Generated info plist (LSUIElement = YES)
    ├── idotmatrix_swift.entitlements  # Bluetooth, AppleEvents, Network entitlements
    └── idotmatrix-swift.xcodeproj     # Core Xcode project manifest
```

---

## 4. Key Engineering Gotchas & Constraints (Must Read!)

1. **Xcode Build Phases (`PBXSourcesBuildPhase`)**:
   - Xcode's project manifest (`project.pbxproj`) maintains an explicit whitelist of every compiled Swift file in `PBXSourcesBuildPhase`.
   - **Crucial**: Whenever you add a new `.swift` file, you **must** register it in both `PBXFileReference` and `PBXSourcesBuildPhase`. If missing, Xcode silently ignores the file or throws linker errors (`Undefined symbol: _main`).
2. **CompactSlider Dependency**:
   - `CompactSlider` must stay pinned at minimum version `2.0.0` or higher in `Package.resolved`.
   - In Xcode 16 / Swift 6, `LinearGradient` ambiguously conforms to both `View` and `ShapeStyle`. CompactSlider 1.x fails to compile due to `.opacity()` ambiguity.
3. **Product & Output Names**:
   - `PRODUCT_NAME` is explicitly set to `"iDotMatrix Studio"`.
   - `PRODUCT_BUNDLE_IDENTIFIER` is `"com.arcodexx.idotmatrix-studio"`.
   - `INFOPLIST_KEY_CFBundleDisplayName` is `"iDotMatrix Studio"`.
   - `INFOPLIST_KEY_LSUIElement` is `YES` (runs as a menubar agent without taking over Dock unless a window opens).
4. **Dynamic Resource Resolution**:
   - **Never** use hardcoded `/Users/...` paths.
   - Use `Bundle.main.path(forResource: "divoom_convert", ofType: "py")` or `Bundle.main.resourceURL`.
   - `divoom_convert.py` and `gifsicle` are members of `PBXResourcesBuildPhase`.
5. **BLE Packet Throttling**:
   - The ESP32/microcontroller on iDotMatrix boards has limited buffer memory.
   - Streaming text or animations requires a **50ms sleep** between 20-byte MTU packets (`Task.sleep(nanoseconds: 50_000_000)`) to avoid buffer overrun.

---

## 5. Third-Party Integrations

* **Spotify**: Uses macOS `ScriptingBridge` (`SBApplication(bundleIdentifier: "com.spotify.client")`). It queries current track ID and artwork URL, downloads the PNG, resizes it to 32×32 via macOS `/usr/bin/sips`, and streams the chunks over BLE.
* **Divoom Cloud API**: Reverse-engineered endpoints (`/UserLogin`, `/GetCategoryFileListV2`) mimicking the `Aurabox/3.1.10` iPad app. Downloaded pixel art files are converted via the embedded `divoom_convert.py` script. User credentials are stored exclusively in macOS `UserDefaults` (`divoom_email`, `divoom_password`).

---

## 6. Specification Updates & Evolution History

* [001_v2.0.0_studio_overhaul.md](updates/001_v2.0.0_studio_overhaul.md): Full UI/UX workspace revamp, virtual LED mirror, Divoom authentication & category browsing.
* [002_fix_music_marquee_streaming.md](updates/002_fix_music_marquee_streaming.md): Fixed Spotify Marquee GIF streaming, packet mode conflicts, buffer flush timing, and mid-stream task cancellation.

