# Galaxy Shell (Phase 1)

GalaxyOS's desktop: the Galaxy bar, the launcher, window snapping, and
switching between GalaxyOS and macOS on your main account. See [../docs/PLAN.md](../docs/PLAN.md) for the full plan.

> **Not yet tested on a real Mac.** This code was written in a cloud session
> that can't build macOS apps. Expect a few compile fixes the first time.

## What's in this step

| Piece | Status |
|---|---|
| Galaxy bar: 🌌 menu, app name, Wi-Fi, volume, battery, time, ⇄ | ✅ written |
| Galaxy Launcher (⌘Space): apps, files, actions | ✅ written |
| Snapping with keys: halves, quarters, thirds, two-thirds, full, centre | ✅ written |
| Switching GalaxyOS ⇄ macOS on one account (⌃⌥Space or ⇄) | ✅ written |
| Each OS keeps its own windows | ✅ written |
| Install / uninstall scripts | ✅ written |
| App menus (File, Edit…) in the bar | ⏳ next step |
| Snapping by dragging to an edge + snap menu | ⏳ next step |
| Control panel (Wi-Fi, Bluetooth, sound…) | ⏳ next step |
| Galaxy notifications | ⏳ next step |

## Install (on the MacBook)

You need Xcode or the Xcode command-line tools (`xcode-select --install`).
Everything happens on your **main account**: GalaxyOS uses your own files,
logins and apps.

1. Clone this repo and run:

   ```bash
   cd GalaxyOS/shell
   ```

   ```bash
   scripts/build-app.sh --install
   ```

2. Allow **Galaxy Shell** in System Settings › Privacy & Security › Accessibility.
3. Press **⌃⌥Space** to flip between GalaxyOS and macOS.

**Remove it and put macOS's look back:**

```bash
scripts/uninstall.sh
```

## How switching works

| | GalaxyOS on | macOS on |
|---|---|---|
| Galaxy bar, launcher, snapping | ✅ | ❌ (only ⌃⌥Space works, to get back) |
| Dock, macOS menu bar, desktop icons, Spotlight ⌘Space | hidden | ✅ exactly as before |
| Apps used only in this OS | shown where you left them | hidden (not quit) |
| Apps used in both | shown | shown |

- The first time GalaxyOS turns on, it saves a copy of your macOS look
  (Dock, Finder, menu bar and shortcut settings) in
  `~/Library/Application Support/GalaxyOS/mac-look/`. Switching to macOS
  puts that copy back.
- If Galaxy Shell crashes while GalaxyOS is on, it restarts straight back
  into GalaxyOS, still holding the saved copy. `uninstall.sh` can always
  put macOS back from it.
- Each switch takes a second or two, because the Dock and Finder restart to
  change look.
- The Mac starts in GalaxyOS. To start in macOS instead, set
  `"startInGalaxy": false` in settings.json.

## Default shortcuts

All of these can be changed or turned off in `settings.json` (below).

| Keys | Does |
|---|---|
| ⌘Space | Galaxy Launcher |
| ⌃⌥Space | Switch between GalaxyOS and macOS (works in both) |
| ⌃⌥← / → / ↑ / ↓ | Left / right / top / bottom half |
| ⌃⌥U / I / J / K | Top-left / top-right / bottom-left / bottom-right quarter |
| ⌃⌥D / F / G | Left / centre / right third |
| ⌃⌥E / T | Left / right two thirds |
| ⌃⌥Return | Full screen |
| ⌃⌥C | Centre |

## Settings

Until Galaxy Settings exists (Phase 2), everything lives in
`~/Library/Application Support/GalaxyOS/settings.json`. Open it from
🌌 › Galaxy Settings… and restart the shell (🌌 › Restart Galaxy Shell) after
editing. You only need to list what you change. For example:

```json
{
  "hotkeys": { "switchWorld": "cmd+opt+g", "snap.centre": "" },
  "snapGap": 12,
  "galaxyMenu": [
    { "title": "Switch to Mac", "action": "switchWorld" },
    { "title": "", "action": "separator" },
    { "title": "Sleep", "action": "sleep" }
  ]
}
```

(`fn` isn't a valid modifier for hotkeys; use cmd / opt / ctrl / shift.)
Only `switchWorld` works while you're in macOS; every other shortcut is
GalaxyOS-only.

Action IDs: `toggleLauncher`, `switchWorld`, `lockScreen`, `toggleDarkMode`,
`openSettings`, `restartShell`, `sleep`, `restart`, `shutDown`,
`snap.leftHalf`, `snap.rightHalf`, `snap.topHalf`, `snap.bottomHalf`,
`snap.topLeft`, `snap.topRight`, `snap.bottomLeft`, `snap.bottomRight`,
`snap.leftThird`, `snap.centreThird`, `snap.rightThird`,
`snap.leftTwoThirds`, `snap.rightTwoThirds`, `snap.full`, `snap.centre`.

## First-run test checklist

- [ ] `swift build` succeeds (paste any errors back into the session)
- [ ] After install, GalaxyOS turns on: the Dock, macOS menu bar and desktop icons disappear
- [ ] Galaxy bar appears at the top, no gap, not hidden by the notch
- [ ] The macOS menu bar doesn't show through when the mouse touches the top
- [ ] 🌌 menu opens and every item works
- [ ] Battery, Wi-Fi, volume and clock look right and update
- [ ] ⌘Space opens the Galaxy Launcher; typing finds apps, files and actions; ↑↓ Return Esc work
- [ ] Every snap shortcut works in Chrome, Bambu Studio and Terminal
- [ ] ⌃⌥Space → macOS: Dock, menu bar, desktop icons and Spotlight come back exactly as before
- [ ] In macOS, ⌘Space opens Spotlight and the snap shortcuts do nothing
- [ ] An app opened only in GalaxyOS is hidden in macOS, and comes back in the same place
- [ ] An app used in both stays visible in both
- [ ] Nothing ever quits or loses unsaved work when switching
- [ ] `uninstall.sh` puts macOS back fully
