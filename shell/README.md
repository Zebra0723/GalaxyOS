# Galaxy Shell (Phase 1)

The Galaxy world's desktop: the Galaxy bar, the launcher, window snapping
and world switching. See [../docs/PLAN.md](../docs/PLAN.md) for the full plan.

> **Not yet tested on a real Mac.** This code was written in a cloud session
> that can't build macOS apps. Expect a few compile fixes the first time.

## What's in this step

| Piece | Status |
|---|---|
| Galaxy bar: 🌌 menu, app name, Wi-Fi, volume, battery, time, ⇄ | ✅ written |
| Galaxy Launcher (⌘Space): apps, files, actions | ✅ written |
| Snapping with keys: halves, quarters, thirds, two-thirds, full, centre | ✅ written |
| Switching to the Mac world (⌃⌥Space or ⇄) | ⚠️ experimental (see below) |
| Setup / undo scripts for the Galaxy account | ✅ written |
| App menus (File, Edit…) in the bar | ⏳ next step |
| Snapping by dragging to an edge + snap menu | ⏳ next step |
| Control panel (Wi-Fi, Bluetooth, sound…) | ⏳ next step |
| Galaxy notifications | ⏳ next step |
| "Switch to Galaxy" item in the Mac world | ⏳ next step |

## Install (on the MacBook)

You need Xcode or the Xcode command-line tools (`xcode-select --install`).

1. **Make the Galaxy account.** In System Settings › Users & Groups, add a new
   account (e.g. `galaxy`, shown as "Galaxy"). Turn on fast user switching
   (Control Centre › Fast User Switching).
2. **Log into the Galaxy account**, clone this repo, and run:

   ```bash
   cd GalaxyOS/shell
   ```

   ```bash
   scripts/setup-galaxy-world.sh
   ```

   ```bash
   scripts/build-app.sh --install
   ```

3. Allow **Galaxy Shell** in System Settings › Privacy & Security › Accessibility.
4. Log out and back in once.

Never run these in your normal Mac account. `build-app.sh --install` refuses
to install in an account that wasn't set up as the Galaxy world.

**Undo everything** (from the Galaxy account):

```bash
scripts/undo-galaxy-world.sh
```

## Default shortcuts

All of these can be changed or turned off in `settings.json` (below).

| Keys | Does |
|---|---|
| ⌘Space | Galaxy Launcher |
| ⌃⌥Space | Switch to Mac |
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

Action IDs: `toggleLauncher`, `switchWorld`, `lockScreen`, `toggleDarkMode`,
`openSettings`, `restartShell`, `sleep`, `restart`, `shutDown`,
`snap.leftHalf`, `snap.rightHalf`, `snap.topHalf`, `snap.bottomHalf`,
`snap.topLeft`, `snap.topRight`, `snap.bottomLeft`, `snap.bottomRight`,
`snap.leftThird`, `snap.centreThird`, `snap.rightThird`,
`snap.leftTwoThirds`, `snap.rightTwoThirds`, `snap.full`, `snap.centre`.

## About world switching

macOS has no public way for an app to jump straight to another account.
Galaxy Shell first tries a private macOS function (`SACSwitchToUser`). If
that isn't available, it locks the screen instead, and macOS shows the account
picker, where you click your Mac account. Either way it's fast user switching,
so both worlds keep running and nothing closes (D5). If there's more than one
other account, set `"macWorldUser"` in settings.json to your Mac account's
short name.

## First-run test checklist

- [ ] `swift build` succeeds (paste any errors back into the session)
- [ ] Galaxy bar appears at the top, no gap, not hidden by the notch
- [ ] The macOS menu bar doesn't show through when the mouse touches the top
- [ ] 🌌 menu opens and every item works
- [ ] Battery, Wi-Fi, volume and clock look right and update
- [ ] ⌘Space opens the launcher; typing finds apps, files and actions; ↑↓ Return Esc work
- [ ] Every snap shortcut works in Chrome, Bambu Studio and Terminal
- [ ] ⌃⌥Space switches to the Mac world, and switching back leaves every window as it was
- [ ] Dock and desktop icons never appear
- [ ] `undo-galaxy-world.sh` restores the account fully
