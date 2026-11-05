import AppKit

/// Gives each OS its own windows (D3a).
///
/// Every app remembers which OS(es) you've used it in. When you leave an OS,
/// apps used ONLY there are hidden (not quit), so their windows stay exactly
/// where they were. When you come back, they're shown again. Apps used in
/// both OSes stay visible in both. Opening a hidden app from the other OS
/// simply makes it shared.
final class WindowSets {
    static let shared = WindowSets()

    private var usedIn: [pid_t: Set<Mode>] = [:]
    private var hiddenWhenLeaving: [Mode: Set<pid_t>] = [:]
    /// Hiding apps makes macOS activate others; ignore those activations.
    private var ignoreActivationsUntil = Date.distantPast

    private init() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                           object: nil, queue: .main) { [weak self] note in
            guard let self, Date() >= self.ignoreActivationsUntil,
                  let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  Self.isTracked(app)
            else { return }
            self.usedIn[app.processIdentifier, default: []].insert(ModeController.shared.mode)
        }
        center.addObserver(forName: NSWorkspace.didTerminateApplicationNotification,
                           object: nil, queue: .main) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            else { return }
            self?.usedIn[app.processIdentifier] = nil
        }
    }

    /// At startup, everything already open counts as part of the current OS.
    func adoptRunningApps(into mode: Mode) {
        for app in Self.trackedApps() {
            usedIn[app.processIdentifier, default: []].insert(mode)
        }
    }

    func leave(_ mode: Mode) {
        ignoreActivationsUntil = Date().addingTimeInterval(1.5)
        var hidden: Set<pid_t> = []
        for app in Self.trackedApps() where !app.isHidden {
            if usedIn[app.processIdentifier] == [mode] {
                app.hide()
                hidden.insert(app.processIdentifier)
            }
        }
        hiddenWhenLeaving[mode] = hidden
    }

    func enter(_ mode: Mode) {
        ignoreActivationsUntil = Date().addingTimeInterval(1.5)
        for pid in hiddenWhenLeaving[mode] ?? [] {
            NSRunningApplication(processIdentifier: pid)?.unhide()
        }
        hiddenWhenLeaving[mode] = []
    }

    private static func isTracked(_ app: NSRunningApplication) -> Bool {
        app.activationPolicy == .regular
            && app.bundleIdentifier != "com.apple.finder"
            && app.bundleIdentifier != Bundle.main.bundleIdentifier
    }

    private static func trackedApps() -> [NSRunningApplication] {
        NSWorkspace.shared.runningApplications.filter(isTracked)
    }
}
