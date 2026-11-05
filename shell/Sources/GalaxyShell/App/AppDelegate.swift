import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = SettingsStore.shared.value

        // Window snapping needs Accessibility access. This shows macOS's
        // one-time prompt if it hasn't been granted yet.
        Permissions.requestAccessibility()

        if settings.hideFinder {
            FinderHider.quitFinderOnce()
        }

        BarController.shared.show()
        _ = LauncherController.shared  // build the launcher panel up front
        registerHotkeys(settings.hotkeys)
    }

    private func registerHotkeys(_ hotkeys: [String: String]) {
        for (actionID, comboString) in hotkeys.sorted(by: { $0.key < $1.key }) {
            // An empty combo means "no shortcut for this action".
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
