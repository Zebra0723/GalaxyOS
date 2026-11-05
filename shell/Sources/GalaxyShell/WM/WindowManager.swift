import AppKit
import ApplicationServices

/// Galaxy WM: floating windows with snapping (D6).
///
/// Uses the Accessibility API to move/resize any app's window.
/// Accessibility coordinates have their origin at the TOP-left of the
/// primary screen; AppKit (NSScreen) uses the BOTTOM-left. `flip` converts.
enum WindowManager {
    static func snapFocusedWindow(_ layout: SnapLayout) {
        guard Permissions.hasAccessibility else {
            Permissions.requestAccessibility()
            return
        }
        guard let window = focusedWindow(), let current = frame(of: window) else {
            NSSound.beep()
            return
        }

        let currentCocoa = flip(current)
        let screen = screenContaining(currentCocoa)
        let gap = CGFloat(SettingsStore.shared.value.snapGap)
        let target = layout.frame(in: usableArea(of: screen), gap: gap)
        setFrame(of: window, to: flip(target))
    }

    /// The screen minus the Galaxy bar.
    static func usableArea(of screen: NSScreen) -> CGRect {
        var area = screen.frame
        if screen == NSScreen.screens.first {
            area.size.height -= BarController.height(for: screen)
        }
        return area
    }

    // MARK: Accessibility helpers

    static func focusedWindow() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return (value as! AXUIElement)
    }

    /// Window frame in Accessibility (top-left) coordinates.
    static func frame(of window: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let posRef, let sizeRef
        else { return nil }
        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(posRef as! AXValue, .cgPoint, &position),
              AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
        else { return nil }
        return CGRect(origin: position, size: size)
    }

    /// Sets a window's frame, given in Accessibility (top-left) coordinates.
    static func setFrame(of window: AXUIElement, to rect: CGRect) {
        var position = rect.origin
        var size = rect.size
        guard let pos = AXValueCreate(.cgPoint, &position),
              let sz = AXValueCreate(.cgSize, &size) else { return }
        // Position, size, then position again: some apps clamp the size
        // against the old position, so the second move fixes the result.
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, pos)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sz)
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, pos)
    }

    // MARK: Geometry

    /// Converts between Cocoa and Accessibility coordinates (works both ways).
    static func flip(_ rect: CGRect) -> CGRect {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        return CGRect(x: rect.minX, y: primaryHeight - rect.maxY,
                      width: rect.width, height: rect.height)
    }

    static func screenContaining(_ cocoaRect: CGRect) -> NSScreen {
        let centre = CGPoint(x: cocoaRect.midX, y: cocoaRect.midY)
        return NSScreen.screens.first(where: { $0.frame.contains(centre) })
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }
}
