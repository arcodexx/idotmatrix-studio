//
//  MenuBarQuickView.swift
//  idotmatrix-swift
//
//  Created for iDotMatrix UI/UX Revamp.
//

import SwiftUI
import AppKit
import CompactSlider
import DynamicColor

public struct MenuBarQuickView: View {
    @ObservedObject var viewModel: ViewModel = ViewModel.shared

    // 100% pure saturated LED colors (Red, Green, Blue, Yellow, Cyan, Magenta, Orange, White)
    private let colorPresets: [(name: String, color: Color, rgb: (r: Double, g: Double, b: Double))] = [
        ("Red", Color(red: 1.0, green: 0.0, blue: 0.0), (255, 0, 0)),
        ("Green", Color(red: 0.0, green: 1.0, blue: 0.0), (0, 255, 0)),
        ("Blue", Color(red: 0.0, green: 0.0, blue: 1.0), (0, 0, 255)),
        ("Yellow", Color(red: 1.0, green: 1.0, blue: 0.0), (255, 255, 0)),
        ("Cyan", Color(red: 0.0, green: 1.0, blue: 1.0), (0, 255, 255)),
        ("Magenta", Color(red: 1.0, green: 0.0, blue: 1.0), (255, 0, 255)),
        ("Orange", Color(red: 1.0, green: 0.45, blue: 0.0), (255, 115, 0)),
        ("White", Color(red: 1.0, green: 1.0, blue: 1.0), (255, 255, 255))
    ]

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            // Header: Status dot + Label + Styled Icon Action (Disconnect/Connect) + Power toggle
            HStack(alignment: .center, spacing: 8) {
                Circle()
                    .fill(viewModel.deviceStatus == .connected ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)

                Text(viewModel.deviceStatus == .connected ? "Connected" : "Disconnected")
                    .font(.system(size: 11, weight: .semibold))

                // Distinct interactive icon button
                Button(action: {
                    if viewModel.deviceStatus == .connected {
                        viewModel.disconnect()
                    } else {
                        viewModel.searchAgain()
                    }
                }) {
                    Image(systemName: viewModel.deviceStatus == .connected ? "xmark.circle.fill" : "arrow.clockwise.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(viewModel.deviceStatus == .connected ? Color.red : Color.blue)
                }
                .buttonStyle(.plain)
                .help(viewModel.deviceStatus == .connected ? "Disconnect Display" : "Connect Display")

                Spacer()

                // Power button (Green when ON, Gray when OFF)
                Button(action: {
                    if viewModel.screenTurnedOn {
                        viewModel.screenOff()
                    } else {
                        viewModel.screenOn()
                    }
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(viewModel.screenTurnedOn ? .green : .secondary)
                        .help(viewModel.screenTurnedOn ? "Turn Screen Off" : "Turn Screen On")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 4)

            // Centerpiece: Mini Virtual Matrix Display
            VStack(spacing: 6) {
                VirtualMatrixView(size: .mini)

                // Subtitle: Now playing track or current active mode
                if viewModel.isSpotifyEnabled, let track = viewModel.spotifyScript?.currentTrack?.name, !track.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "music.note")
                            .font(.system(size: 9))
                        Text(track)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 180)
                } else {
                    Text(currentModeLabel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            // Brightness Slider
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "sun.min.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", viewModel.brightness))
                        .font(.system(size: 10, weight: .bold).monospacedDigit())
                        .foregroundStyle(.secondary)
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                CompactSlider(value: $viewModel.brightness, in: 5...100, step: 1)
                    .frame(height: 22)
                    .onChange(of: viewModel.brightness) {
                        viewModel.setBrightness()
                    }
            }
            .padding(.horizontal, 2)

            Divider()

            // Quick Mode Selector Pills
            VStack(alignment: .leading, spacing: 8) {
                Text("QUICK MODES")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)

                HStack(spacing: 6) {
                    modeButton(title: "Clock", icon: "clock.fill", isSelected: viewModel.currentScreen == .clock) {
                        viewModel.isSpotifyEnabled = false
                        viewModel.setClock()
                    }

                    modeButton(title: "Music", icon: "music.note", isSelected: viewModel.isSpotifyEnabled) {
                        viewModel.isSpotifyEnabled.toggle()
                    }

                    modeButton(title: "Color", icon: "paintpalette.fill", isSelected: viewModel.currentScreen == .fullscreenColor) {
                        viewModel.isSpotifyEnabled = false
                        viewModel.setFullScreenColor()
                    }

                    modeButton(title: "Effects", icon: "sparkles", isSelected: viewModel.currentScreen == .lightEffect) {
                        viewModel.isSpotifyEnabled = false
                        viewModel.currentScreen = .lightEffect
                        // Rotate to next built-in effect
                        viewModel.lightEffectStyle = (viewModel.lightEffectStyle + 1) % 7
                        viewModel.setLightEffect()
                    }
                }

                // Saturated Color Swatches (revealed when Color mode is active)
                if viewModel.currentScreen == .fullscreenColor {
                    HStack(spacing: 7) {
                        ForEach(colorPresets, id: \.name) { preset in
                            Button(action: {
                                applyPresetColor(r: preset.rgb.r, g: preset.rgb.g, b: preset.rgb.b)
                            }) {
                                Circle()
                                    .fill(preset.color)
                                    .frame(width: 19, height: 19)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.35), lineWidth: 1)
                                    )
                                    .shadow(color: preset.color.opacity(0.3), radius: 2)
                            }
                            .buttonStyle(.plain)
                            .help(preset.name)
                        }

                        // Custom color picker
                        ColorPicker("", selection: Binding(
                            get: { Color(viewModel.color) },
                            set: { newColor in applyCustomColor(newColor) }
                        ))
                        .labelsHidden()
                        .frame(width: 20, height: 20)
                    }
                    .padding(8)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            Divider()

            // Footer: Utility menu + Single clear "Open Studio" button
            HStack {
                Menu {
                    Button("Sync Time") { viewModel.setTime() }
                    Button("Flip Screen (180°)") { viewModel.flipScreen() }
                    Button("Freeze Screen") { viewModel.freezeScreen() }
                    Divider()
                    Button("Quit iDotMatrix") { NSApplication.shared.terminate(nil) }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Spacer()

                Button(action: {
                    StudioWindowManager.shared.open()
                }) {
                    HStack(spacing: 5) {
                        Text("Open Studio")
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 10))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(14)
        .frame(width: 295)
    }

    private func applyPresetColor(r: Double, g: Double, b: Double) {
        viewModel.color = DynamicColor(r: r, g: g, b: b)
        viewModel.setFullScreenColor()
    }

    private func applyCustomColor(_ color: Color) {
        if let nsColor = NSColor(color).usingColorSpace(.sRGB) {
            viewModel.color = DynamicColor(
                r: Double(nsColor.redComponent * 255),
                g: Double(nsColor.greenComponent * 255),
                b: Double(nsColor.blueComponent * 255)
            )
            viewModel.setFullScreenColor()
        }
    }

    private var currentModeLabel: String {
        switch viewModel.currentScreen {
        case .clock: return "Clock Mode"
        case .fullscreenColor: return "Solid Color"
        case .musicIntegration: return "Music Integration"
        case .lightEffect: return "Animation Effect \(viewModel.lightEffectStyle + 1)"
        case .eco: return "Eco Mode"
        case .image: return "Custom Image"
        case .gifImage: return "Animated GIF"
        case .text: return "Text Banner"
        case .scheduler: return "Scheduled Routine"
        default: return "Active"
        }
    }

    @ViewBuilder
    private func modeButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }
}
