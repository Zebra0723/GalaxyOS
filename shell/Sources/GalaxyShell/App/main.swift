import AppKit

// Galaxy Shell runs as a background ("accessory") app: no Dock icon, no
// macOS menu bar of its own. It draws the Galaxy bar and launcher itself.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
