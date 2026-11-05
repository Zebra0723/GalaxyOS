import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Window snapping needs Accessibility access. This shows macOS's
        // one-time prompt if it hasn't been granted yet.
        Permissions.requestAccessibility()

        _ = LauncherController.shared  // build the launcher panel up front
        _ = WindowSets.shared          // start tracking which OS each app is used in
        ModeController.shared.start()  // GalaxyOS or macOS, plus hotkeys
    }
}
