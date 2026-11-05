# GalaxyOS — Master Plan

> A bespoke, single-user operating system for one MacBook Air (M5), built to be
> better than macOS *for its owner*, and switchable with macOS in about a second.

Status: **Planning** · Owner: zebra0723 · Last updated: 2026-11-05

---

## 0. TL;DR

- **What it is:** a custom Linux-based OS (NixOS core, our own compositor, shell,
  launcher and apps) with a design language and workflow built around one person.
- **How it runs on an M5:** inside a thin native macOS host app called
  **Galaxy Gate**, which boots GalaxyOS full-screen using Apple's
  Virtualization stack. One hotkey flips between GalaxyOS and macOS instantly;
  both stay running.
- **Why not bare metal (yet):** Apple Silicon has no public hardware docs. The
  only native Linux port (Asahi Linux) supports M1/M2 and, at the time of
  writing, not M3 or later. Writing GPU, display, power and trackpad drivers for
  M5 ourselves is a multi-year team effort. So v1 runs virtualised, and the
  system is built so the *same* OS image can boot natively the day M5 is
  supported (Phase 6).
- **What makes it "better than macOS for me":** declarative config with instant
  rollback, a keyboard-first spatial desktop (tiling + floating), one universal
  command bar for everything, scriptable everything, an assistant built into the
  shell, and zero features you don't use.

---

## 1. Goals and non-goals

### Goals
1. **Bespoke.** Every default, shortcut, colour and workflow is chosen for one
   user. No onboarding, no accounts, no telemetry, no upsells.
2. **Better than macOS for daily use.** Faster to navigate, more predictable,
   fully customisable, recoverable from any bad change in seconds.
3. **Easy switching.** macOS ↔ GalaxyOS in ≤ 1 s, with files and clipboard
   shared, and no reboots.
4. **Safe.** It must be impossible for GalaxyOS to damage the macOS install or
   its data.
5. **Reproducible.** The whole OS is defined in this repo. A new or wiped Mac
   gets the identical system from one command.

### Non-goals
- Supporting other users or other hardware.
- Running macOS apps natively inside GalaxyOS (we *hand off* to macOS instead,
  see §6.6).
- Writing our own kernel or drivers from scratch.
- Gaming-grade 3D performance in v1.

---

## 2. Reality check: running a custom OS on an M5

| Approach | Switch speed | Performance | Feasible on M5 today? | Risk to macOS |
|---|---|---|---|---|
| **A. Full-screen VM via Galaxy Gate** (chosen for v1) | Instant (hotkey) | ~90–95% CPU; GPU limited/paravirtualised | **Yes** | None |
| B. Native dual-boot (Asahi-style, m1n1 + U-Boot) | Reboot (~20–40 s) | 100% | **No** (no M3+ support yet) | Low, but touches boot policy |
| C. Custom shell on top of macOS (replace Finder/Dock) | Fast user switch | 100% | Yes | None |
| D. From-scratch kernel | — | — | No (years of reverse-engineering) | — |

**Decision:** Build GalaxyOS as a real, independent OS (A), keep the userland
portable so it moves to bare metal (B) when possible. Approach C is kept as a
fallback idea only; it can't escape macOS's constraints, which defeats the point.

Things to verify on the actual machine before Phase 1 (see §11):
- Exact model, RAM and disk size (affects VM memory budget).
- macOS version (Virtualization.framework features vary by release).
- Current Asahi Linux device support page for M5.

---

## 3. System architecture

```
┌──────────────────────────────── macOS (host) ─────────────────────────────────┐
│                                                                               │
│  Galaxy Gate.app  (Swift, Virtualization.framework / libkrun)                 │
│   ├─ Full-screen borderless window on its own Space                           │
│   ├─ Global hotkey  ⌃⌥Space  → switch Space (GalaxyOS ⇄ macOS)                 │
│   ├─ virtio-gpu display  (native resolution, ProMotion-free 60 Hz)            │
│   ├─ virtio-fs share      ~/Galaxy  ⇄  /home/me/mac                            │
│   ├─ vsock "Bridge" daemon: clipboard, battery, Wi-Fi, notifications,         │
│   │                          open-on-Mac, Touch ID unlock, time sync           │
│   └─ Disk: sparse APFS file  ~/Library/GalaxyOS/galaxy.img (Btrfs inside)      │
│                                                                               │
└───────────────────────────────────────────────────────────────────────────────┘
                                     │
┌──────────────────────────── GalaxyOS (guest) ─────────────────────────────────┐
│  Galaxy Apps      Files · Notes · Terminal · Settings · Mail/Calendar (web)   │
│  Galaxy Shell     top bar · command bar · notifications · lock screen · OSD   │
│  Orbit WM         Wayland compositor (Rust, Smithay) — tiling + floating      │
│  Services         PipeWire · NetworkManager (virtio-net) · galaxy-bridge       │
│  Base             NixOS (aarch64), systemd, Btrfs snapshots                   │
│  Kernel           Linux mainline, trimmed virtio-only config (→ Asahi later)  │
└───────────────────────────────────────────────────────────────────────────────┘
```

### 3.1 Why these choices
- **NixOS base:** the whole OS is one declarative config in this repo. Every
  change is a new "generation"; a broken update is undone by picking the
  previous one at boot. This is the single biggest "better than macOS" feature.
- **Our own compositor (Orbit):** the window manager *is* the personality of
  the OS. Building on Smithay (Rust) gives full control over animations,
  gestures and layout without writing a display server from zero. Fallback for
  early phases: Hyprland or niri, themed, so there is a usable desktop from week 1.
- **Shell in a declarative UI toolkit:** Galaxy Shell is written with
  **Quickshell (QML)** or **AGS/Astal (TypeScript + GTK4)**. Pick one in
  Phase 2 after a one-day prototype in each.
- **Btrfs inside the image:** snapshots before each rebuild; "Time Machine"
  equivalent is a nightly `btrbk` snapshot sent to the macOS side.

---

## 4. The switching experience

Target: feels like swiping between two desktops, not like opening a VM.

| Action | Result |
|---|---|
| Login to macOS | Galaxy Gate auto-starts, boots GalaxyOS in background (~5 s) |
| `⌃⌥Space` anywhere | Jump to the other OS (macOS Space ⇄ Galaxy Space) |
| Four-finger swipe | Same as above (it's a macOS Space) |
| Close lid | Both sleep; GalaxyOS is paused via VM suspend |
| Quit Galaxy Gate | GalaxyOS state saved to disk (VM save/restore), resumes exactly |
| "Open on Mac" in GalaxyOS | Sends file/URL over vsock, macOS opens it and switches |
| `galaxy` CLI on macOS | `galaxy open file.pdf`, `galaxy run cmd`, `galaxy snapshot` |

Optional "Galaxy-first" mode: a dedicated macOS user account whose only login
item is Galaxy Gate in kiosk mode. Logging into that account *is* booting
GalaxyOS. The everyday account stays plain macOS.

---

## 5. Design language — "Galaxy"

- **Mood:** dark-first, deep navy/space black, a single accent colour
  (configurable; default electric violet `#8B5CF6`), subtle starfield on the
  wallpaper layer only.
- **Typography:** Inter for UI, JetBrains Mono for code/terminal. One size scale
  (12/14/16/20/28), one weight pair (400/600).
- **Shape:** 12 px corner radius everywhere, 1 px hairline borders, soft shadows
  only on floating windows.
- **Motion:** spring physics, ≤ 200 ms, every animation interruptible, and a
  global "reduce motion" toggle.
- **Density:** compact by default; the 13" screen is precious.
- **Notch-free:** guest display has no notch, so the top bar is uniform.
- **Theme is code:** one `theme.nix` file feeds the compositor, shell, GTK/Qt,
  terminal and editor. Change a colour once, everything updates.

---

## 6. Core components

### 6.1 Orbit (window manager / compositor)
- Workspaces as a **horizontal strip of "orbits"** (scrollable tiling, like niri),
  plus a floating layer for small tools.
- Layouts per workspace: scroll-tile, grid, monocle, float.
- Trackpad: 3-finger swipe = move between windows, 4-finger = workspaces,
  pinch = overview of everything.
- Keyboard-first: every action has a shortcut; `⌘` (Super) is the modifier, so
  Mac muscle memory mostly carries over (`⌘Q`, `⌘W`, `⌘Tab`, `⌘Space`).
- Window rules in config ("Terminal always on orbit 1, 50% width").
- Session restore: windows and layout come back after reboot.

### 6.2 Galaxy Shell
- **Top bar:** workspace dots · focused app · clock · battery (from host) ·
  network · volume · focus mode. Nothing else.
- **Command bar (`⌘Space`):** one box for apps, files, settings, calculator,
  unit conversion, clipboard history, emoji, window search, shell commands,
  web search, and assistant questions. Plugin API in TypeScript/Lua.
- **Notifications:** quiet by default; a Focus system with schedules.
- **Control centre:** volume, brightness (forwarded to host), Wi-Fi status,
  dark/light, Do Not Disturb, "Switch to macOS" button.
- **Lock screen:** password, or Touch ID via the Bridge (macOS verifies, guest
  receives a signed "unlocked" token).
- **OSD:** volume/brightness pop-ups in Galaxy style.

### 6.3 Galaxy Settings
A GUI over the Nix config. Every toggle writes to `~/galaxy/config/*.nix` and
runs a rebuild, so the GUI and the code never disagree. Includes a
"Generations" page: list of past system versions with one-click rollback.

### 6.4 Built-in apps (thin, themed, replaceable)
| Need | v1 choice | Later |
|---|---|---|
| Terminal | Ghostty or foot, themed | — |
| Files | Nautilus/Thunar, themed | Custom "Nebula" file manager |
| Browser | Firefox or Chromium, themed | — |
| Editor/IDE | VS Code / Zed / Neovim | — |
| Notes | Obsidian or own markdown notes app | Own app |
| Mail / Calendar | Web apps as PWAs | — |
| Music | Spotify web / native client | — |
| Assistant | Shell-integrated Claude client (§6.5) | — |

### 6.5 Assistant layer
- `⌘⇧Space` opens an assistant panel that can see (with permission) the focused
  window's text, selected files, and system state.
- Actions it can take go through an allow-list of shell tools: "move all
  screenshots to ~/Pictures/2026", "set up a Python project here", "why is the
  fan… CPU high?".
- API key stored in the GalaxyOS keyring, never in the repo.

### 6.6 Bridge to macOS (`galaxy-bridge`, vsock)
- Clipboard sync (text + images), both directions.
- Shared folder `~/Galaxy` on macOS ⇄ `~/mac` in GalaxyOS (virtio-fs).
- Battery %, charging state, Wi-Fi SSID → shown in the top bar.
- Brightness and volume keys forwarded to the host.
- "Open on Mac": for apps that only exist on macOS (iMessage, Final Cut, etc.)
  — GalaxyOS has launcher entries for them; picking one switches to macOS and
  opens the app.
- macOS notifications (optionally) mirrored into the Galaxy shell.

---

## 7. Hardware mapping (v1, virtualised)

| Hardware | How GalaxyOS gets it |
|---|---|
| CPU | All performance cores via VM vCPUs (configurable, default = all − 1) |
| RAM | Fixed allocation (e.g. 8 GB of 16 GB) with memory balloon |
| GPU | virtio-gpu. Start with 2D (Virtualization.framework); move to Venus/Vulkan via libkrun/krunkit for acceleration |
| Display | Native panel resolution, integer HiDPI scaling (2×) |
| Keyboard | Passed through; Fn-row handled by Bridge |
| Trackpad | Multitouch gestures are the hardest part — v1 uses pointer + macOS-side gesture capture translated by Galaxy Gate into Orbit actions |
| Audio | virtio-sound / PipeWire |
| Wi-Fi / Bluetooth | Host-managed; guest sees virtio-net. BT devices pair on macOS |
| Camera / mic | Not in v1 |
| Battery / power | Host-managed; values reported over Bridge |
| Touch ID | Via Bridge (macOS LocalAuthentication) |

---

## 8. Security and safety
- The VM cannot touch the macOS disk except the one shared folder.
- GalaxyOS image is encrypted (LUKS inside the image, key in macOS Keychain,
  unlocked by Galaxy Gate).
- No SIP changes, no boot-policy changes, no kernel extensions on macOS in v1.
- Nightly snapshot + weekly copy of the image to the macOS backup destination,
  so Time Machine also covers GalaxyOS.
- Secrets (API keys, Wi-Fi etc.) never committed; `sops-nix` for anything that
  must live in config.

---

## 9. Repository layout

```
GalaxyOS/
├─ docs/                 plans, design notes, decision records (ADR)
├─ gate/                 Galaxy Gate — Swift macOS host app (Xcode/SwiftPM)
├─ bridge/
│   ├─ host/             macOS side of galaxy-bridge (Swift)
│   └─ guest/            Linux side (Rust)
├─ os/
│   ├─ flake.nix         the whole OS definition
│   ├─ hosts/galaxy-vm/  VM-specific hardware config
│   ├─ hosts/galaxy-metal/  future native config (Asahi kernel)
│   ├─ modules/          base, desktop, apps, theme.nix, users
│   └─ kernel/           trimmed kernel config
├─ orbit/                compositor (Rust, Smithay)
├─ shell/                Galaxy Shell (QML or TS)
├─ apps/                 Galaxy-native apps (settings, notes, files…)
├─ cli/                  `galaxy` CLI (macOS + guest)
└─ scripts/              build image, install, update, backup
```

Build pipeline: GitHub Actions on an aarch64 runner (or a Linux builder VM on the
Mac) builds the NixOS image → Galaxy Gate downloads/updates it, or it is built
locally with `galaxy build`.

---

## 10. Roadmap

Each phase ends with something usable every day.

| Phase | Name | Outcome | Rough effort* |
|---|---|---|---|
| 0 | **Launchpad** | Verify hardware/macOS version, repo scaffold, ADRs, design moodboard | 1 week |
| 1 | **First Light** | Galaxy Gate boots a stock NixOS aarch64 VM full-screen with hotkey switch; shared folder works | 2–3 weeks |
| 2 | **Atmosphere** | Themed niri/Hyprland desktop + first Galaxy Shell (bar, command bar, notifications) — daily-drivable | 3–4 weeks |
| 3 | **Bridge** | Clipboard, battery, brightness/volume keys, Open-on-Mac, Touch ID unlock, save/restore on quit | 3 weeks |
| 4 | **Orbit** | Own compositor replaces niri/Hyprland: scroll-tiling, gestures, overview, animations | 6–10 weeks |
| 5 | **Constellation** | Galaxy Settings (GUI over Nix), assistant layer, own Files/Notes apps, GPU acceleration via Venus | 6–8 weeks |
| 6 | **Touchdown** | Native boot path: when Asahi supports M5, add `galaxy-metal` host config, dual-boot via Startup Disk | When upstream allows |

\*Solo, part-time estimates with an AI pair programmer. They will slip; the
phases are ordered so slipping never leaves you without a working system.

### Phase 1 acceptance checklist
- [ ] `galaxy build` produces a bootable aarch64 image
- [ ] Galaxy Gate boots it in < 10 s from cold
- [ ] `⌃⌥Space` switches OS in < 1 s
- [ ] `~/Galaxy` visible inside GalaxyOS
- [ ] Rolling back a broken config works from the boot menu
- [ ] Deleting Galaxy Gate + image leaves macOS exactly as before

---

## 11. Open questions (decide before/at Phase 0)
1. **MacBook specs:** 13" or 15"? RAM? Free disk space? (Need ≥ 16 GB RAM and
   ~100 GB free for a comfortable v1.)
2. **What do you actually do all day?** (Coding? School? Design? Gaming?) This
   decides the default apps and which workflows get custom tooling first.
3. **Which macOS-only apps are must-haves?** They become Open-on-Mac entries.
4. **Shell toolkit:** QML (Quickshell) vs TypeScript (AGS) — prototype both.
5. **Keyboard philosophy:** keep Mac shortcuts (`⌘C/⌘V`) or go Linux-native
   (`Ctrl`)? Recommendation: Mac-style everywhere via keyd remapping.
6. **Name the pieces:** Orbit, Galaxy Shell, Galaxy Gate, Nebula — keep or rename?
7. **Accent colour and wallpaper direction.**

---

## 12. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| No 3D GPU acceleration in VM | Laggy animations, no games | Keep animations GPU-light in v1; pursue Venus via libkrun; native boot later |
| Trackpad gestures in a VM feel worse than macOS | Hurts "better than macOS" | Capture gestures on host side in Galaxy Gate and send as semantic actions |
| Building a compositor is big | Phase 4 drags | Daily-drive niri/Hyprland until Orbit is clearly better |
| Asahi never supports M5 | No native boot | VM path is the product; native is a bonus |
| RAM pressure running two OSes | Swapping | Memory balloon + pause GalaxyOS when idle for long |
| macOS update breaks Galaxy Gate | Can't boot | Gate uses only public APIs; pin & test before updating macOS |

---

## 13. Next actions
1. Answer §11 questions 1–3.
2. Write ADR-001 (VM-first architecture) and ADR-002 (NixOS base).
3. Scaffold `gate/` (Swift app that boots a Linux VM full-screen) and `os/`
   (minimal flake for aarch64 VM).
4. Hit the Phase 1 checklist.
