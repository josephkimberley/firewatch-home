# Running Firewatch Home

[Back to the README](../README.md) · [Customisation](CUSTOMIZATION.md) · [Codex / Claude prompts](AI_ASSISTED_SETUP.md)

## Current status

**Developer preview: this checkout is not yet a complete installable app.** The screenshots show a working development TV, not a tested installation from this repository on a fresh TV. There is no supported download-and-run package yet.

| What you want to do | Available now? |
| --- | --- |
| Browse/download the included wallpapers | Yes: [artwork gallery](GALLERY.md) |
| Inspect and modify the QML, JavaScript and shaders | Yes |
| Validate a proposed app/HDMI configuration locally | Yes; validation does not configure a TV |
| Run the complete app on a normal desktop or LG web-app simulator | No supported preview harness; LG-specific native modules are required |
| Build and install from this checkout alone | Not yet; build and asset gaps below |
| Replace LG Home, launch at power-on, or suppress the screensaver | Not included as portable integration |

The development target is LG OLED48C24LA, webOS 24 / 9.2.2-61, firmware 23.25.55. Other models and firmware versions are unverified. An LG logo or matching model family is not a compatibility check.

## What you can run today

With Git and Node.js 20 or newer, clone the repository and run the offline checks. While the repository is private, cloning requires access to it.

```sh
git clone https://github.com/josephkimberley/firewatch-home.git
cd firewatch-home
node --test tests/*.test.mjs
node tools/config.mjs config/default.json
node tools/config.mjs config/example-living-room.json
```

No npm dependencies are required for these checks. They validate the proposed configuration format; they do not compile QML, install anything, connect to a TV, or prove native compatibility. Editing either JSON file currently has no effect on the running app.

## Why there is no install command yet

The manifest starts a native executable named `minimal-home`, but that executable is not included. The retained C entry point needs reconciling with the working development build and a pinned ARM toolchain. The package also references missing `icon.png`, `large-icon.png` and launcher logos. App IDs, installation paths and preference paths still use `uk.local.minimalhome.native` / Minimal Home for compatibility with the development installation.

The QML imports `Eos.Window`, `WebOSServices` and `WebOS.Global`, in addition to Qt Quick. Installing desktop Qt does not provide LG's modules or prove that the shaders and input handling will behave the same. LG's standard CLI guide describes web-app packaging; it is not a complete build guide for this native application. See [LG CLI documentation](https://webostv.developer.lge.com/develop/tools/cli-dev-guide) and [webOS Homebrew native development](https://www.webosbrew.org/pages/native-development).

Root is not something this repository installs. Native app launch, application-service access and replacing the system Home screen are separate compatibility questions. Do not assume Developer Mode alone provides the full experience shown here.

## The deployment path we need to support

This is the release plan, not an executable installation recipe:

1. **Build a complete package.** Pin the compiler and target ABI; reconcile the entry point; include app icons, appropriate app-icon fallbacks, fonts and all referenced assets; generate an IPK and checksums reproducibly.
2. **Check the destination TV.** Identify model, webOS/firmware, architecture, installed apps, available native modules and service permissions. Return a useful unsupported result instead of applying a guessed patch.
3. **Install and launch the app independently.** Keep stock LG Home unchanged. Verify appearance, app and HDMI launch, Back, remote focus and preferences before considering startup integration.
4. **Configure on the TV.** Select installed apps, order them, name HDMI inputs, choose a clock format/timezone and select a scene. Preserve these choices across app updates.
5. **Offer optional Home/startup integration separately.** Only after firmware compatibility checks and verified backups, allow Home → Firewatch Home and Red → LG Home. Keep startup, key mapping and screensaver behavior independently reversible.
6. **Test updates and removal.** Disable optional integration before uninstalling its target app; restore stock behavior from verified receipts. See [recovery requirements](RECOVERY.md).

The approximately five-second startup is an observed development-TV result with additional integration active. It is not a promise for other TVs, and installing the visual app alone does not reproduce every system modification.

## Controls in the current app

- Left/Right selects launcher tiles; OK opens the selected app/input.
- Down selects Appearance; OK opens it. Arrows and OK operate the panel.
- Back closes Appearance. Back on the main screen is deliberately consumed.
- Red opens LG Home **only when the separate remote mapping is installed**. The on-screen red hint does not implement that mapping itself.
- Appearance selects scenes, season/framing, a manual time, Auto and Motion. Preferences are saved by the native app.

Do not assume the red hint or screensaver behavior works on an installation without the corresponding integration. A standalone release must provide an appropriate stock-Home route and hide unavailable integration hints.

## Using an AI assistant

Codex, Claude or another coding assistant can help inspect and adapt this source. They are optional development tools, not a runtime dependency or a substitute for verified compatibility. Start with the [read-only assessment prompt](AI_ASSISTED_SETUP.md), not a request to root the TV or replay the development patches.
