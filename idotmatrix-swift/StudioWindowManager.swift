//
//  StudioWindowManager.swift
//  idotmatrix-swift
//
//  Created for iDotMatrix UI/UX Revamp.
//

import SwiftUI
import AppKit

public class StudioWindowManager: ObservableObject {
    public static let shared = StudioWindowManager()
    private var window: NSWindow?

    private init() {}

    public func open() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let studioView = StudioView()
        let hostingController = NSHostingController(rootView: studioView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 980, height: 660),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        newWindow.title = "iDotMatrix Studio"
        newWindow.titlebarAppearsTransparent = true
        newWindow.titleVisibility = .hidden
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        newWindow.setFrameAutosaveName("iDotMatrixStudioWindow")
        newWindow.contentViewController = hostingController
        newWindow.minSize = NSSize(width: 860, height: 560)

        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    public func close() {
        window?.close()
    }
}
