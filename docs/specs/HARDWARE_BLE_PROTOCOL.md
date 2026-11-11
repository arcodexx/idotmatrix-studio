# HARDWARE_BLE_PROTOCOL: Bluetooth Protocol & Packet Layouts

> **Audience**: AI Agents & Firmware Engineers  
> **Hardware Target**: iDotMatrix 32×32 & 16×16 RGB LED Displays (and compatible clones)  
> **Source Reference**: `idotmatrix-swift/ViewModel/` + `python3-idotmatrix-library` by `@derkalle4`

---

## 1. BLE Discovery & Connection Lifecycle

* **Device Advertising Name**: The display advertises with the prefix **`IDM-`** (e.g., `IDM-3232-XXXX`, `IDM-2503-ABCD`).
* **Service & Characteristic**:
  * Discovery filters search for peripheral names starting with `IDM-`.
  * Communication uses standard Nordic UART / custom serial BLE characteristics.
  * Transmission mode: **`.withoutResponse`** (`CBCharacteristicWriteType.withoutResponse`).
  * Reconnection: Handled by `ViewModel.searchAgain()` using `SwiftBluetooth.CentralManager`.

---

## 2. Low-Level Command Packet Reference

All commands follow a binary structure where the **first byte** typically denotes total payload length, followed by command category and parameters.

### 2.1 Power & Brightness Control
| Function | Byte Sequence (Hex / Decimal) | Notes |
| :--- | :--- | :--- |
| **Set Brightness** | `[0x05, 0x00, 0x04, 0x80, <0-100>]` | 5th byte is brightness level `0` to `100`. |
| **Screen On** | `[0x05, 0x00, 0x07, 0x01, 0x01]` | Enables LED matrix power. |
| **Screen Off** | `[0x05, 0x00, 0x07, 0x01, 0x00]` | Disables LEDs (low power standby). |
| **Screen Flip (180°)** | `[0x05, 0x00, 0x06, 0x80, <0|1>]` | Rotates display orientation upside down. |
| **Freeze Frame** | `[0x04, 0x00, 0x03, 0x00]` | Freezes current rendering frame. |

### 2.2 Time & Date Synchronization
Synchronizes the hardware RTC (Real Time Clock):
```text
Data([11, 0, 1, 128, year, month, day, weekday, hour, minute, second])
```
* **Byte 0**: `11` (total packet length)
* **Byte 1–3**: `[0, 1, 128]` (RTC sync command identifier)
* **Byte 4**: `year % 100` (e.g. `26` for 2026)
* **Byte 5**: `month` (1–12)
* **Byte 6**: `day` (1–31)
* **Byte 7**: `weekday` (1–7)
* **Byte 8**: `hour` (0–23)
* **Byte 9**: `minute` (0–59)
* **Byte 10**: `second` (0–59)

### 2.3 Full-Screen Solid Color
Fills all 1,024 LEDs with a single saturated color:
```text
Data([7, 0, 2, 2, R, G, B])
```
* **Bytes**: `[0x07, 0x00, 0x02, 0x02, UInt8(R), UInt8(G), UInt8(B)]`

### 2.4 Built-In Light Effects
The hardware includes native animated lighting presets:
```text
let totalCount = 7 + (3 * colors.count)
Data([totalCount, 0, 3, 2, styleId, 90, colors.count, R1, G1, B1, ...])
```
* **`styleId`**: `1` through `7` (corresponds to presets `1effect` through `7effect`).
* **`90`**: Speed parameter.
* Colors: Appended sequentially as RGB triplets.

---

## 3. Image & Photo Streaming Protocol (32×32 PNG)

Streaming custom static images (including Spotify album art and Pixel Art) uses PNG binary chunking.

### Step 1: Pre-Process to 32×32 PNG
Images are formatted to exact 32×32 PNG dimensions using macOS `sips`:
```bash
/usr/bin/sips -s format png -z 32 32 <input.png> --out <output.png>
```

### Step 2: Switch to Image Mode
```text
Data([5, 0, 4, 1, 1])
```
> **Warning**: Do not send the image mode packet repeatedly if already in image mode (`currentlyDisplayingImage == .image`), as the hardware introduces a noticeable 1-second black blanking interval on mode transition.

### Step 3: Chunking & Header Construction
* Chunk Size: **4,096 bytes** (subdata slices of the PNG file).
* `idk` (Int16 Little Endian): `pngData.count + chunks.count`
* `pngLen` (Int32 Little Endian): `pngData.count`
* Header structure for each chunk (9 bytes):
  ```text
  [idk_byte_0, idk_byte_1, 0, 0, (chunkIndex > 0 ? 2 : 0), pngLen_0, pngLen_1, pngLen_2, pngLen_3]
  ```
* Transmit each chunk: `header + chunkData` sequentially via `sendData(chunk)`.

---

## 4. Text & Marquee Banner Protocol

Text rendering bypasses simple strings and instead converts glyphs into monochromatic bitmaps rendered on the matrix:

* **MTU Safety**: Standard BLE MTU without response is small. Text data is split into **20-byte chunks**.
* **Inter-Packet Delay**: Each 20-byte slice **must** be followed by a **50ms sleep** (`Task.sleep(nanoseconds: 50_000_000)`) to prevent packet dropping on the receiver.
* **Separators**: Text frames are delimited using the hardware separator sequence:
  ```text
  [0x05, 0xFF, 0xFF, 0xFF]
  ```
