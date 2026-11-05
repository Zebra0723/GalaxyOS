import Foundation

/// One item in the 🌌 Galaxy menu. The owner sets these up (D22).
struct MenuEntry: Codable, Identifiable, Hashable {
    var title: String
    /// An action ID from `Actions`, e.g. "switchWorld". "separator" draws a line.
    var action: String
    var id: String { title + "|" + action }
}

/// Everything the owner can change, stored as JSON at
/// ~/Library/Application Support/GalaxyOS/settings.json.
/// Galaxy Settings (Phase 2) will be a GUI over this same file.
struct GalaxySettings: Codable {
    /// Minimum bar height in points. On a notched screen the bar is never
    /// shorter than the notch.
    var barHeight: Double
    /// Gap between snapped windows and the screen edges, in points.
    var snapGap: Double
    /// Short name of the macOS account to switch to. Empty = auto-detect.
    var macWorldUser: String
    /// Quit Finder when Galaxy Shell starts.
    var hideFinder: Bool
    /// Action ID → key combo, e.g. "snap.leftHalf": "ctrl+opt+left".
    /// Set a combo to "" to turn that shortcut off.
    var hotkeys: [String: String]
    /// The 🌌 Galaxy menu, top to bottom.
    var galaxyMenu: [MenuEntry]

    static let defaults = GalaxySettings(
        barHeight: 30,
        snapGap: 8,
        macWorldUser: "",
        hideFinder: true,
        hotkeys: [
            "toggleLauncher": "cmd+space",
            "switchWorld": "ctrl+opt+space",
            "snap.leftHalf": "ctrl+opt+left",
            "snap.rightHalf": "ctrl+opt+right",
            "snap.topHalf": "ctrl+opt+up",
            "snap.bottomHalf": "ctrl+opt+down",
            "snap.topLeft": "ctrl+opt+u",
            "snap.topRight": "ctrl+opt+i",
            "snap.bottomLeft": "ctrl+opt+j",
            "snap.bottomRight": "ctrl+opt+k",
            "snap.leftThird": "ctrl+opt+d",
            "snap.centreThird": "ctrl+opt+f",
            "snap.rightThird": "ctrl+opt+g",
            "snap.leftTwoThirds": "ctrl+opt+e",
            "snap.rightTwoThirds": "ctrl+opt+t",
            "snap.full": "ctrl+opt+return",
            "snap.centre": "ctrl+opt+c",
        ],
        galaxyMenu: [
            MenuEntry(title: "Galaxy Settings…", action: "openSettings"),
            MenuEntry(title: "", action: "separator"),
            MenuEntry(title: "Switch to Mac", action: "switchWorld"),
            MenuEntry(title: "Lock Screen", action: "lockScreen"),
            MenuEntry(title: "", action: "separator"),
            MenuEntry(title: "Restart Galaxy Shell", action: "restartShell"),
            MenuEntry(title: "", action: "separator"),
            MenuEntry(title: "Sleep", action: "sleep"),
            MenuEntry(title: "Restart…", action: "restart"),
            MenuEntry(title: "Shut Down…", action: "shutDown"),
        ]
    )
}

extension GalaxySettings {
    /// Missing keys fall back to the defaults, so an old or hand-edited file
    /// never breaks the shell. Hotkeys are merged: you only list the ones you
    /// change.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GalaxySettings.defaults
        barHeight = try c.decodeIfPresent(Double.self, forKey: .barHeight) ?? d.barHeight
        snapGap = try c.decodeIfPresent(Double.self, forKey: .snapGap) ?? d.snapGap
        macWorldUser = try c.decodeIfPresent(String.self, forKey: .macWorldUser) ?? d.macWorldUser
        hideFinder = try c.decodeIfPresent(Bool.self, forKey: .hideFinder) ?? d.hideFinder
        let userHotkeys = try c.decodeIfPresent([String: String].self, forKey: .hotkeys) ?? [:]
        hotkeys = d.hotkeys.merging(userHotkeys) { _, mine in mine }
        galaxyMenu = try c.decodeIfPresent([MenuEntry].self, forKey: .galaxyMenu) ?? d.galaxyMenu
    }
}

final class SettingsStore {
    static let shared = SettingsStore()

    let fileURL: URL
    private(set) var value: GalaxySettings

    private init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("GalaxyOS", isDirectory: true)
        fileURL = dir.appendingPathComponent("settings.json")

        if let data = try? Data(contentsOf: fileURL) {
            do {
                value = try JSONDecoder().decode(GalaxySettings.self, from: data)
            } catch {
                NSLog("GalaxyOS: settings.json has a mistake (\(error)); using defaults for now")
                value = .defaults
            }
        } else {
            value = .defaults
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            save()
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(value) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
