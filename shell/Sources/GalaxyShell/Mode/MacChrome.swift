import AppKit

/// Hides and restores macOS's own look (Dock, menu bar, desktop icons,
/// Spotlight shortcut) on the main account (D3).
///
/// Safety: before hiding, the current macOS settings are saved to
/// ~/Library/Application Support/GalaxyOS/mac-look/. The folder's
/// `galaxy-on` file means "the saved copy is the real macOS look; GalaxyOS
/// is on". While it exists we never save again, so a crash or restart can't
/// overwrite the real macOS settings with Galaxy's. `uninstall.sh` uses the
/// same folder to put macOS back if needed.
enum MacChrome {
    static let saveDir: URL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("GalaxyOS/mac-look", isDirectory: true)
    private static var onMarker: URL { saveDir.appendingPathComponent("galaxy-on") }
    private static var menuBarFile: URL { saveDir.appendingPathComponent("menubar-hidden.txt") }

    /// Whole preference domains saved and restored as a unit.
    private static let domains = [
        ("com.apple.dock", "dock.plist"),
        ("com.apple.finder", "finder.plist"),
        ("com.apple.symbolichotkeys", "symbolichotkeys.plist"),
    ]

    /// True if GalaxyOS was on when the shell last stopped (e.g. a crash).
    static var galaxyWasOn: Bool {
        FileManager.default.fileExists(atPath: onMarker.path)
    }

    static func hideMacLook() {
        if !galaxyWasOn {
            saveMacLook()
        }

        // Dock: hidden, and so slow to reveal that it never appears.
        defaults("write", "com.apple.dock", "autohide", "-bool", "true")
        defaults("write", "com.apple.dock", "autohide-delay", "-float", "1000")
        defaults("write", "com.apple.dock", "autohide-time-modifier", "-float", "0")
        defaults("write", "com.apple.dock", "show-recents", "-bool", "false")
        // Finder: no desktop icons, allowed to quit.
        defaults("write", "com.apple.finder", "CreateDesktop", "-bool", "false")
        defaults("write", "com.apple.finder", "QuitMenuItem", "-bool", "true")
        // Spotlight ⌘Space (64) and ⌥⌘Space (65) off, so Galaxy Launcher gets ⌘Space.
        for id in ["64", "65"] {
            defaults("write", "com.apple.symbolichotkeys", "AppleSymbolicHotKeys", "-dict-add", id,
                     "<dict><key>enabled</key><false/></dict>")
        }
        // macOS menu bar: auto-hide (the Galaxy bar sits in its place).
        defaults("write", "-g", "_HIHideMenuBar", "-bool", "true")

        applyChanges()
        if SettingsStore.shared.value.hideFinder {
            FinderHider.quitFinder()
        }
    }

    static func restoreMacLook() {
        guard galaxyWasOn else { return }

        for (domain, file) in domains {
            let url = saveDir.appendingPathComponent(file)
            if FileManager.default.fileExists(atPath: url.path) {
                defaults("import", domain, url.path)
            }
        }
        // The menu bar setting lives in the global domain, which we don't
        // import as a whole (that would undo any other change you made).
        let saved = (try? String(contentsOf: menuBarFile, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        switch saved {
        case "1": defaults("write", "-g", "_HIHideMenuBar", "-bool", "true")
        case "0": defaults("write", "-g", "_HIHideMenuBar", "-bool", "false")
        default: defaults("delete", "-g", "_HIHideMenuBar")
        }

        try? FileManager.default.removeItem(at: onMarker)
        applyChanges()
        run("/usr/bin/open", ["-a", "Finder"])
    }

    // MARK: -

    private static func saveMacLook() {
        try? FileManager.default.createDirectory(at: saveDir, withIntermediateDirectories: true)
        for (domain, file) in domains {
            defaults("export", domain, saveDir.appendingPathComponent(file).path)
        }
        let menuBar = run("/usr/bin/defaults", ["read", "-g", "_HIHideMenuBar"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        try? (menuBar.isEmpty ? "absent" : menuBar).write(to: menuBarFile, atomically: true, encoding: .utf8)
        FileManager.default.createFile(atPath: onMarker.path, contents: Data())
    }

    /// Makes macOS pick up the new settings.
    private static func applyChanges() {
        run("/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings", ["-u"])
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("AppleInterfaceMenuBarHidingChangedNotification"),
            object: nil, userInfo: nil, deliverImmediately: true)
        run("/usr/bin/killall", ["Dock"])
        run("/usr/bin/killall", ["Finder"])
    }

    private static func defaults(_ args: String...) {
        run("/usr/bin/defaults", args)
    }

    /// Runs a command and waits for it. Returns what it printed.
    @discardableResult
    private static func run(_ path: String, _ args: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        let out = Pipe()
        process.standardOutput = out
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            NSLog("GalaxyOS: couldn't run \(path): \(error)")
            return ""
        }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
