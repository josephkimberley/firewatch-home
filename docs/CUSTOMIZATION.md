# Customising apps, HDMI, clock and themes

[Running the project](GETTING_STARTED.md) · [Codex / Claude prompts](AI_ASSISTED_SETUP.md)

## Current configuration status

`config/default.json` is a proposed portable format with a working offline validator. It is not yet consumed by the QML app. Editing it will not change the TV.

Apps are ordered entries with `id`, `label` and an optional relative `icon` path. IDs are the installed app IDs, which can differ by region and app variant. The UK examples are not an app installer or a guarantee those apps exist. Planned runtime behavior: keep an unavailable app visible, show a clear message on launch failure, and allow removal in settings.

Inputs are ordered entries with physical `port` 1–4, `label` and an optional icon. A port determines the target ID independently of the entry's position or name. For example, `{ "port": 3, "label": "Streaming box" }` always targets HDMI 3 even if moved to the first tile.

The first layout contract permits up to five apps and four inputs; either group may be empty. Runtime navigation and positioning must be adapted and tested for each count before that flexibility ships. Icon paths must be local PNG/SVG asset paths; the eventual importer must also verify file contents and reject symlinks escaping the asset directory.

`clock.timeZone` is `system` or an IANA timezone such as `Europe/London`. `clock.format` is `12h` or `24h`. The Node validator checks IANA support on the host; this does not prove that the TV's Qt runtime can implement every timezone. That adapter is an outstanding release task. UK time must switch between GMT and BST rather than hard-coding UTC+1.

`scene` selects a theme ID, an automatic or fixed period, and motion on/off. `layout` controls group gap in the 1920×1080 design coordinate space, divider visibility and HDMI tint opacity.

Current phase boundaries: Dawn 05:30, Morning 08:00, Noon 09:00, Afternoon 14:30, Evening 17:00, Dusk 20:00, Night 22:00. Automatic mode blends for 15 minutes after each boundary. These are clock boundaries, not calculated sunrise/sunset times.

Before release: implement atomic import, export, reset and last-known-good recovery; reject unsupported versions without overwriting existing preferences. Wire the validated data into tile layout and remote navigation, then test unknown apps, missing icons and all supported group sizes. Do not run configuration values as commands.

## Prepare your choices now

Create a private local copy from the repository root:

```sh
mkdir -p local
cp config/default.json local/config.json
node tools/config.mjs local/config.json
```

`local/` is ignored by Git. After editing the JSON, rerun the validator. It prints the targets in display order. It does **not** transfer the configuration or apply it to the TV.

See [example-living-room.json](../config/example-living-room.json): two app entries and two HDMI entries, with the streaming box on physical HDMI 3 placed before the console on HDMI 1. App IDs in examples must be checked against the user's installed apps; installing Firewatch Home does not install or sign into those services. Labels are display text, not application identifiers.

Prefer a future Apps & Inputs editor for everyday setup. JSON import/export should be an advanced option, not a requirement for using the home screen.

## Where settings live in the current source

| Change | Current source | Caveat |
| --- | --- | --- |
| App IDs, labels, HDMI order and logo sizes/colours | `src/native/HomeControls.qml`: `targetIds`, `targetLabels`, `logoFiles`, `logoWidths`, `logoHeights`, `tints` | Keep entries aligned; runtime assumes five apps plus four inputs |
| Tile counts, spacing and remote focus | `HomeControls.qml`: repeater, delegate positions, `select`, `activate`, `handleKey`, footer indices | Must change together; the JSON flexibility is not implemented |
| Clock/date | `src/native/UKClock.js`, used by `HomeControls.qml` and `PaintedScene.qml` | UK-specific; configure display and scene clock together |
| Lighting times | `src/native/SceneMath.js`: `phaseHours` | Current schedule uses fixed clock boundaries |
| Wallpaper and preview mapping | `src/native/Appearance.js`, `themes/inventory.json` | Close-up uses its own full artwork; current menu previews share wide framing |
| Saved appearance/focus | `src/native/main.qml`: `Settings` | Existing app-owned INI preferences; do not overwrite them during updates |

For source-level experiments, start in a branch, preserve the current group sizes and update all aligned fields together. Removing a tile requires navigation/layout work, not just deleting its array entry. Logos referenced by the source are not bundled yet; supply appropriately licensed icons or implement a readable fallback before attempting a complete package.

Appearance is already editable with the remote in the installed development app. Apps/HDMI editing, arbitrary timezones and theme importing are not yet available as settings screens. See [the portability milestones](PORTABILITY.md) for the proposed implementation.
