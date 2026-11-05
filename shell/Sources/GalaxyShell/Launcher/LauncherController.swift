import AppKit
import SwiftUI

private final class LauncherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// Galaxy Launcher: one box for apps + files and actions (D9).
final class LauncherController: NSObject, NSWindowDelegate {
    static let shared = LauncherController()

    private let panel: LauncherPanel
    private let model = LauncherModel()
    private var previousApp: NSRunningApplication?

    private override init() {
        panel = LauncherPanel(
            contentRect: NSRect(x: 0, y: 0, width: LauncherView.width, height: LauncherView.height),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered, defer: false)
        super.init()

        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            panel.standardWindowButton(button)?.isHidden = true
        }
        panel.isMovable = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.contentView = NSHostingView(rootView: LauncherView(model: model) { [weak self] item in
            self?.choose(item)
        } onCancel: { [weak self] in
            self?.hide(restoreFocus: true)
        })
    }

    func toggle() {
        panel.isVisible ? hide(restoreFocus: true) : show()
    }

    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication
        model.prepare()

        if let screen = NSScreen.main {
            let f = screen.frame
            let origin = NSPoint(x: f.midX - LauncherView.width / 2,
                                 y: f.minY + f.height * 0.62 - LauncherView.height / 2)
            panel.setFrameOrigin(origin)
        }
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    func hide(restoreFocus: Bool) {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
        if restoreFocus, let previousApp, previousApp.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApp.activate()
        }
    }

    private func choose(_ item: LauncherItem) {
        switch item.kind {
        case .app, .file:
            hide(restoreFocus: false)
        case .action:
            // Actions like snapping work on the app you came from.
            hide(restoreFocus: true)
        }
        // Give focus a moment to settle before running.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { item.run() }
    }

    func windowDidResignKey(_ notification: Notification) {
        hide(restoreFocus: false)
    }
}
