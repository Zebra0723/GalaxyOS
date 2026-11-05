# GalaxyOS — Master Plan

> A bespoke, single-user operating system for one MacBook Air (M5).
> Planned together, decision by decision. This file records what we have
> agreed so far and what is still open.

Status: **Planning** · Last updated: 2026-11-05

---

## 1. Decisions so far

| # | Decision | Notes |
|---|---|---|
| D1 | **Two fully separate worlds.** When GalaxyOS is in use there is *no* macOS UI. When macOS is in use there is *no* Galaxy. | Owner requirement |
| D2 | **Every app must work** in GalaxyOS: Chrome, Claude, ChatGPT, Bambu Studio, and anything else installed. | Rules out a separate Linux OS (no M5 drivers; many apps missing) |
| D3 | **Architecture:** GalaxyOS is its own world on the Mac: a dedicated "Galaxy" account whose entire visible layer (desktop, bar, launcher, windows, system apps) is replaced by Galaxy components. The normal macOS account stays untouched. | macOS stays underneath only as the hardware engine, never shown |
| D4 | **Apple apps are replaced by Galaxy apps** (see §3). | |
| D5 | **AI ecosystem = the existing GalaxyAI family**: Comet (text/iMessage), Orbit (voice), Nova (sight, acts on screen), Nebula (touch/gestures), Zenith (time/commander), all coordinated by **Galaxy Link** (galaxyd + Galaxy Link.app, in NovaAI/galaxy). | GalaxyOS is the home the Galaxy lives in |
| D13 | **Galaxy AI Hub = Galaxy Link**, built into GalaxyOS (bar icon, launcher actions, its own app). | No new hub |
| D14 | **AI permissions start at "ask for everything"** and are loosened step by step, only when the owner says so. | Uses Galaxy Link Approvals |
| D6 | **AIs can control the OS** (open apps, move windows, manage files, run commands), and there is a **dashboard** for them. | Safety rules TBD (§5) |
| D7 | **Look = fully customisable**, no fixed theme. | Default theme TBD |
| D8 | **Switching: all methods** — hotkey, button in the Galaxy bar, choose at login, Galaxy is the default world. | |
| D9 | **Switching never touches anything.** The other world is paused, not closed: every window, tab and unsaved thing stays exactly as left. | Uses macOS fast user switching (sessions keep running) |
| D11 | **Galaxy bar sits at the top**, exactly where the macOS menu bar was. | |
| D12 | **Galaxy Launcher does apps + files and actions** (e.g. "dark mode", "switch to Mac", "open my printing setup"). AI chat and clipboard history are *not* in the launcher. | |
| D10 | **Windows: floating + snapping.** Windows overlap freely; snap to halves/quarters/etc. with keys or by dragging to an edge. | |

### Why not a separate Linux OS?
On an M5, macOS is currently the only system with drivers for the screen,
Wi-Fi, battery and trackpad (Asahi Linux supports M1/M2 only). A Linux-based
GalaxyOS would also lose many apps that the owner needs. So GalaxyOS replaces
**everything you see and touch**, and macOS keeps doing hardware work
invisibly in the background.

### Known limits (accepted)
- The Apple logo at power-on cannot be changed.
- Rare system prompts (privacy permissions, critical updates) are drawn by
  macOS.
- The login/user-switch screen is macOS's (can be minimised with auto-login
  and a hotkey switch, §4).

---

## 2. Architecture

```
┌──────────────── Mac (M5) ────────────────┐
│                                          │
│  World 1: "Mac" account   World 2: "Galaxy" account
│  ───────────────────────  ────────────────────────────
│  Stock macOS, untouched   Galaxy Shell (replaces Dock,
│                           menu bar, Finder desktop,
│                           Spotlight, Mission Control)
│                           Galaxy WM (window manager)
│                           Galaxy apps (Mail, Settings,
│                           Files, AI Hub, Calendar+Notes,
│                           Launcher)
│                           Third-party apps (Chrome,
│                           Claude, ChatGPT, Bambu…)
│                                          │
│  Shared: /Applications, hardware, Wi-Fi  │
│  Separate: desktop, settings, files, logins
│                                          │
│  macOS core underneath both: drivers,    │
│  power, networking (never shown in Galaxy)│
└──────────────────────────────────────────┘
```

### How macOS gets hidden in the Galaxy world
| macOS piece | What happens in Galaxy |
|---|---|
| Dock | Hidden permanently; Galaxy Shell has its own bar/launcher |
| Menu bar | Auto-hidden; Galaxy bar drawn on top (app menus reachable via Galaxy command bar) |
| Finder / desktop icons | Finder quit and kept closed; Galaxy Files + Galaxy desktop |
| Spotlight / Launchpad | Shortcuts reassigned to Galaxy Launcher |
| Mission Control / Spaces | Replaced by Galaxy WM workspaces and overview |
| Notification Centre | Galaxy notifications (macOS banners suppressed where possible) |
| System Settings | Galaxy Settings (writes the same underlying settings) |
| Apple Mail, Calendar, Notes, Reminders | Galaxy Mail, Galaxy Calendar + Notes |
| Wallpaper, cursor, sounds, fonts | Galaxy theme engine |

### Tech stack (proposed, not yet agreed)
- **Swift + SwiftUI/AppKit** for Galaxy Shell and Galaxy apps (native speed,
  full access to macOS APIs underneath).
- **Accessibility API** for Galaxy WM (tiling, moving, resizing any app's
  windows).
- **Local Galaxy daemon** exposing an API that both the shell and the AIs use
  to control the system (see §5).

---

## 3. Galaxy apps (all agreed)

| App | Replaces | First ideas |
|---|---|---|
| **Galaxy Mail** | Apple Mail | All accounts (Gmail etc.) in one inbox; AI summaries and drafts |
| **Galaxy Settings** | System Settings | One searchable page; every setting also editable as a config file |
| **Galaxy Files** | Finder | Fast, keyboard-first, tags, AI search ("the STL I printed last week") |
| **Galaxy AI Hub** | — (new) | Dashboard for the Space family: status, start/stop, logs, chat |
| **Galaxy Calendar + Notes** | Calendar, Notes, Reminders | One app for time and thoughts |
| **Galaxy Launcher** | Spotlight + Launchpad | One search box for apps, files, settings, commands, AIs |

---

## 4. Switching between worlds (agreed)
- **Hotkey** anywhere → switch to the other world.
- **Button** in the Galaxy bar ("Switch to Mac"); a small menu-bar item in the
  Mac world ("Switch to Galaxy").
- **Login screen**: both worlds shown, Galaxy pre-selected.
- **Nothing is ever closed or harmed** by a switch: both sessions keep running
  in the background (fast user switching), so apps, windows and unsaved work
  are exactly as left.

---

## 5. AI control

### Permissions (agreed: D14)
- **Level 0 (start):** every action needs a yes, answered in Galaxy Link
  Approvals, by Nebula thumbs up/down, or by a Galaxy notification.
- Later levels are unlocked one at a time by the owner, e.g. per action type
  ("opening apps is always fine now") or per AI ("Nova can move windows freely").
  Nothing gets more permission automatically.
- Every action any AI takes is logged in Galaxy Link Activity.

### How GalaxyOS plugs into Galaxy Link
- GalaxyOS registers with galaxyd as a new body (`galaxyos`), advertising
  powers such as `open_app`, `move_window`, `snap_window`, `open_file`,
  `switch_world`, `set_setting`, `send_mail`.
- Any member (Nova, Zenith…) asks for an OS action through galaxyd; GalaxyOS
  checks the permission level, asks for approval if needed, then does it.
- galaxyd stays local-only with its token, as today.

### Proposal: where each AI lives in GalaxyOS (not yet agreed)
| AI | Place in GalaxyOS |
|---|---|
| ✦ Nova | Main everyday AI: ⌃Space bar on top of the Galaxy desktop |
| 🪐 Orbit | Greets you with the daily brief when you enter the Galaxy world |
| 🖐️ Nebula | Gestures move/snap Galaxy windows; thumbs up/down for approvals |
| ⏳ Zenith | Running missions shown as a small indicator in the Galaxy bar |
| ☄️ Comet | Its messages show as Galaxy notifications |
| 🔗 Galaxy Link | The AI Hub app + bar icon |

---

## 6. Still to plan together
2. Galaxy WM details: snap layouts, gestures, shortcuts (style agreed: floating + snapping)
3. Galaxy bar contents + notifications (position and launcher scope agreed)
4. Default theme + how customisation works
5. AI control rules + Space family integration (§5)
6. Each Galaxy app in detail
7. Build order / roadmap
