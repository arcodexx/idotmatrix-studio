<p align="center">
  <h1 align="center">iDotMatrix Studio</h1>
  <p align="center">
    <strong>The ultimate native macOS companion for iDotMatrix & 32×32 Bluetooth LED displays.</strong>
  </p>
  <p align="center">
    <a href="https://github.com/arcodexx/idotmatrix-studio/releases"><img src="https://img.shields.io/github/v/release/arcodexx/idotmatrix-studio?style=flat-square&color=blue" alt="Release"></a>
    <img src="https://img.shields.io/badge/macOS-14.0%2B-black?style=flat-square&logo=apple" alt="macOS 14+">
    <img src="https://img.shields.io/badge/Swift-5.9%2B-orange?style=flat-square&logo=swift" alt="Swift 5.9+">
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License"></a>
  </p>
</p>

---

## 🌟 Overview

**iDotMatrix Studio** is a completely reimagined macOS application for controlling and designing on 16×16 and 32×32 Bluetooth LED matrix displays (iDotMatrix and compatible hardware).

Combining a lightweight **MenuBar Quick View** for instant control with a rich, full-screen **Studio Workspace**, iDotMatrix Studio turns your desktop LED display into a live dashboard, pixel art canvas, and ambient music visualizer.

---

## ✨ Features

### 🎛️ Dual-Layer Experience
* **MenuBar Quick View**: A sleek 295px popover right in your macOS menu bar. Control brightness, toggle presets, pick pure saturated colors, and see a live-rendered virtual matrix mirror without taking up screen space.
* **Studio Workspace**: A dedicated, distraction-free creative suite with a unified sidebar (`NavigationSplitView`) for deep pixel art editing, gallery browsing, scheduling, and device management.

### 💡 Real-Time Virtual LED Mirror
* 32×32 hardware-accurate LED simulation powered by SwiftUI `Canvas` and `TimelineView`.
* Live preview for the ticking clock, streaming music album art, full-screen colors, and lighting effects.

### 🎨 Pixel Art Editor
* 32×32 grid canvas built for creators.
* Full toolset: **Pen**, **Eraser**, **Color Eyedropper**, **Fill Bucket**, and **Clear**.
* Saturated palette presets + full system Hex ColorPicker.
* One-click upload to your connected display.

### 🌐 Divoom Cloud Community Library
* Connect and browse thousands of animated GIFs and pixel artworks shared by the global community.
* 17 curated categories: *Recommended, Emoji, Nature, Gaming, Creative, Animals, Patterns, and more*.
* Seamless background authentication and instant preview.

### 🎵 Music & Spotify Visualizer
* Automatically syncs and downsamples current playing album artwork to your 32×32 LED display in real time.

### ⏰ Daily Smart Scheduler
* Set up custom automation time slots throughout your day (e.g., live clock during work hours, album art during listening sessions, ambient animations in the evening).

### ⚡ Low Energy & Fast BLE
* Built 100% native with Swift and SwiftUI.
* Efficient Bluetooth Low Energy (BLE) auto-reconnection and zero background battery drain.

---

## 🖥️ Requirements & Compatibility

* **OS**: macOS 14.0 (Sonoma) or newer.
* **Hardware**:
  * 32×32 or 16×16 iDotMatrix Bluetooth LED Displays (and compatible clones).
  * Mac with Bluetooth 4.0+.

---

## 🚀 Installation

### Download Pre-built Release
1. Go to the [**Releases**](https://github.com/arcodexx/idotmatrix-studio/releases) page.
2. Download the latest `iDotMatrix-Studio.dmg`.
3. Open the `.dmg` and drag **iDotMatrix Studio** to your **Applications** folder.
4. Launch the app and grant Bluetooth permissions when prompted.

### Building from Source
```bash
# Clone the repository
git clone git@github.com:arcodexx/idotmatrix-studio.git
cd idotmatrix-studio

# Open in Xcode
open idotmatrix-swift.xcodeproj
```
Select the `idotmatrix-swift` target and run `Cmd + R` to build and run.

---

## 🛠️ Tech Stack

* **Language**: Swift 5.9+
* **UI**: SwiftUI (macOS 14+ / NavigationSplitView / Canvas API)
* **Bluetooth**: SwiftBluetooth (CoreBluetooth wrapper)
* **GIF Processing**: Gifsicle C-library integration
* **API**: Divoom Cloud API

---

## 🤝 Acknowledgments & Credits

iDotMatrix Studio is built on the shoulders of giants. Special thanks to:

* [**Avi Wadhwa (@aviwad)**](https://github.com/aviwad/idotmatrix-swift) — for the original proof-of-concept menu bar application.
* [**derkalle4 (@derkalle4)**](https://github.com/derkalle4/python3-idotmatrix-library) — for reverse-engineering the iDotMatrix Bluetooth protocol (`python3-idotmatrix-library`).
* [**exPHAT (@exPHAT)**](https://github.com/exPHAT/SwiftBluetooth) — for the clean SwiftBluetooth library.
* [**Eddie Kohler (@kohler)**](https://github.com/kohler/gifsicle) — for `gifsicle`.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
