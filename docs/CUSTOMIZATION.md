# Make Firewatch Home yours

[Running the project](GETTING_STARTED.md) · [Codex / Claude prompts](AI_ASSISTED_SETUP.md) · [Portability status](PORTABILITY.md)

## Apps & Inputs

The community source now includes a remote-friendly **Apps & Inputs** editor. This is separate from Appearance, so choosing a wallpaper stays simple. It opens on first use and is also available in the footer. It has been tested locally with a simulated TV; installation and app discovery on additional real TV models still require verification.

- Select up to **five apps** and **four HDMI inputs**. Either group can be empty, but keep at least one tile.
- Change labels, reorder the entries or remove unused tiles. A label never changes the app ID or physical HDMI port.
- Save to apply, or press **Back** to discard unsaved changes and close the editor.
- Missing app shortcuts are labelled after successful discovery. The bundled UK app examples may not be installed on your TV; replace or remove them.

For example, a tile named “Streaming box” with `port: 3` opens HDMI 3 wherever you place it in the row. Moving it to the first position does not change it to HDMI 1.

App discovery supplies the installed app IDs when the platform permits it. If discovery is unavailable, the editor explains that; existing app shortcuts and HDMI inputs remain editable. Adding an app without discovery requires the advanced JSON workflow below. Firewatch Home does not install other apps, sign into services or guess passwords. An unavailable app gives a launch error instead of freezing the home screen.

Icons are optional. The launcher uses a packaged custom icon first, then a discovered app icon inside that app’s known LG installation directory. Those TV-specific paths are display-only and are not saved into portable configuration. A missing icon falls back to a readable app or input label. The community package does not depend on the original developer's private logo folder.

## Local preview before using a TV

See [the local preview instructions](GETTING_STARTED.md) for the simulated setup environment. Its app inventory and launch responses are mock data, and it does not connect to a TV. You can exercise first-run setup, app and HDMI edits, saving, cancellation and bad-config recovery locally. Passing those checks does not establish firmware compatibility or cold-boot performance.

## Advanced configuration

`config/default.json` is now the shared versioned runtime contract. The build stages it as `launcher-config.json`; the native shell loads it and applies valid saved user choices in preference to that bundled default. Updating bundled defaults should not replace an existing valid user setup. Appearance and saved focus remain in the app's existing preference store.

Create a private local copy from the repository root:

```sh
mkdir -p local
cp config/default.json local/config.json
node tools/config.mjs local/config.json
node tools/build.mjs --config local/config.json --zig /path/to/zig --python /path/to/python3
```

`local/` is ignored by Git. The command validates and prints launch targets; it does **not** transfer anything to a TV. See [example-living-room.json](../config/example-living-room.json) for two apps and two inputs. JSON import/export is an advanced workflow; the on-screen editor is intended for ordinary changes.

| Field | What it changes |
| --- | --- |
| `apps` | Ordered `{id, label, icon?}` entries; at most five |
| `inputs` | Ordered `{port, label, icon?}` entries; physical ports 1–4 |
| `clock.timeZone` | `system`, `UTC` or `Europe/London`; used by clock and automatic lighting together |
| `clock.format` | `12h` or `24h` |
| `scene` | Initial season (`autumn` or `winter`), period and motion defaults; existing saved Appearance choices take precedence |
| `layout.groupGap` | Extra separation between the app and input groups in 1920×1080 design coordinates; `88.328125` preserves the full-row design |
| `layout.divider` | Show or hide the faint divider when both groups have tiles |
| `layout.inputTintOpacity` | HDMI tile tint intensity, from 0 to 0.3 |

The validator and native QML use the same ES5 JavaScript module, `src/native/LauncherConfig.js`. They reject unknown fields/versions, duplicate apps or physical ports, unsafe icon paths, control characters, unsupported timezones and invalid counts. Configurations are data, never shell commands. Rejected data produces a safe fallback rather than preventing the home screen from opening.

The native preview uses Qt Settings for persistence and retains the previous valid configuration for recovery. It requests a settings sync before closing Save, but this QML API does not report filesystem write failures; disk-full/read-only failure reporting and proven power-loss durability still require a native storage adapter and device testing. The local mock tests editing and recovery, not those hardware guarantees.

Optional icons must be relative packaged PNG/SVG paths. They cannot be network URLs, absolute paths or `../` traversals. User-supplied image files should be reviewed and bundled deliberately; entering a path does not upload or fetch an image. No arbitrary file or theme importer is provided.

The currently supported explicit UK zone handles GMT/BST rather than hard-coding UTC+1. Arbitrary IANA zones await a compatible Qt timezone adapter; `system` follows the native process’s local time. Some firmware may expose UTC despite a regional clock in LG Home; choose an explicit supported zone if necessary. Changing the clock configuration does not modify the TV system clock.

Current automatic lighting boundaries: Dawn 05:30, Morning 08:00, Noon 09:00, Afternoon 14:30, Evening 17:00, Dusk 20:00, Night 22:00. These are clock boundaries, not calculated sunrise/sunset times.

## Source map

| Area | Source |
| --- | --- |
| Shared validation, defaults, identity and tile geometry | `src/native/LauncherConfig.js` |
| Launcher tiles, focus, fallback labels and footer actions | `src/native/HomeControls.qml` |
| Remote-first draft editor | `src/native/AppsInputsPanel.qml` |
| Platform calls, config loading and saved preferences | `src/native/main.qml` |
| Clock formatting and zone conversion | `src/native/RuntimeClock.js` |
| Wallpaper and preview mapping | `src/native/Appearance.js`, `themes/inventory.json` |

Keep the standalone app separate from rooted Home/startup integration. Saving apps, HDMI names or appearance should not edit root services, update policy, input mappings or television picture settings.
