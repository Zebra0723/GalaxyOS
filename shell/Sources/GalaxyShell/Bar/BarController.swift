import AppKit
import SwiftUI

/// The Galaxy bar: a thin panel across the top of the main screen, exactly
/// where the macOS menu bar was (D7). While GalaxyOS is on, the macOS menu
/// bar is auto-hidden (MacChrome) and this panel sits above it.
final class BarController {
    static let shared = BarController()

    let model = BarModel()
    private var panel: NSPanel?

    private init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.layout() }
    }

    /// Never shorter than the notch, so nothing hides behind it.
    static func height(for screen: NSScreen) -> CGFloat {
        max(CGFloat(SettingsStore.shared.value.barHeight), screen.safeAreaInsets.top)
    }

    func show() {
        if let panel {
            layout()
            panel.orderFrontRegardless()
            return
        }
        let p = NSPanel(contentRect: .zero,
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        p.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.hidesOnDeactivate = false
        p.isMovable = false
        p.isReleasedWhenClosed = false
        p.contentView = NSHostingView(rootView: BarView(model: model))
        panel = p
        layout()
        p.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func layout() {
        guard let panel, let screen = NSScreen.screens.first else { return }
        let h = Self.height(for: screen)
        let frame = NSRect(x: screen.frame.minX, y: screen.frame.maxY - h,
                           width: screen.frame.width, height: h)
        panel.setFrame(frame, display: true)
    }
}

final class BarModel: ObservableObject {
    @Published var now = Date()
    @Published var frontAppName = "Galaxy"
    @Published var battery: SystemStatus.Battery?
    @Published var wifiOn = true
    @Published var volume: Float?

    var galaxyMenu: [MenuEntry] { SettingsStore.shared.value.galaxyMenu }

    private var timers: [Timer] = []
    private var observer: NSObjectProtocol?

    init() {
        refreshStatus()
        updateFrontApp(NSWorkspace.shared.frontmostApplication)

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            self?.updateFrontApp(app)
        }

        timers.append(Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.now = Date()
        })
        timers.append(Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        })
    }

    private func updateFrontApp(_ app: NSRunningApplication?) {
        // Ignore Galaxy Shell itself (e.g. while the launcher is open).
        guard let app, app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
        if app.bundleIdentifier == "com.apple.finder" {
            frontAppName = "Galaxy"
        } else {
            frontAppName = app.localizedName ?? "Galaxy"
        }
    }

    func refreshStatus() {
        battery = SystemStatus.battery()
        wifiOn = SystemStatus.wifiOn()
        volume = SystemStatus.outputVolume()
    }
}
