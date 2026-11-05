import AppKit
import Darwin

enum ScreenLock {
    /// Locks the screen immediately, using the same private function as
    /// macOS's own "Lock Screen" menu item (login.framework).
    static func lock() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY),
              let symbol = dlsym(handle, "SACLockScreenImmediate")
        else {
            NSLog("GalaxyOS: couldn't find a way to lock the screen")
            NSSound.beep()
            return
        }
        typealias LockNow = @convention(c) () -> Int32
        _ = unsafeBitCast(symbol, to: LockNow.self)()
    }
}
