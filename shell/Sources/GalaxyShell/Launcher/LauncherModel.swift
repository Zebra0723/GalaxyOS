import AppKit

struct LauncherItem: Identifiable {
    enum Kind { case app, file, action }

    let id: String
    let title: String
    let subtitle: String
    let kind: Kind
    let icon: NSImage?
    let run: () -> Void
}

final class LauncherModel: ObservableObject {
    @Published var query = "" {
        didSet { if query != oldValue { update() } }
    }
    @Published private(set) var results: [LauncherItem] = []
    @Published var selection = 0
    /// Bumped every time the launcher opens, so the view can refocus.
    @Published private(set) var openCount = 0

    private let apps = AppIndex()
    private let files = FileSearch()
    private var appAndActionResults: [LauncherItem] = []
    private var fileResults: [LauncherItem] = []

    init() {
        files.onResults = { [weak self] urls in
            guard let self else { return }
            self.fileResults = urls.map(Self.fileItem)
            self.publish()
        }
    }

    func prepare() {
        apps.refresh()
        query = ""
        update()
        openCount += 1
    }

    func move(_ delta: Int) {
        guard !results.isEmpty else { return }
        selection = (selection + delta + results.count) % results.count
    }

    var selectedItem: LauncherItem? {
        results.indices.contains(selection) ? results[selection] : nil
    }

    private func update() {
        let q = query.trimmingCharacters(in: .whitespaces)
        fileResults = []
        selection = 0

        if q.isEmpty {
            appAndActionResults = []
            publish()
            files.search("")
            return
        }

        var scored: [(Int, LauncherItem)] = []
        for app in apps.apps {
            if let s = Fuzzy.score(q, app.name) {
                scored.append((s + 20, Self.appItem(app)))  // apps win ties
            }
        }
        for action in Actions.all where action.showInLauncher {
            let best = ([action.title] + action.keywords).compactMap { Fuzzy.score(q, $0) }.max()
            if let best {
                scored.append((best, LauncherItem(id: "action:\(action.id)", title: action.title,
                                                  subtitle: "Action", kind: .action,
                                                  icon: NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil),
                                                  run: action.run)))
            }
        }
        appAndActionResults = scored.sorted { $0.0 > $1.0 }.prefix(8).map { $0.1 }
        publish()
        files.search(q)
    }

    private func publish() {
        results = appAndActionResults + fileResults
        if selection >= results.count { selection = 0 }
    }

    private static func appItem(_ app: AppIndex.App) -> LauncherItem {
        LauncherItem(id: "app:\(app.url.path)", title: app.name, subtitle: "App", kind: .app,
                     icon: NSWorkspace.shared.icon(forFile: app.url.path)) {
            NSWorkspace.shared.openApplication(at: app.url, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    private static func fileItem(_ url: URL) -> LauncherItem {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let folder = url.deletingLastPathComponent().path.replacingOccurrences(of: home, with: "~")
        return LauncherItem(id: "file:\(url.path)", title: url.lastPathComponent, subtitle: folder,
                            kind: .file, icon: NSWorkspace.shared.icon(forFile: url.path)) {
            NSWorkspace.shared.open(url)
        }
    }
}

/// Simple ranking: starts-with beats word-start beats contains beats
/// letters-in-order. Higher is better; nil means no match.
enum Fuzzy {
    static func score(_ query: String, _ text: String) -> Int? {
        let q = query.lowercased()
        let t = text.lowercased()
        if t == q { return 1000 }
        if t.hasPrefix(q) { return 800 - t.count }
        let words = t.split(whereSeparator: { $0 == " " || $0 == "-" || $0 == "_" || $0 == "." })
        if words.contains(where: { $0.hasPrefix(q) }) { return 600 - t.count }
        if t.contains(q) { return 400 - t.count }
        var it = t.makeIterator()
        for ch in q {
            var found = false
            while let c = it.next() { if c == ch { found = true; break } }
            if !found { return nil }
        }
        return 200 - t.count
    }
}

/// Every installed app, found by scanning the usual folders.
final class AppIndex {
    struct App { let name: String; let url: URL }
    private(set) var apps: [App] = []

    private let roots: [URL] = [
        URL(fileURLWithPath: "/Applications"),
        URL(fileURLWithPath: "/Applications/Utilities"),
        URL(fileURLWithPath: "/System/Applications"),
        URL(fileURLWithPath: "/System/Applications/Utilities"),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
    ]

    func refresh() {
        var seen = Set<String>()
        var found: [App] = []
        for root in roots {
            guard let items = try? FileManager.default.contentsOfDirectory(
                at: root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { continue }
            for url in items where url.pathExtension == "app" {
                let name = url.deletingPathExtension().lastPathComponent
                if seen.insert(url.resolvingSymlinksInPath().path).inserted {
                    found.append(App(name: name, url: url))
                }
            }
        }
        apps = found
    }
}

/// File search through Spotlight's index (names only, in your home folder).
final class FileSearch: NSObject {
    var onResults: (([URL]) -> Void)?
    private var query: NSMetadataQuery?

    func search(_ text: String) {
        if let query {
            query.stop()
            NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: query)
        }
        query = nil
        guard text.count >= 2 else { return }

        let q = NSMetadataQuery()
        q.predicate = NSPredicate(format: "%K CONTAINS[cd] %@", NSMetadataItemFSNameKey, text)
        q.searchScopes = [NSMetadataQueryUserHomeScope]
        q.sortDescriptors = [NSSortDescriptor(key: NSMetadataItemFSContentChangeDateKey, ascending: false)]
        NotificationCenter.default.addObserver(self, selector: #selector(finished(_:)),
                                               name: .NSMetadataQueryDidFinishGathering, object: q)
        query = q
        q.start()
    }

    @objc private func finished(_ note: Notification) {
        guard let q = note.object as? NSMetadataQuery, q === query else { return }
        q.disableUpdates()
        var urls: [URL] = []
        for i in 0..<q.resultCount {
            guard urls.count < 8 else { break }
            guard let item = q.result(at: i) as? NSMetadataItem,
                  let path = item.value(forAttribute: NSMetadataItemPathKey) as? String,
                  !path.contains(".app/"), !path.hasSuffix(".app"),
                  !path.contains("/Library/")
            else { continue }
            urls.append(URL(fileURLWithPath: path))
        }
        q.stop()
        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: q)
        onResults?(urls)
    }
}
