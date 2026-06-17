# Vorssaint

> The free, open-source toolkit that replaces several paid Mac utilities.

<p align="center"><strong><a href="https://vorssaint.com">vorssaint.com</a></strong></p>

[![Release](https://img.shields.io/github/v/release/vorssaint/vorssaint-utils?label=release)](https://github.com/vorssaint/vorssaint-utils/releases)
[![CI](https://github.com/vorssaint/vorssaint-utils/actions/workflows/ci.yml/badge.svg?branch=main&event=push)](https://github.com/vorssaint/vorssaint-utils/actions/workflows/ci.yml)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B%20(Apple%20Silicon)-black)](#requirements)
[![License: GPL-3.0-or-later](https://img.shields.io/badge/license-GPL--3.0--or--later-blue)](LICENSE)

*Leia em [Português (Brasil)](docs/README.pt-BR.md).*

<p align="center">🇺🇸 🇧🇷 🇪🇸 🇩🇪 🇫🇷 🇮🇹 🇯🇵 🇨🇳</p>
<p align="center"><sub>The interface speaks 8 languages, switchable anytime in Settings.</sub></p>

If Vorssaint is useful to you, a quick ⭐ means a lot and helps others find the project. It is, and always will be, 100% free with no subscription; community support is what keeps it alive, so if you'd like to chip in you can [buy me a coffee](https://buymeacoffee.com/vorssaint) ☕.

One small menu bar app that does the jobs you'd otherwise buy a handful of
separate utilities for: keep your Mac awake, see what's slowing it down, set the
volume per app, switch windows, carry files between apps, remove leftovers and
fix a few everyday annoyances.

**Free. Open source. Local.** No account, no subscription, no telemetry.
Nothing leaves your Mac except an update check you can turn off. It's built
with native macOS frameworks, so it stays small and quick.

**Install with [Homebrew](https://brew.sh):**

```sh
brew install --cask vorssaint/tap/vorssaint
```

Already have Vorssaint installed? Adopt your copy into Homebrew with no reinstall: `brew install --cask --adopt vorssaint/tap/vorssaint`. You can also [download the .dmg](https://github.com/vorssaint/vorssaint-utils/releases).

## What it does

Features are configurable from Settings or directly from the panel.

<table>
  <tr>
    <td width="50%" valign="top">
      <strong>⚡ Keep awake, even with the lid closed</strong><br>
      <sub>Run a timer or keep going until you stop it. Closed-lid mode is optional and scoped.</sub><br><br>
      <img src="docs/assets/readme/keep-awake-lid-closed.png" alt="Keep awake and closed-lid controls" width="330">
    </td>
    <td width="50%" valign="top">
      <strong>🌡️ System monitor with history graphs</strong><br>
      <sub>Track CPU, GPU, memory, temperatures, battery details and uptime in one compact panel.</sub><br><br>
      <img src="docs/assets/readme/system-monitor-graph.png" alt="System monitor with live usage graphs" width="330">
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <strong>🌐 Network speed and totals</strong><br>
      <sub>See live upload/download rates, session totals and a built-in speed test.</sub><br><br>
      <img src="docs/assets/readme/network-section.png" alt="Network monitoring section" width="330">
    </td>
    <td width="50%" valign="top">
      <strong>🔋 Power and battery insight</strong><br>
      <sub>Watch system draw, adapter input, battery flow, health and cycles.</sub><br><br>
      <img src="docs/assets/readme/power-section.png" alt="Power and battery monitoring section" width="330">
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <strong>🎚️ Per-app volume mixer</strong><br>
      <sub>Turn one app down or boost it without changing the rest of your Mac.</sub><br><br>
      <img src="docs/assets/readme/volume-mixer.png" alt="Per-app volume mixer" width="330">
    </td>
    <td width="50%" valign="top">
      <strong>🪟 Window switcher</strong><br>
      <sub>Replace ⌘Tab with live window thumbnails, including multiple windows from the same app.</sub><br><br>
      <img src="docs/assets/readme/window-switcher.gif" alt="Window switcher with live thumbnails" width="330">
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <strong>📥 Shelf for temporary files</strong><br>
      <sub>Hold files, images, text and links near the cursor, then drag them anywhere later.</sub><br><br>
      <img src="docs/assets/readme/shelf-demonstration.gif" alt="Shelf holding temporary dragged items" width="330">
    </td>
    <td width="50%" valign="top">
      <strong>🧭 Compact section panel</strong><br>
      <sub>Switch between list and section navigation, with Utilities kept close at hand.</sub><br><br>
      <img src="docs/assets/readme/utilities-section.png" alt="Utilities section in the compact panel" width="330">
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <strong>✂️ Cut and paste files in Finder</strong><br>
      <sub>Use ⌘X and ⌘V to move selected files while text fields keep their normal shortcuts.</sub><br><br>
      <img src="docs/assets/readme/cut-and-paste.gif" alt="Cut and paste files in Finder" width="330">
    </td>
    <td width="50%" valign="top">
      <strong>❌ Quit apps when the last window closes</strong><br>
      <sub>Close the final window and the app quits, with per-app exceptions.</sub><br><br>
      <img src="docs/assets/readme/quit-on-close.gif" alt="App quitting after its last window closes" width="330">
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <strong>🗑️ Remove app leftovers</strong><br>
      <sub>Drop an app onto Settings, review caches, preferences and logs, then move them to the Trash.</sub><br><br>
      <img src="docs/assets/readme/uninstall-demo.gif" alt="Uninstaller finding leftover files" width="330">
    </td>
    <td width="50%" valign="top">
      <strong>🧼 Clean the keyboard safely</strong><br>
      <sub>Cleaning Mode locks the keyboard for a wipe-down and unlocks from the overlay or a repeated-key gesture.</sub><br><br>
      <img src="docs/assets/readme/utilities-section.png" alt="Cleaning Mode inside Utilities" width="330">
    </td>
  </tr>
</table>

### Also included

- **🖱️ Fix the mouse scroll direction**: invert the mouse wheel without touching
  the trackpad's natural scrolling.
- **🧪 Fan Control beta**: a testing entry is available, with manual controls
  disabled until Mac models are validated safely.

## Why it's built this way

- **Free and open source**, under GPL-3.0-or-later. No paywalled tiers.
- **Local by default.** No account, no sign-in, no telemetry. The only network
  call checks GitHub for a new version, and you can turn it off.
- **Native and light.** Plain SwiftUI + AppKit, no external dependencies, a
  single small app instead of several.
- **Optional by design.** Features can be adjusted or disabled, ask for a
  permission only when they need one, and degrade gracefully without it.

## Install

### Homebrew (recommended)
```sh
brew install --cask vorssaint/tap/vorssaint
```
Already have Vorssaint installed and don't want to reinstall it? Adopt your
existing copy into Homebrew instead:
```sh
brew install --cask --adopt vorssaint/tap/vorssaint
```
After that, updates arrive with `brew upgrade --cask vorssaint`.

### Download
Grab the latest DMG from [**Releases**](https://github.com/vorssaint/vorssaint-utils/releases),
open it and drag **Vorssaint** into **Applications**.

Vorssaint is signed with a Developer ID and notarized by Apple, so it opens
normally with no security warning. The stable signing identity also keeps your
granted permissions across updates.

### Official builds and forks
Official Vorssaint builds are distributed only by the project maintainer.
Unofficial forks must use a different name, icon, bundle identifier and signing
identity. The GPL license covers the source code only and does not grant
permission to use the Vorssaint name, logo, icon, bundle identity, trade dress
or official branding. See [TRADEMARKS.md](TRADEMARKS.md).

### Build from source
```sh
git clone https://github.com/vorssaint/vorssaint-utils.git
cd vorssaint-utils
./build.sh            # compile, generate the icon, assemble the signed bundle
./build.sh --install  # same, then install into /Applications and launch
```

### Requirements
- macOS 14 (Sonoma) or newer
- Apple Silicon
- Xcode Command Line Tools (to build from source)

## Permissions

Everything is optional: features degrade gracefully and the onboarding walks you
through each grant.

| Permission | Used by | Without it |
|---|---|---|
| **Accessibility** | Scroll inverter, switcher keyboard, cut & paste, quit on close | Those features stay off |
| **Screen Recording** | Window titles & thumbnails in the switcher | Switcher shows app icons only |
| **Notifications** | Session end & battery protection alerts | Silent operation |
| **Full Disk Access** (optional) | A more thorough uninstaller scan | Scans the accessible locations only |
| **Administrator** (once, optional) | Password-free closed-lid toggling | Password prompt per toggle |

Cut & paste and the uninstaller also ask macOS for Automation consent the first
time they talk to Finder. The shelf needs no permissions.

The first launch opens a short, guided onboarding (language, permissions and an
opt-in page per feature). Revisit it anytime from **Settings › About**.

## Uninstall

```sh
./Tools/uninstall.sh   # from a clone, or download it from the repo
```
It quits the app, unregisters the login item, resets its Accessibility and
Screen Recording permissions, deletes the app, preferences and saved state, and
removes the optional closed-lid `sudoers` rule, leaving nothing behind. Or drag
the app to the Trash and run `tccutil reset All com.vorssaint.utils` to clear
its permissions.

## Architecture

```
Sources/Vorssaint/
├── main.swift                  # entry point (--selftest, --sensors)
├── App/                        # AppDelegate, menu bar status item
├── Core/                       # localization, permissions, defaults
├── Services/                   # all behavior: energy, monitor, scroll, switcher,
│                               #   audio mixer, Finder, auto-quit, uninstall, shelf
├── Support/                    # selftest & sensor dump
└── UI/                         # SwiftUI: panel, settings, onboarding, switcher, shelf
```

Strict separation: **UI** observes **services**. Every user-facing string lives
in `Core/Localization.swift`, compiler-checked for every supported language.

## Contributing

Issues and pull requests are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md) for
the build setup, project conventions and how to add a translation or port the
sensor mapping to a new chip.

## License

The source code is licensed under [GPL-3.0-or-later](LICENSE), copyright
© 2026 Vorssaint. The license covers source code only. Vorssaint branding is
covered separately in [TRADEMARKS.md](TRADEMARKS.md).
