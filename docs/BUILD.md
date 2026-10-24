# Build the standalone developer preview

This build produces a native ARM `.ipk` from the source in this repository. It does **not** connect to a TV, install root, replace LG Home, change startup settings, or grant any Luna permissions. The community package has not yet been tested on a fresh TV. Local build success is not a compatibility certification.

## Requirements

- Node.js 20 or newer.
- Python 3.9 or newer (standard library only).
- **Zig 0.13.0**, downloaded for your development computer from [Zig's official downloads](https://ziglang.org/download/). Check the archive against the SHA-256 published there. The build refuses a different compiler version.

The tested build host is macOS on Apple Silicon. The scripts use portable Node/Python APIs and contain no Homebrew, Docker, Xcode or webOS SDK dependency, but Windows/Linux host builds still need verification. Python may be named `python` rather than `python3` on Windows; use the explicit option below.

The toolchain is not committed. The checked Apple Silicon archive is `zig-macos-aarch64-0.13.0.tar.xz`, SHA-256 `46fae219656545dfaf4dce12fb4e8685cec5b51d721beee9389ab4194d43394c`. Do not use this hash for other operating systems or architectures.

## Build

From the repository root:

```sh
npm test
npm run check:assets
python3 -m unittest discover -s tests -p 'test_*.py'
node tools/build.mjs --zig /path/to/zig --python /path/to/python3
```

If Zig and Python are on `PATH`, `npm run build` is sufficient. `ZIG` and `PYTHON` environment variables are also accepted. No npm dependency installation is necessary for the build/check scripts.

Output:

- `dist/uk.local.minimalhome.native_3.1.0_arm.ipk`
- A matching `.ipk.sha256` checksum.
- A `.manifest.json` listing every packaged file, size and SHA-256.
- `dist/build-report.json` with compiler, target, launcher and package hashes.
- `dist/stage/`, the exact app folder used for packaging.

The installer also validates the package identity, version, archive paths and absence of privileged hooks before any connection. A matching checksum alone is not treated as proof that an arbitrary archive is this app.

`dist/` is ignored by Git. A repeat build replaces the staging folder and package. Do not put hand-edited files there. The package includes `config/default.json` as `launcher-config.json`; use the community setup controls, or pass `--config local/config.json` to the build to include private choices without changing tracked defaults.

## What the build checks

- All 42 inventoried wallpaper hashes and every active scene/time mapping.
- The 28 menu previews, fonts, shaders, compositing assets and application icons.
- Configuration validity and application identity.
- No symlinks, hidden files or key files in package assets.
- Launcher is 32-bit little-endian ARM ELF and uses no dynamic interpreter/shared libraries.
- Manifest does not request system privilege groups.

The IPK contains only `usr/palm/applications/<app-id>/…` and its package metadata under `usr/palm/packages/<app-id>/`. There are no install/remove scripts, root service roles, boot hooks, LG executables or LG libraries. App-specific privileged integrations are deliberately separate.

The control field `Installed-Size` is recorded in bytes, matching [LG’s own CLI implementation](https://github.com/webos-tools/cli/blob/main/lib/package.js) (`getFileSize` → `createControlFile`); this differs from Debian’s KiB convention.

The package writer normalizes archive order, UID/GID, modes and timestamps. It writes deterministic `ar` + `tar.gz` structures using Python's standard library. Two builds with unchanged inputs and the same compiler/Python/zlib environment should have the same checksum. Different zlib versions may compress the same bytes differently; compare the per-file manifest as well as the complete IPK.

## Launcher and platform assumptions

The compiler command targets `arm-linux-musleabi`, Cortex-A9, with a static musl launcher. This tiny executable starts the TV's own `/usr/bin/qml-runner`; it does not link or redistribute LG Qt libraries. It is a candidate for the known ARM target, not for arbitrary architectures or every LG firmware.

The exported historical C source matched the retained development launcher. It used a fixed application path. The community source now resolves `main.qml` relative to `/proc/self/exe`, JSON-escapes that path, and checks it is readable. It retains the established runner arguments: `qml-runner --appid <app-id> <JSON payload>`. It intentionally does not forward LG's native-launch metadata as qml-runner arguments. [webOS Homebrew documents this native `argv[1]` metadata](https://www.webosbrew.org/pages/native-development#argv-handling).

It retains `uk.local.minimalhome.native` and the app-owned `/media/developer/.minimalhome-native` preference directory. A same-ID install replaces an existing installation, so save that application's package/preferences before testing an upgrade. It does not migrate another app ID. Directory ownership/symlink checks fail closed; there is no fallback to a world-writable location.

The launcher changes only its own `QSG_RENDER_LOOP`/threaded-rendering environment. It neither edits a system QML import path nor installs private modules. The QML requires the TV's existing `Eos.Window`, `WebOSServices`, `WebOS.Global` and matching Qt modules. Missing modules, unavailable services and platform permissions are runtime compatibility issues that a desktop mock cannot prove away.

## What still requires a real test TV

A clean app-only install, launch permissions, rendered scene/shaders, app/input launching, preferences, remote Back handling, update and uninstall must be tested on each supported firmware. Home/wake replacement and screensaver suppression are not delivered by this package. A successful IPK build does not reproduce the five-second development-TV result by itself.

Do not install this candidate over a daily-use home screen just to validate packaging. Use a separate test device or volunteer tester with a rollback plan. See [getting started](GETTING_STARTED.md) and [recovery](RECOVERY.md).

## App icon

`tools/generate_icons.py` produces the two PNG app icons from an original geometric lookout mark. It uses no Firewatch logo, brand icon or downloaded image. The generator is retained so both sizes can be reproduced without an image editor.


The installer establishes absence using LG’s documented [`getAppLoadStatus`](https://webostv.developer.lge.com/develop/references/application-manager#getapploadstatus) with `appId`, requiring a successful response and `exist: false`. Missing fields, permission failures and error codes never count as absence. This endpoint is documented for webOS TV 4.0 onward; the candidate is not a generic old-firmware installer. The later version-confirmation call still relies on `getAppInfo`, which requires verification on the target firmware.
