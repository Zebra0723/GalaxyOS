import AppKit
import ApplicationServices

enum Permissions {
    static var hasAccessibility: Bool { AXIsProcessTrusted() }

    /// Shows macOS's "allow Galaxy Shell to control your computer" prompt
    /// if access hasn't been granted yet. Needed for window snapping.
    static func requestAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }
}

enum FinderHider {
    /// Finder draws the macOS desktop and is relaunched by macOS at login.
    /// The setup script turns its desktop icons off and allows quitting it;
    /// here we quit it once at startup. Opening a folder will still bring
    /// it back until Galaxy Files exists (Phase 4).
    static func quitFinderOnce() {
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder") {
            app.terminate()
        }
    }
}
