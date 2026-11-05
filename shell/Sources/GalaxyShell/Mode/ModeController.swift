import AppKit

enum Mode: String {
    case galaxy, mac
}

/// Flips the main account between GalaxyOS and macOS (D3, D4, D5).
final class ModeController {
    static let shared = ModeController()

    private(set) var mode: Mode = .mac
    var isGalaxy: Bool { mode == .galaxy }

    private init() {}

    /// Called once at launch.
    func start() {
        // If GalaxyOS was on when the shell stopped (crash, restart), stay in
        // it; otherwise follow the setting (GalaxyOS by default).
        let startGalaxy = MacChrome.galaxyWasOn || SettingsStore.shared.value.startInGalaxy
        mode = startGalaxy ? .galaxy : .mac
        WindowSets.shared.adoptRunningApps(into: mode)
        apply(mode)
    }

    func toggle() {
        let old = mode
        let new: Mode = old == .galaxy ? .mac : .galaxy
        WindowSets.shared.leave(old)
        mode = new
        apply(new)
        WindowSets.shared.enter(new)
    }

    private func apply(_ mode: Mode) {
        switch mode {
        case .galaxy:
            MacChrome.hideMacLook()
            BarController.shared.show()
        case .mac:
            LauncherController.shared.hide(restoreFocus: false)
            BarController.shared.hide()
            MacChrome.restoreMacLook()
        }
        registerHotkeys(for: mode)
    }

    /// In macOS only the switch hotkey is active, so Galaxy never gets in the
    /// way there (D1). In GalaxyOS every Galaxy shortcut is on.
    private func registerHotkeys(for mode: Mode) {
        HotKeyCenter.shared.unregisterAll()
        let hotkeys = SettingsStore.shared.value.hotkeys
        for (actionID, comboString) in hotkeys.sorted(by: { $0.key < $1.key }) {
            if mode == .mac && actionID != "switchWorld" { continue }
            if comboString.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            guard let combo = KeyCombo(string: comboString) else {
                NSLog("GalaxyOS: can't understand hotkey '\(comboString)' for \(actionID)")
                continue
            }
            HotKeyCenter.shared.register(combo) {
                Actions.run(actionID)
            }
        }
    }
}
