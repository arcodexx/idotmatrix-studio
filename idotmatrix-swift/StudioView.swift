//
//  StudioView.swift
//  idotmatrix-swift
//
//  Created for iDotMatrix UI/UX Revamp.
//

import SwiftUI
import AppKit
import CompactSlider
import ColorPickerRing
import DynamicColor

public enum StudioTab: String, CaseIterable, Identifiable {
    case display = "Live Display"
    case pixelArt = "Pixel Art Studio"
    case divoom = "Divoom Library"
    case assets = "My Assets"
    case scheduler = "Daily Scheduler"
    case settings = "Device & Settings"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .display: return "display"
        case .pixelArt: return "paintbrush.fill"
        case .divoom: return "cloud.fill"
        case .assets: return "folder.fill"
        case .scheduler: return "calendar"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct StudioView: View {
    @ObservedObject var viewModel: ViewModel = ViewModel.shared
    @State private var selectedTab: StudioTab = .display

    public init() {}

    public var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 12) {
                // Header badge
                HStack(spacing: 10) {
                    Image(systemName: "photo.tv")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iDotMatrix")
                            .font(.headline)
                        Text(viewModel.statusDescription)
                            .font(.caption)
                            .foregroundStyle(viewModel.deviceStatus == .connected ? .green : .secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 16)
                .padding(.bottom, 6)

                Divider()
                    .padding(.horizontal, 10)

                // Navigation list
                List(StudioTab.allCases, selection: $selectedTab) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.icon)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.vertical, 4)
                    }
                }
                .listStyle(.sidebar)

                Spacer()

                // Bottom connection status bar
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.deviceStatus == .connected ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(viewModel.deviceStatus == .connected ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
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
                }
                .padding(12)
                .background(.ultraThinMaterial)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            // Detail Content
            ZStack {
                switch selectedTab {
                case .display:
                    StudioDisplayDetailView(viewModel: viewModel)
                case .pixelArt:
                    PixelArtEditorView()
                case .divoom:
                    DivoomLibraryView()
                case .assets:
                    AssetsView()
                case .scheduler:
                    SchedulerView()
                        .padding()
                case .settings:
                    StudioSettingsView(viewModel: viewModel)
                }
            }
            .frame(minWidth: 600, minHeight: 520)
        }
    }
}

// MARK: - Studio Live Display Detail View
struct StudioDisplayDetailView: View {
    @ObservedObject var viewModel: ViewModel

    @State private var activeDisplayControl: DisplayControlSubTab = .clock
    @State private var textInput: String = ""

    enum DisplayControlSubTab: String, CaseIterable, Identifiable {
        case clock = "Clock"
        case color = "Color"
        case text = "Text"
        case lightEffect = "Light Effect"
        case music = "Music"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .clock: return "clock.fill"
            case .color: return "paintpalette.fill"
            case .text: return "text.bubble.fill"
            case .lightEffect: return "sparkles"
            case .music: return "music.note"
            }
        }
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 20) {
                // Left Hero Canvas
                VStack(spacing: 14) {
                    Text("Live Matrix Preview")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    VirtualMatrixView(
                        size: .studio
                    )

                    // Quick matrix utility toggles
                    HStack(spacing: 8) {
                        Button(action: {
                            viewModel.flipScreen()
                        }) {
                            Label("Flip", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .controlSize(.small)

                        Button(action: {
                            viewModel.setTime()
                        }) {
                            Label("Sync", systemImage: "clock.arrow.2.circlepath")
                        }
                        .controlSize(.small)

                        Button(action: {
                            if viewModel.screenTurnedOn {
                                viewModel.screenOff()
                            } else {
                                viewModel.screenOn()
                            }
                        }) {
                            Label(viewModel.screenTurnedOn ? "Screen On" : "Screen Off", systemImage: "power")
                        }
                        .controlSize(.small)
                        .tint(viewModel.screenTurnedOn ? .green : .secondary)
                    }

                    // Brightness slider
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("Brightness", systemImage: "sun.max.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.0f%%", viewModel.brightness))
                                .font(.caption.monospacedDigit())
                                .bold()
                        }
                        CompactSlider(value: $viewModel.brightness, in: 5...100, step: 1)
                            .frame(height: 24)
                            .onChange(of: viewModel.brightness) {
                                viewModel.setBrightness()
                            }
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: 260)
                }
                .padding(14)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .frame(width: 275)

                Divider()

                // Right Controls Section
                VStack(alignment: .leading, spacing: 14) {
                    // Control Category Segmented Picker
                    Picker("Control", selection: $activeDisplayControl) {
                        ForEach(DisplayControlSubTab.allCases) { tab in
                            Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 6)

                    VStack(alignment: .leading, spacing: 16) {
                        switch activeDisplayControl {
                        case .clock:
                            clockControls
                        case .color:
                            colorControls
                        case .text:
                            textControls
                        case .lightEffect:
                            lightEffectControls
                        case .music:
                            musicControls
                        }
                    }
                    .padding(.trailing, 8)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .padding(16)
        }
    }

    // MARK: Sub-controls
    @ViewBuilder
    var clockControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Clock Face Styles")
                .font(.headline)

            // 8 Clock Styles Grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64))], spacing: 12) {
                ForEach(1...8, id: \.self) { index in
                    Button(action: {
                        viewModel.clockStyle = index - 1
                        viewModel.setClock()
                    }) {
                        Image("\(index)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(viewModel.clockStyle == index - 1 ? Color.accentColor : Color.clear, lineWidth: 3)
                            )
                            .shadow(radius: viewModel.clockStyle == index - 1 ? 4 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            Toggle("24-Hour Format", isOn: $viewModel.hour24)
                .onChange(of: viewModel.hour24) { viewModel.setClock() }

            Toggle("Display Date", isOn: $viewModel.visibleDate)
                .onChange(of: viewModel.visibleDate) { viewModel.setClock() }

            Divider()

            Text("Clock Color")
                .font(.subheadline)
                .bold()

            ColorPickerRing(color: $viewModel.color, strokeWidth: 26)
                .frame(width: 160, height: 160)
                .frame(maxWidth: .infinity, alignment: .center)
                .onChange(of: viewModel.color) {
                    viewModel.setClock()
                }
        }
    }

    @ViewBuilder
    var colorControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Fullscreen Color")
                .font(.headline)

            ColorPickerRing(color: $viewModel.color, strokeWidth: 32)
                .frame(width: 200, height: 200)
                .frame(maxWidth: .infinity, alignment: .center)
                .onChange(of: viewModel.color) {
                    viewModel.setFullScreenColor()
                }

            Button(action: {
                viewModel.setFullScreenColor()
            }) {
                Label("Apply Fullscreen Color", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    @ViewBuilder
    var textControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Display Text Message")
                .font(.headline)

            TextField("Enter text to display...", text: $textInput)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Send Text Banner") {
                    guard !textInput.isEmpty else { return }
                    viewModel.sendText(textInput)
                }
                .buttonStyle(.borderedProminent)

                Button("Clear") {
                    textInput = ""
                }
            }
        }
    }

    @ViewBuilder
    var lightEffectControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Light Animation Effects")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64))], spacing: 12) {
                ForEach(1...7, id: \.self) { index in
                    Button(action: {
                        viewModel.lightEffectStyle = index - 1
                        viewModel.setLightEffect()
                    }) {
                        Image("\(index)effect")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(viewModel.lightEffectStyle == index - 1 ? Color.accentColor : Color.clear, lineWidth: 3)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    var musicControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Music Integration")
                .font(.headline)

            Toggle("Enable Spotify / Apple Music Integration", isOn: $viewModel.isSpotifyEnabled)

            Toggle("Show Song Title Overlay", isOn: $viewModel.showSongTitle)
                .disabled(!viewModel.isSpotifyEnabled)

            Toggle("Switch to Clock When Music is Paused", isOn: $viewModel.switchToClockOnPause)
                .disabled(!viewModel.isSpotifyEnabled)

            if viewModel.isSpotifyEnabled {
                HStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading) {
                        Text("Active Track Monitoring")
                            .font(.subheadline)
                            .bold()
                        Text("Album art automatically converts to 32x32 and streams to the display.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

// MARK: - Studio Settings View
struct StudioSettingsView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        Form {
            Section("Device Connection") {
                LabeledContent("Status", value: viewModel.statusDescription)
                LabeledContent("Device", value: viewModel.device?.name ?? "None")
                HStack {
                    Button("Search for Devices") {
                        viewModel.searchAgain()
                    }
                    if viewModel.deviceStatus == .connected {
                        Button("Disconnect", role: .destructive) {
                            viewModel.disconnect()
                        }
                    }
                }
            }

            Section("Display Controls") {
                Button("Flip Orientation (180°)") {
                    viewModel.flipScreen()
                }
                Button("Freeze Screen") {
                    viewModel.freezeScreen()
                }
                Button("Synchronize Time") {
                    viewModel.setTime()
                }
            }

            Section("Application") {
                Button("Quit iDotMatrix", role: .destructive) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
