# GalaxyOS: Master Plan

> A bespoke, single-user operating system for one MacBook Air (M5).
> Planned together, decision by decision. This file records what we have
> agreed and what is still open.

Status: **Planning** · Last updated: 2026-11-05

---

## 1. Agreed decisions

### The big picture
| # | Decision |
|---|---|
| D1 | **Two operating systems that feel fully separate.** When GalaxyOS is in use there is *no* macOS UI. When macOS is in use there is *no* Galaxy (only the switch hotkey stays active, so you can get back). |
| D2 | **Every app must work** in GalaxyOS: Chrome, Claude, ChatGPT, Bambu Studio, and anything else installed. |
| D3 | **Same account, two OSes.** GalaxyOS runs on the owner's **main macOS account**, so every file, login and app is already there in both. Switching to GalaxyOS replaces the entire visible layer (Dock, menu bar, desktop, Spotlight, window management) with Galaxy's; switching back restores macOS exactly as it was. macOS keeps doing the hardware work underneath. *(Replaces the earlier "separate Galaxy account" plan.)* |
| D3a | **Each OS keeps its own windows.** Apps used only in GalaxyOS hide when you switch to macOS and come back exactly where they were, and the other way round. Apps used in both OSes stay shared and visible in both. |

### Switching
| # | Decision |
|---|---|
| D4 | **Switching methods**: hotkey (works in both OSes) and the ⇄ button in the Galaxy bar. **GalaxyOS is the default** when the Mac starts. (A "choose at login" screen no longer applies with one account.) |
| D4a | **Switch hotkey is set in Galaxy Settings** (placeholder default ⌃⌥Space until changed). |
| D5 | **A switch never closes or harms anything.** Apps are only hidden and shown, never quit, so every window, tab and unsaved thing stays exactly as it was. |

### Desktop
| # | Decision |
|---|---|
| D6 | **Windows: floating + snapping.** Windows overlap freely and snap to halves/quarters/etc. with keys or by dragging to an edge. |
| D6a | **Snap shapes: halves, quarters, thirds (incl. 2/3 + 1/3), full screen and centred.** |
| D6b | **Snapping methods are all built** (drag to edge, key combos, snap menu on the window's top bar) and **chosen/remapped in Galaxy Settings**. |
| D7 | **Galaxy bar at the top, laid out like the Apple menu bar but more bespoke**: 🌌 Galaxy menu (replaces 🍎) · app name + app menus · 🔗 Galaxy Link · ⏳ Zenith missions · approvals waiting · Wi-Fi / volume / battery · time · ⇄ switch to Mac. |
| D8 | **Bluetooth and other controls** live in the Galaxy control panel (opened from the bar), not on the bar itself. |
| D9 | **Galaxy Launcher** does **apps + files** and **actions** ("dark mode", "switch to Mac", "open my printing setup"). No AI chat or clipboard history in the launcher. |
| D10 | **Notifications: normal.** They pop up, fade away, and are kept in a list. No smart filtering for now. |

### Look
| # | Decision |
|---|---|
| D11 | **Everything is customisable**: colours, wallpaper, fonts, sizes, shapes, effects, layout. |
| D12 | **Ways to customise**: Galaxy Settings, and just asking an AI ("make everything purple and glassy"). |
| D13 | **Default look: clean light.** White / soft grey, calm, minimal. |

### Apps
| # | Decision |
|---|---|
| D14 | **Apple apps are replaced by Galaxy apps** (§3). |
| D15 | **Apple-only services**: Apple's own app runs hidden in the background and a Galaxy app sits in front (iMessage, Photos, FaceTime). iCloud Drive + AirDrop are built into Galaxy Files. Music is Spotify. |

### AI
| # | Decision |
|---|---|
| D16 | **The AI ecosystem is the existing GalaxyAI family**: ☄️ Comet (text/iMessage), 🪐 Orbit (voice), ✦ Nova (sight, acts on screen), 🖐️ Nebula (touch/gestures), ⏳ Zenith (time/commander), all coordinated by **🔗 Galaxy Link** (galaxyd + Galaxy Link.app, in `Zebra0723/NovaAI/galaxy`). GalaxyOS is the home the Galaxy lives in. |
| D17 | **Galaxy AI Hub = Galaxy Link**, built into GalaxyOS (bar icon, launcher actions, its own app). |
| D18 | **AIs can control the OS** (open apps, move windows, manage files, run commands). |
| D19 | **AI permissions start at "ask for everything"** and loosen step by step, only when the owner says so. |
| D20 | **Each AI has its own spot** (§5). Orbit gives **no daily brief**; Nebula watches for gestures **only while Fn+F1 is on**. |

### Owner-configured
| # | Decision |
|---|---|
| D22 | **The 🌌 Galaxy menu and the control panel are set up by the owner**, not pre-designed. Galaxy Settings must offer **lots and lots of options**: every item can be added, removed, reordered and restyled. |

### Build order
| # | Decision |
|---|---|
| D21 | **The shell is built first** (bar, launcher, windows, switching), so GalaxyOS becomes usable day to day as early as possible. |

---

## 2. Architecture

### Why not a separate Linux OS?
On an M5, macOS is currently the only system with drivers for the screen,
Wi-Fi, battery and trackpad (Asahi Linux supports M1/M2 only). A Linux-based
GalaxyOS would also lose apps the owner needs (Bambu Studio, Claude desktop,
iMessage…). So GalaxyOS replaces **everything you see and touch**, and macOS
keeps doing hardware work invisibly underneath.

```
┌───────────────────────── MacBook Air (M5) ─────────────────────────┐
│                                                                    │
│            One account · switch hotkey flips between the two       │
│                                                                    │
│  🍎 macOS                        🌌 GalaxyOS                          │
│  ─────────────────────────      ─────────────────────────────────  │
│  Stock macOS look: Dock,        Galaxy Shell: bar, launcher,       │
│  menu bar, Finder desktop,        desktop, control panel,          │
│  Spotlight                        notifications                    │
│                                 Galaxy WM: floating + snapping     │
│                                 Galaxy apps: Mail, Messages,       │
│                                   Files, Settings, Calendar+Notes, │
│                                   Photos, Calls, Galaxy Link       │
│                                 Your apps: Chrome, Claude,         │
│                                   ChatGPT, Bambu Studio, Spotify…  │
│                                 Galaxy Link body "galaxyos"        │
│                                                                    │
│  Shared by both: files, logins, installed apps, Wi-Fi, hardware    │
│  Per OS: the look, shortcuts, and which app windows are showing    │
│                                                                    │
│  macOS core underneath: drivers, power, networking (never shown)   │
└────────────────────────────────────────────────────────────────────┘
```

### How macOS gets hidden while GalaxyOS is on
Switching to GalaxyOS first saves the current macOS look (Dock, Finder,
menu bar, shortcut settings); switching back restores that saved copy. If
Galaxy Shell crashes or restarts while GalaxyOS is on, it comes back in
GalaxyOS and still holds the saved copy, so macOS can always be restored.

| macOS piece | While GalaxyOS is on |
|---|---|
| 🍎 menu bar | Auto-hidden; the Galaxy bar is drawn in its place and shows the app's menus (D7) |
| Dock | Hidden permanently |
| Finder / desktop icons | Finder quit and kept closed; Galaxy Files + Galaxy desktop |
| Spotlight / Launchpad | Shortcuts reassigned to Galaxy Launcher |
| Mission Control / Spaces | Replaced by Galaxy WM |
| Notification Centre | Galaxy notifications |
| Control Centre | Galaxy control panel (Wi-Fi, Bluetooth, sound, display…) |
| System Settings | Galaxy Settings (changes the same settings underneath) |
| Apple apps | Galaxy apps (§3) |
| Wallpaper, cursor, sounds, fonts | Galaxy theme engine |

### Known limits (accepted)
- The Apple logo at power-on can't be changed.
- Rare system prompts (privacy permissions, critical updates) are drawn by macOS.
- The login screen is macOS's.
- Switching takes a second or two (the Dock and Finder restart to change look).
- During a live FaceTime call, the call window itself is FaceTime's.

### Tech stack (proposed)
- **Swift + SwiftUI/AppKit** for the Galaxy Shell and Galaxy apps: native
  speed and full access to the macOS layer underneath.
- **Accessibility API** for Galaxy WM: moving, resizing and snapping any app's
  windows, and reading app menus for the Galaxy bar.
- **galaxy-osd**, a small local service for GalaxyOS. It exposes OS
  actions to the shell, the launcher and Galaxy Link, and enforces AI
  permissions.
- **Theme engine**: one theme file (colours, fonts, radii, effects, layout)
  that every Galaxy component reads live. Galaxy Settings and the AIs edit it.

---

## 3. Galaxy apps

| App | Replaces | Notes |
|---|---|---|
| **Galaxy Launcher** | Spotlight + Launchpad | Apps + files and actions (D9) |
| **Galaxy Settings** | System Settings | One searchable place; also the theme editor |
| **Galaxy Files** | Finder | Includes iCloud Drive and AirDrop (send + received-files inbox) |
| **Galaxy Mail** | Apple Mail | All email accounts arrive here |
| **Galaxy Messages** | Messages | Real iMessage: Apple's Messages runs hidden and does the sending. Comet lives inside it too |
| **Galaxy Calendar + Notes** | Calendar, Notes, Reminders | One app |
| **Galaxy Photos** | Photos | Full iCloud photo library (PhotoKit) |
| **Galaxy Calls** | FaceTime / phone | Start/answer calls Galaxy-style; the live call window is FaceTime's |
| **Galaxy Link** | (new) | The AI Hub: the existing app, built in |

Music: **Spotify** (normal app). Chrome, Claude, ChatGPT, Bambu Studio and the
rest run as they are, inside Galaxy windows.

---

## 4. Switching between GalaxyOS and macOS

| Way | What happens |
|---|---|
| Hotkey (in both OSes) | Flip to the other OS |
| ⇄ in the Galaxy bar | Flip to macOS |
| Starting the Mac | Comes up in GalaxyOS (setting: `startInGalaxy`) |

What a switch does:
1. Hides the apps that were only used in the OS you're leaving (D3a).
2. Changes the look: Galaxy bar/launcher/snapping on or off; Dock, menu bar,
   desktop icons and Spotlight off or back on.
3. Shows the apps that belong to the OS you're entering, exactly where they were.

Nothing is ever quit or closed (D5).

---

## 5. AI in GalaxyOS

### Where each AI lives
| AI | Place in GalaxyOS |
|---|---|
| ✦ Nova | Main everyday AI: ⌃Space bar over the Galaxy desktop |
| 🪐 Orbit | Voice, only when spoken to. No daily brief |
| 🖐️ Nebula | Gestures move/snap Galaxy windows, only while **Fn+F1** is on; thumbs up/down for approvals |
| ⏳ Zenith | Running missions shown in the Galaxy bar |
| ☄️ Comet | Its messages appear as Galaxy notifications and inside Galaxy Messages |
| 🔗 Galaxy Link | The AI Hub app + bar icon |

### Permissions
- **Level 0 (start):** every action needs a yes, answered in Galaxy Link
  Approvals, with a Nebula thumbs up/down, or from a Galaxy notification.
- Later levels are unlocked one at a time, only by the owner: per action type
  ("opening apps is always fine now") or per AI ("Nova can move windows
  freely"). Nothing ever gains permission automatically.
- Every action any AI takes is logged in Galaxy Link Activity.

### How GalaxyOS joins Galaxy Link
- galaxy-osd registers with galaxyd as a new body, `galaxyos`, advertising
  powers like `open_app`, `move_window`, `snap_window`, `open_file`,
  `switch_world`, `set_setting`, `set_theme`, `send_mail`.
- A member (Nova, Zenith…) asks for an OS action through galaxyd. GalaxyOS
  checks the permission level, asks for approval if needed, then does it.
- galaxyd stays local-only, with its token, as it is today.

---

## 6. Roadmap (shell first, D21)

| Phase | Name | What you get |
|---|---|---|
| 1 | **Shell** | Switching between GalaxyOS and macOS on the main account; Galaxy bar, launcher, floating + snapping WM, control panel, notifications, all switching methods. Clean light theme. **Usable every day.** |
| 2 | **Settings + themes** | Galaxy Settings, the theme engine, customise everything |
| 3 | **Galaxy Link** | galaxyos body, permissions + approvals, Nova/Nebula/Zenith/Comet in their spots, AI theme changes |
| 4 | **Core apps** | Galaxy Files (with iCloud Drive + AirDrop), Galaxy Mail, Galaxy Messages |
| 5 | **More apps** | Galaxy Calendar + Notes, Galaxy Photos, Galaxy Calls |

### Phase 1 steps
| Step | What | Status |
|---|---|---|
| 1.1 | Install/uninstall; Galaxy bar (🌌 menu, app name, status, time, ⇄); launcher (apps, files, actions); key snapping; switching on one account with per-OS windows | Written, not yet tested on the Mac (`shell/`) |
| 1.2 | App menus in the bar; drag-to-edge snapping + snap menu | Next |
| 1.3 | Control panel (Wi-Fi, Bluetooth, sound, display…); Galaxy notifications | |
| 1.4 | Polish from daily use | |

---

## 7. The Mac

| | |
|---|---|
| Model | MacBook Air M5, **13-inch** |
| Memory | **16 GB** |
| Storage | 494 GB, ~208 GB used (**~286 GB free**) |

What this means:
- **Storage is plenty.** GalaxyOS adds very little (shell, Galaxy apps,
  caches).
- **16 GB is fine.** With one account there is only one session, so nothing
  runs twice. Hidden apps still use memory (as they would in macOS), and
  the Galaxy shell itself should stay light (target under 300 MB).
- **13-inch screen:** the Galaxy bar and snap layouts should be compact by
  default.

---

## 8. Still to plan together
1. Each Galaxy app in detail (starting with the Phase 1 pieces)
