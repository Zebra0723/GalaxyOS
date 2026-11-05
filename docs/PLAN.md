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
| D1 | **Two fully separate worlds.** When GalaxyOS is in use there is *no* macOS UI. When macOS is in use there is *no* Galaxy. |
| D2 | **Every app must work** in GalaxyOS: Chrome, Claude, ChatGPT, Bambu Studio, and anything else installed. |
| D3 | **GalaxyOS is its own world on the Mac**: a dedicated "Galaxy" account whose entire visible layer (desktop, bar, launcher, windows, system apps) is replaced by Galaxy components. The normal macOS account stays untouched. macOS stays underneath only as the hardware engine and is never shown. |

### Switching
| # | Decision |
|---|---|
| D4 | **All switching methods**: hotkey, ⇄ button in the Galaxy bar (plus a small "Switch to Galaxy" item in the Mac world), and choosing at the login screen, with **Galaxy as the default world**. |
| D4a | **Switch hotkey is set in Galaxy Settings** (placeholder default ⌃⌥Space until changed). |
| D5 | **A switch never touches anything.** The other world is paused, not closed. Every window, tab and unsaved thing stays exactly as it was left (both sessions keep running via fast user switching). |

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
│  🍎 World 1: "Mac" account      🌌 World 2: "Galaxy" account         │
│  ─────────────────────────      ─────────────────────────────────  │
│  Stock macOS, untouched         Galaxy Shell: bar, launcher,       │
│  + one "Switch to Galaxy"         desktop, control panel,          │
│    menu item                      notifications                    │
│                                 Galaxy WM: floating + snapping     │
│                                 Galaxy apps: Mail, Messages,       │
│                                   Files, Settings, Calendar+Notes, │
│                                   Photos, Calls, Galaxy Link       │
│                                 Your apps: Chrome, Claude,         │
│                                   ChatGPT, Bambu Studio, Spotify…  │
│                                 Galaxy Link body "galaxyos"        │
│                                                                    │
│  Shared by both: installed apps, Wi-Fi, hardware                   │
│  Separate per world: desktop, settings, files, logins              │
│                                                                    │
│  macOS core underneath: drivers, power, networking (never shown)   │
└────────────────────────────────────────────────────────────────────┘
```

### How macOS gets hidden in the Galaxy world
| macOS piece | In the Galaxy world |
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
- The login / user-switch screen is macOS's.
- During a live FaceTime call, the call window itself is FaceTime's.

### Tech stack (proposed)
- **Swift + SwiftUI/AppKit** for the Galaxy Shell and Galaxy apps: native
  speed and full access to the macOS layer underneath.
- **Accessibility API** for Galaxy WM: moving, resizing and snapping any app's
  windows, and reading app menus for the Galaxy bar.
- **galaxy-osd**, a small local service for the Galaxy world. It exposes OS
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

## 4. Switching between worlds

| Way | What happens |
|---|---|
| Hotkey (anywhere) | Jump to the other world |
| ⇄ in the Galaxy bar | Jump to Mac |
| "Switch to Galaxy" item in the Mac menu bar | Jump to Galaxy |
| Login screen | Both worlds shown, Galaxy pre-selected |

Both worlds keep running in the background, so nothing closes and nothing is
lost when you switch (D5).

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
| 1 | **Shell** | Galaxy account set up and macOS UI hidden; Galaxy bar, launcher, floating + snapping WM, control panel, notifications, all switching methods. Clean light theme. **Usable every day.** |
| 2 | **Settings + themes** | Galaxy Settings, the theme engine, customise everything |
| 3 | **Galaxy Link** | galaxyos body, permissions + approvals, Nova/Nebula/Zenith/Comet in their spots, AI theme changes |
| 4 | **Core apps** | Galaxy Files (with iCloud Drive + AirDrop), Galaxy Mail, Galaxy Messages |
| 5 | **More apps** | Galaxy Calendar + Notes, Galaxy Photos, Galaxy Calls |

---

## 7. The Mac

| | |
|---|---|
| Model | MacBook Air M5, **13-inch** |
| Memory | **16 GB** |
| Storage | 494 GB, ~208 GB used (**~286 GB free**) |

What this means:
- **Storage is plenty.** The Galaxy world adds a few GB (shell, Galaxy apps,
  its own files and caches).
- **16 GB is fine but worth watching**, because both worlds stay running in
  the background (D5). macOS compresses and swaps memory automatically, so
  nothing breaks; the Galaxy shell itself should stay light (target under
  300 MB). Galaxy Settings will show how much each world is using.
- **13-inch screen:** the Galaxy bar and snap layouts should be compact by
  default.

---

## 8. Still to plan together
1. Each Galaxy app in detail (starting with the Phase 1 pieces)
