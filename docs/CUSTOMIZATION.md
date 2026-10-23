# Configuration contract, version 1

`config/default.json` is a proposed portable format with a working offline validator. It is not yet consumed by the QML app. Editing it will not change the TV.

Apps are ordered entries with `id`, `label` and an optional relative `icon` path. IDs are the installed app IDs, which can differ by region and app variant. The UK examples are not an app installer or a guarantee those apps exist. Planned runtime behavior: keep an unavailable app visible, show a clear message on launch failure, and allow removal in settings.

Inputs are ordered entries with physical `port` 1–4, `label` and an optional icon. A port determines the target ID independently of the entry's position or name. For example, `{ "port": 3, "label": "Streaming box" }` always targets HDMI 3 even if moved to the first tile.

The first layout contract permits up to five apps and four inputs; either group may be empty. Runtime navigation and positioning must be adapted and tested for each count before that flexibility ships. Icon paths must be local PNG/SVG asset paths; the eventual importer must also verify file contents and reject symlinks escaping the asset directory.

`clock.timeZone` is `system` or an IANA timezone such as `Europe/London`. `clock.format` is `12h` or `24h`. The Node validator checks IANA support on the host; this does not prove that the TV's Qt runtime can implement every timezone. That adapter is an outstanding release task. UK time must switch between GMT and BST rather than hard-coding UTC+1.

`scene` selects a theme ID, an automatic or fixed period, and motion on/off. `layout` controls group gap in the 1920×1080 design coordinate space, divider visibility and HDMI tint opacity.

Current phase boundaries: Dawn 05:30, Morning 08:00, Noon 09:00, Afternoon 14:30, Evening 17:00, Dusk 20:00, Night 22:00. Automatic mode blends for 15 minutes after each boundary. These are clock boundaries, not calculated sunrise/sunset times.

Before release: implement atomic import, export, reset and last-known-good recovery; reject unsupported versions without overwriting existing preferences. Wire the validated data into tile layout and remote navigation, then test unknown apps, missing icons and all supported group sizes. Do not run configuration values as commands.
