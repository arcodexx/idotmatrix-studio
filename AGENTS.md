# AI Developer Instructions (`AGENTS.md`)

Welcome to **iDotMatrix Studio**. This repository is configured for autonomous and pair-programming AI agents (Antigravity, Claude Code, OpenAI Codex, Cursor, etc.).

## 📍 Essential First Step
**Before implementing any feature, bug fix, or refactor in this repository, you MUST read the master system context:**

👉 [**`docs/specs/00_SYSTEM_CONTEXT.md`**](docs/specs/00_SYSTEM_CONTEXT.md)

This file contains:
- Full application architecture and state flow.
- Directory map and file responsibilities.
- BLE hardware protocol packet layouts and frame chunking.
- Third-party integrations (Divoom API, Spotify ScriptingBridge).
- Critical Xcode build settings and gotchas that prevent project corruption.

---

## 📜 Agent Guidelines & Rules of Engagement

1. **Document Every Major Change**:
   - When you complete a meaningful feature, architectural modification, or fix, create a new entry in `docs/specs/updates/` (e.g. `002_<feature_name>.md`) and update `docs/specs/00_SYSTEM_CONTEXT.md`.
2. **Never Hardcode Secrets or Personal Paths**:
   - Never commit API credentials, passwords, or absolute paths (e.g. `/Users/...`).
   - Always resolve resources dynamically using `Bundle.main.path(forResource:ofType:)`.
3. **Preserve Xcode Project Integrity (`project.pbxproj`)**:
   - If you create new `.swift` files, ensure they are registered in `PBXSourcesBuildPhase` and `PBXFileReference`.
   - Bundle resources (scripts, assets) must be in `PBXResourcesBuildPhase`.
   - Do not downgrade `CompactSlider` below `2.0.0` (required for Swift 6 / Xcode 16 compatibility).
4. **Hardware Safety**:
   - Respect the 32×32 and 16×16 packet structure. Frame sizes and chunk delays are critical to avoid buffer overruns on the display's micro-controller.
5. **Dual-Layer UI Consistency**:
   - The app has two main interfaces:
     1. **`MenuBarQuickView.swift`**: Quick popover (compact 295px width, fast toggles, saturated presets, mini virtual LED mirror).
     2. **`StudioView.swift`**: Full workspace window (`NavigationSplitView`) managed by `StudioWindowManager.swift`.
   - Both must share state cleanly via `ViewModel.shared`.

---

## 📚 Deep-Dive References
* [Master System Context](docs/specs/00_SYSTEM_CONTEXT.md)
* [Hardware BLE Protocol Specification](docs/specs/HARDWARE_BLE_PROTOCOL.md)
* [Divoom API & Conversion Pipeline](docs/specs/DIVOOM_API_SPEC.md)
* [Change Logs & Evolution History](docs/specs/updates/)
