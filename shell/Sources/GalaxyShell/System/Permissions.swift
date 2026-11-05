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
    /// Finder draws the macOS desktop. While GalaxyOS is on, its desktop
    /// icons are off and it may quit; this quits it. Opening a folder will
    /// still bring it back until Galaxy Files exists (Phase 4).
    static func quitFinder() {
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder") {
            app.terminate()
        }
    }
}
