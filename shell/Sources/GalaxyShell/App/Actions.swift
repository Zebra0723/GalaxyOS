import AppKit

/// Everything Galaxy can *do*, by ID. Hotkeys, the 🌌 menu and the launcher
/// all run actions from here, so one ID works everywhere.
struct GalaxyAction {
    let id: String
    let title: String
    /// Extra words the launcher matches on.
    let keywords: [String]
    let showInLauncher: Bool
    let run: () -> Void
}

enum Actions {
    static let all: [GalaxyAction] = {
        var list: [GalaxyAction] = [
            GalaxyAction(id: "toggleLauncher", title: "Galaxy Launcher", keywords: [],
                         showInLauncher: false) { LauncherController.shared.toggle() },
            GalaxyAction(id: "switchWorld", title: "Switch to macOS", keywords: ["mac", "macos", "switch"],
                         showInLauncher: true) { ModeController.shared.toggle() },
            GalaxyAction(id: "lockScreen", title: "Lock Screen", keywords: ["lock"],
                         showInLauncher: true) { ScreenLock.lock() },
            GalaxyAction(id: "toggleDarkMode", title: "Dark Mode / Light Mode", keywords: ["dark", "light", "appearance", "theme"],
                         showInLauncher: true) { runAppleScript(#"tell application "System Events" to tell appearance preferences to set dark mode to not dark mode"#) },
            GalaxyAction(id: "openSettings", title: "Galaxy Settings", keywords: ["settings", "preferences", "config"],
                         showInLauncher: true) { NSWorkspace.shared.open(SettingsStore.shared.fileURL) },
            GalaxyAction(id: "restartShell", title: "Restart Galaxy Shell", keywords: ["reload"],
                         showInLauncher: true) { exit(0) },  // the launch agent starts it again
            GalaxyAction(id: "sleep", title: "Sleep", keywords: ["sleep"],
                         showInLauncher: true) { runProcess("/usr/bin/pmset", ["sleepnow"]) },
            GalaxyAction(id: "restart", title: "Restart Mac", keywords: ["reboot"],
                         showInLauncher: true) { confirmThen("Restart the Mac?") { runAppleScript(#"tell application "System Events" to restart"#) } },
            GalaxyAction(id: "shutDown", title: "Shut Down Mac", keywords: ["power off", "turn off"],
                         showInLauncher: true) { confirmThen("Shut down the Mac?") { runAppleScript(#"tell application "System Events" to shut down"#) } },
        ]
        for layout in SnapLayout.allCases {
            list.append(GalaxyAction(id: "snap.\(layout.rawValue)", title: "Snap: \(layout.title)", keywords: [],
                                     showInLauncher: false) { WindowManager.snapFocusedWindow(layout) })
        }
        return list
    }()

    static func run(_ id: String) {
        guard let action = all.first(where: { $0.id == id }) else {
            NSLog("GalaxyOS: unknown action '\(id)'")
            NSSound.beep()
            return
        }
        action.run()
    }

    static func title(for id: String) -> String? {
        all.first(where: { $0.id == id })?.title
    }

    // MARK: helpers

    private static func runAppleScript(_ source: String) {
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error { NSLog("GalaxyOS: AppleScript failed: \(error)") }
    }

    private static func runProcess(_ path: String, _ args: [String]) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        try? p.run()
    }

    /// Galaxy-drawn confirm for actions that end the session.
    private static func confirmThen(_ question: String, _ action: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = question
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn { action() }
    }
}
