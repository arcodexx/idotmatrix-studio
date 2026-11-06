//
//  VirtualMatrixView.swift
//  idotmatrix-swift
//
//  Created for iDotMatrix UI/UX Revamp.
//

import SwiftUI
import AppKit

public struct VirtualMatrixView: View {
    public enum DisplaySize {
        case mini    // ~110x110 for MenuBar popover
        case studio  // ~240x240 for Studio workspace
        case custom(width: CGFloat, height: CGFloat)

        var dimension: CGFloat {
            switch self {
            case .mini: return 110
            case .studio: return 240
            case .custom(let width, _): return width
            }
        }

        var dotSpacingRatio: CGFloat {
            switch self {
            case .mini: return 0.82
            case .studio: return 0.85
            case .custom: return 0.84
            }
        }
    }

    @ObservedObject var viewModel: ViewModel = ViewModel.shared
    var size: DisplaySize = .mini
    var overridePixels: [[Color]]? = nil
    var overrideImage: NSImage? = nil

    @State private var cachedImagePixels: [[Color]]? = nil
    @State private var lastImageProcessed: NSImage? = nil

    public init(
        size: DisplaySize = .mini,
        overridePixels: [[Color]]? = nil,
        overrideImage: NSImage? = nil
    ) {
        self.size = size
        self.overridePixels = overridePixels
        self.overrideImage = overrideImage
    }

    public var body: some View {
        let dim = size.dimension

        ZStack {
            // Bezel frame
            RoundedRectangle(cornerRadius: size == .mini ? 10 : 14)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: size == .mini ? 10 : 14)
                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 2)

            // Inner dark LED grid backplate with periodic updates
            RoundedRectangle(cornerRadius: size == .mini ? 8 : 10)
                .fill(Color(red: 0.05, green: 0.05, blue: 0.06))
                .padding(size == .mini ? 6 : 10)
                .overlay(
                    TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
                        Canvas { context, canvasSize in
                            renderMatrix(context: context, size: canvasSize, date: timeline.date)
                        }
                    }
                    .padding(size == .mini ? 8 : 12)
                )
        }
        .frame(width: dim, height: dim)
        .onAppear {
            updateImageCacheIfNeeded()
        }
        .onChange(of: viewModel.currentPreviewImage) {
            updateImageCacheIfNeeded()
        }
        .onChange(of: viewModel.currentScreen) {
            updateImageCacheIfNeeded()
        }
        .onChange(of: viewModel.lightEffectStyle) {
            updateImageCacheIfNeeded()
        }
        .onChange(of: overrideImage) {
            updateImageCacheIfNeeded()
        }
    }

    private func renderMatrix(context: GraphicsContext, size: CGSize, date: Date) {
        let cols = 32
        let rows = 32
        let cellWidth = size.width / CGFloat(cols)
        let cellHeight = size.height / CGFloat(rows)
        let dotRadius = min(cellWidth, cellHeight) * (self.size.dotSpacingRatio / 2.0)

        let offColor = Color(red: 0.11, green: 0.11, blue: 0.13)
        let isScreenOn = viewModel.screenTurnedOn

        // Determine if image/art/effect thumbnail should be shown
        let shouldShowImage = overridePixels != nil || overrideImage != nil ||
            viewModel.currentScreen == .lightEffect ||
            viewModel.currentlyDisplayingImage == .image ||
            viewModel.currentScreen == .gifImage ||
            (viewModel.isSpotifyEnabled && !viewModel.currentArtworkUrlString.isEmpty)

        for y in 0..<rows {
            for x in 0..<cols {
                let centerX = CGFloat(x) * cellWidth + (cellWidth / 2.0)
                let centerY = CGFloat(y) * cellHeight + (cellHeight / 2.0)
                let dotRect = CGRect(
                    x: centerX - dotRadius,
                    y: centerY - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                )

                var pixelColor: Color = offColor

                if isScreenOn {
                    if let override = overridePixels, y < override.count, x < override[y].count {
                        pixelColor = override[y][x]
                    } else if shouldShowImage, let cached = cachedImagePixels, y < cached.count, x < cached[y].count {
                        pixelColor = cached[y][x]
                    } else {
                        pixelColor = defaultColorForCurrentMode(x: x, y: y, date: date)
                    }
                }

                // Sharp LED Base Circle
                context.fill(Path(ellipseIn: dotRect), with: .color(pixelColor))
            }
        }
    }

    private func defaultColorForCurrentMode(x: Int, y: Int, date: Date) -> Color {
        let offColor = Color(red: 0.11, green: 0.11, blue: 0.13)

        switch viewModel.currentScreen {
        case .fullscreenColor:
            return Color(viewModel.color)

        case .clock:
            return clockPixelColor(x: x, y: y, date: date)

        case .text:
            // Text mode representation
            return (y >= 12 && y <= 19 && (x % 3 == 0 || y == 15)) ? Color(viewModel.color) : offColor

        case .eco:
            let dx = x - 16
            let dy = y - 16
            if dx*dx + dy*dy < 40 && (dx > -2 || dy < -1) {
                return Color.green.opacity(0.8)
            }
            return offColor

        default:
            return clockPixelColor(x: x, y: y, date: date)
        }
    }

    private func clockPixelColor(x: Int, y: Int, date: Date) -> Color {
        let clockColor = Color(viewModel.color)
        let offColor = Color(red: 0.11, green: 0.11, blue: 0.13)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)

        let displayHour: Int
        if viewModel.hour24 {
            displayHour = hour
        } else {
            let h = hour % 12
            displayHour = h == 0 ? 12 : h
        }
        let timeStr = String(format: "%02d:%02d", displayHour, minute)

        // Center on 32x32:
        let startX = 6
        let startY = 13

        var currentX = startX
        for char in timeStr {
            if char == ":" {
                let showColon = second % 2 == 0
                if showColon && (x == currentX + 1) && (y == startY + 1 || y == startY + 3) {
                    return clockColor
                }
                currentX += 3
            } else if let digit = char.wholeNumberValue {
                if isDigitPixel(digit: digit, dx: x - currentX, dy: y - startY) {
                    return clockColor
                }
                currentX += 4
            }
        }
        return offColor
    }

    private func isDigitPixel(digit: Int, dx: Int, dy: Int) -> Bool {
        guard dx >= 0 && dx < 3 && dy >= 0 && dy < 5 else { return false }
        let masks: [Int] = [
            0b111_101_101_101_111, // 0
            0b010_110_010_010_111, // 1
            0b111_001_111_100_111, // 2
            0b111_001_111_001_111, // 3
            0b101_101_111_001_001, // 4
            0b111_100_111_001_111, // 5
            0b111_100_111_101_111, // 6
            0b111_001_001_001_001, // 7
            0b111_101_111_101_111, // 8
            0b111_101_111_001_111  // 9
        ]
        let mask = masks[digit]
        let bitIndex = 14 - (dy * 3 + dx)
        return ((mask >> bitIndex) & 1) == 1
    }

    private func updateImageCacheIfNeeded() {
        let imageToProcess: NSImage?
        if let override = overrideImage {
            imageToProcess = override
        } else if viewModel.currentScreen == .lightEffect {
            imageToProcess = NSImage(named: "\(viewModel.lightEffectStyle + 1)effect")
        } else {
            imageToProcess = viewModel.currentPreviewImage
        }

        guard let img = imageToProcess else {
            cachedImagePixels = nil
            lastImageProcessed = nil
            return
        }

        guard img !== lastImageProcessed else { return }
        lastImageProcessed = img

        guard let tiffData = img.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return
        }

        var pixels: [[Color]] = Array(repeating: Array(repeating: Color.clear, count: 32), count: 32)
        let sampleW = bitmap.pixelsWide
        let sampleH = bitmap.pixelsHigh

        for y in 0..<32 {
            for x in 0..<32 {
                let srcX = Int((Double(x) / 32.0) * Double(sampleW))
                let srcY = Int((Double(y) / 32.0) * Double(sampleH))
                if let nsColor = bitmap.colorAt(x: min(srcX, sampleW - 1), y: min(srcY, sampleH - 1)) {
                    pixels[y][x] = Color(nsColor: nsColor)
                }
            }
        }
        self.cachedImagePixels = pixels
    }
}

extension VirtualMatrixView.DisplaySize: Equatable {}
