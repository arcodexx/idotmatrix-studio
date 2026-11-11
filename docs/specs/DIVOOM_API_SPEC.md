# DIVOOM_API_SPEC: Cloud Gallery Endpoints & Conversion Pipeline

> **Audience**: AI Agents & Backend Integrators  
> **Source Reference**: `idotmatrix-swift/Divoom/` & `idotmatrix-swift/Scripts/divoom_convert.py`  
> **Status**: Reverse-engineered community endpoints (unofficial integration)

---

## 1. Overview & Authentication Flow

The Divoom Community Library enables users to browse and stream thousands of community-crafted pixel art animations. Because Divoom does not offer an official public cloud gallery REST API, this client interfaces with the backend endpoints of the legacy iOS `Aurabox` application.

### Connection Parameters
* **Base URL**: `https://app.divoom-gz.com`
* **User-Agent**: `Aurabox/3.1.10 (iPad; iOS 14.8; Scale/2.00)`
* **Content-Type**: `application/json`

### Authentication (`POST /UserLogin`)
Passwords are not sent in plaintext; they are hashed via **MD5**:
```json
{
  "Email": "user@example.com",
  "Password": "<MD5_HEX_STRING>"
}
```

#### Successful Response (`DivoomLoginResponse`):
```json
{
  "ReturnCode": 0,
  "Message": "Success",
  "UserId": 1234567,
  "Token": 987654321
}
```
* The `UserId` and `Token` integers are stored in memory and included in all subsequent authenticated requests.
* User credentials are encrypted/stored only in macOS `UserDefaults` (`divoom_email`, `divoom_password`).

---

## 2. Gallery Pagination (`POST /GetCategoryFileListV2`)

Retrieves paginated community animations for a specific category:

### Request Payload:
```json
{
  "UserId": 1234567,
  "Token": 987654321,
  "Classify": 18,
  "StartNum": 1,
  "EndNum": 12
}
```

### Supported Categories (`DivoomCategory` enum):
| Category | ID (`Classify`) | Category | ID (`Classify`) |
| :--- | :--- | :--- | :--- |
| **Recommended** | `18` | **Creative** | `9` |
| **Character** | `3` | **Photo** | `12` |
| **Emoji** | `4` | **Top** | `14` |
| **Daily** | `5` | **Gadget** | `15` |
| **Nature** | `6` | **Business** | `16` |
| **Symbol** | `7` | **Festival** | `17` |
| **Pattern** | `8` | **Plant / Animal / Person / Food** | `31 / 32 / 33 / 35` |

---

## 3. Pixel Art Conversion Pipeline (`divoom_convert.py`)

Divoom cloud assets are delivered in multiple proprietary formats:
1. Some files are standard animated GIFs renamed with proprietary extensions.
2. Other files are serialized binary blobs in Divoom's custom **`PixelBean`** format.

### Two-Stage Conversion Architecture:
The embedded script `idotmatrix-swift/Scripts/divoom_convert.py` runs locally on downloaded files:

```
[Remote File Downloaded]
          │
          ▼
┌─────────────────────────────────┐
│ Strategy 1: PIL Direct Open     │ ──(Success)──► [Extract & Resize to 32x32 GIF]
└────────────────┬────────────────┘
                 │ (Fails / Not standard image)
                 ▼
┌─────────────────────────────────┐
│ Strategy 2: Apixoo PixelBean    │ ──(Success)──► [Decode Stream -> Temp GIF -> 32x32]
│             Decoder             │
└─────────────────────────────────┘
                 │
                 ▼
       [Final 32×32 Animated GIF Output]
                 │
                 ▼
       [Streamed over BLE via Gif.swift]
```

* **Resampling Filter**: `Image.NEAREST` (Preserves sharp, crisp pixel art edges without blurry interpolation).
* **Frame Normalization**: Forces dimensions to exactly `32×32` with loops enabled (`loop=0`) and background disposal (`disposal=2`).
