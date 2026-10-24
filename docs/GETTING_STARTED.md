# Getting started

Firewatch Home now has a buildable **standalone community candidate**, a remote-friendly Apps & Inputs editor, and a desktop mock. It is not yet a verified replacement Home installer for arbitrary LG TVs. The package has been built and tested locally; a fresh TV installation still needs validation.

## Try it without a TV

The desktop preview runs the actual controls and setup panel over a static wallpaper. It uses fake app discovery and saves in memory, so it cannot touch a TV. [Preview instructions](../preview/README.md) include normal-window and headless modes.

```sh
python3 -m venv .venv-preview
.venv-preview/bin/python -m pip install PySide6
.venv-preview/bin/python preview/run.py
```

Use arrows and Enter, with Escape for Back. F3 simulates unavailable app discovery; F4 simulates a save failure. These test UI behaviour, not LG boot time or graphics performance.

## Build the package

You need Node 20+, Python 3.9+ and Zig 0.13.0. The build has no npm dependencies and does not download or install a compiler automatically.

```sh
npm test
python3 -m unittest discover -s tests -p 'test_*.py'
node tools/build.mjs --zig /path/to/zig --python /path/to/python3
```

See [Build](BUILD.md) for the compiler checksum, package contents and complete validation details. The output is `dist/uk.local.minimalhome.native_3.1.0_arm.ipk`, its SHA-256 file and a per-file manifest. All 42 wallpapers are included; the app does not need a computer serving them.

## Candidate installation: rooted test TVs only

This candidate needs the TV's native `qml-runner`, LG Qt modules and working native Luna permissions. Rooting is a separate prerequisite; this project does not run an exploit. ARM runtime checks do not certify a firmware version. Missing app-discovery permissions produce a message and retain the configured shortcuts rather than stopping the launcher.

The optional installer is **dry-run by default**. Substitute your own test TV's hostname/address:

```sh
python3 tools/install_app.py --tv YOUR_TV \
  --package dist/uk.local.minimalhome.native_3.1.0_arm.ipk \
  --checksum dist/uk.local.minimalhome.native_3.1.0_arm.ipk.sha256
```

That command checks the local package and prints its plan; it makes no connection. Establish and verify the TV's SSH host key yourself first. The tool uses existing SSH authentication, never stores a password and never disables host-key checks.

Read-only prerequisite checks:

```sh
python3 tools/install_app.py --tv YOUR_TV --doctor
```

On a test TV, when its owner is ready, append `--apply` to the package command. It verifies the package and runtime, refuses an existing installation, uploads into a temporary directory, verifies the remote checksum, requests app installation and checks registration. It does not launch the app, replace LG Home, remap a remote button, change power/update settings or add permission groups.

Open Firewatch Home from LG Home after installation. Registration success is not proof of correct rendering or service permissions. The existing `uk.local.minimalhome.native` ID is retained: **the helper refuses to overwrite that ID**, including a working personal installation. Upgrade support with backup/restore remains a separate release gate.

## First launch and customising

The first-run Apps & Inputs panel opens after the artwork. Choose from the returned installed-app list, move shortcuts up/down, rename them, hide unused HDMI inputs and arrange physical ports independently from their names. Save applies the changes; Back or Cancel discards the draft. Removing a tile never uninstalls an app or changes an input on the TV.

The supported layout is up to five apps and four HDMI inputs, with at least one shortcut overall. Text labels remain usable when no logo has been provided. App discovery depends on TV permissions; if denied, HDMI editing still works and existing app shortcuts are preserved. Advanced users can configure app IDs in `config/default.json` before building.

Appearance retains the existing scene cards, seven periods, Auto and Motion. Apps & Inputs can be reopened from its footer button. Red and the on-screen LG Home action request stock Home while Firewatch Home is active; remapping the remote globally is not part of this package. Back dismisses an open panel and is consumed on the home screen.

See [Customisation](CUSTOMIZATION.md) for configuration, clock options and settings recovery limits.

## What this candidate does not deliver yet

- Automatically replacing Home at boot or globally intercepting Home/Red.
- The development TV's firmware-specific startup optimisation or screensaver helper.
- A verified update/uninstall manager with recovery receipts.
- General support for every model, firmware, regional app ID or arbitrary IANA timezone.

Your stock LG Home remains the installation and recovery route. Use its app-management UI to remove this standalone candidate. The app-owned settings directory may remain; do not delete it if preserving preferences for a later reinstall. See [Recovery](RECOVERY.md) before any separate integration work.

## Contributors and AI assistance

[Example prompts](AI_ASSISTED_SETUP.md) help contributors inspect compatibility, build or test. Codex and Claude are optional development tools, not a runtime requirement or a substitute for verifying a TV's supported interfaces.
