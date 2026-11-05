import AppKit
import Darwin

/// Switches between the Galaxy world and the Mac world (D4, D5).
///
/// Both worlds are macOS accounts, so switching is macOS fast user switching:
/// the other session keeps running and nothing is closed.
///
/// EXPERIMENTAL: macOS has no public API to jump straight to another user.
/// We try the private `SACSwitchToUser` from login.framework first. If that
/// isn't there, we fall back to locking the screen, where macOS shows the
/// account picker (one click on the Mac account).
enum WorldSwitcher {
    static func switchToOtherWorld() {
        if let uid = targetUID(),
           let symbol = loginSymbol("SACSwitchToUser") {
            typealias SwitchToUser = @convention(c) (uid_t) -> Int32
            let switchToUser = unsafeBitCast(symbol, to: SwitchToUser.self)
            if switchToUser(uid) == 0 { return }
            NSLog("GalaxyOS: SACSwitchToUser failed, falling back to the lock screen")
        }
        lockScreen()
    }

    static func lockScreen() {
        if let symbol = loginSymbol("SACLockScreenImmediate") {
            typealias LockNow = @convention(c) () -> Int32
            _ = unsafeBitCast(symbol, to: LockNow.self)()
        } else {
            NSLog("GalaxyOS: couldn't find a way to lock the screen")
            NSSound.beep()
        }
    }

    /// The Mac world account: from settings, or the only other real account.
    static func targetUserName() -> String? {
        let configured = SettingsStore.shared.value.macWorldUser
        if !configured.isEmpty { return configured }

        let me = NSUserName()
        let skip: Set<String> = ["Shared", "Guest", me]
        let homes = (try? FileManager.default.contentsOfDirectory(atPath: "/Users")) ?? []
        let others = homes.filter { !$0.hasPrefix(".") && !skip.contains($0) }
            .filter { getpwnam($0) != nil }
        return others.count == 1 ? others[0] : nil
    }

    private static func targetUID() -> uid_t? {
        guard let name = targetUserName(), let pw = getpwnam(name) else { return nil }
        return pw.pointee.pw_uid
    }

    private static let loginFramework: UnsafeMutableRawPointer? =
        dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY)

    private static func loginSymbol(_ name: String) -> UnsafeMutableRawPointer? {
        guard let handle = loginFramework else { return nil }
        return dlsym(handle, name)
    }
}
