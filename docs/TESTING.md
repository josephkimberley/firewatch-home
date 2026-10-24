# Experimental community preview verification — 24 October 2026

These checks were run on the community checkout, without connecting to or changing a TV.

**Volunteer testers:** use the [short testing checklist and report form](COMMUNITY_TESTING.md). This page records developer verification; it is not a hardware compatibility certification.

| Check | Result | Scope |
| --- | --- | --- |
| Node tests | 46 passed | Runtime config, layout combinations, HDMI identity, corrupt-state recovery, clocks/DST, icon paths, asset inventory |
| Python tests | 16 passed | Package format, deterministic archives, identity/content verification, mocked installer refusal/transfer/registration/cleanup |
| Production control/editor mock | 95 assertions passed | Remote navigation, Save/Cancel, rename, unavailable inventory, 50-app scrolling, plain-text labels, all footers |
| Real Qt Back and pointer gestures | Passed | Press retains panel, release closes it; clicks behind modal panel do not launch tiles |
| Production main integration | 52 assertions passed | Real temporary Qt Settings; save/reopen, preserved Appearance, plus ten service/startup/recovery scenarios |
| Native C helper unit test | Passed | JSON path escaping and output bounds |
| Runtime assets | Passed | 42 inventoried wallpapers, all active mappings, thumbnails, fonts, compositing assets and app icons |
| Documentation links | 138 local links resolved | No missing repository targets at verification time |
| ARM package build | Passed twice with identical SHA-256 | Pinned Zig 0.13.0, static ARM wrapper, Python standard-library packaging |
| Candidate installer dry run | Passed | Validated the actual package; no network connection |

## Build receipt

- Package: `uk.local.minimalhome.native_3.1.0_arm.ipk`
- Size: 76,673,314 bytes
- SHA-256: `3ec18ea529f7de6008a416a32ff59c5a305be560c4c264513ecd83ffd1a00fe9`
- Contents: 104 app/package files; no install hooks or system permission roles.
- All staged source files were compared with the current checkout after building.
- Art assets were hash-checked; no wallpaper or animation redesign was part of this change.

Generated packages are in ignored `dist/`, not committed binaries. Rebuild from [Build](BUILD.md). If source changes, this receipt describes this candidate only; rerun and replace it rather than carrying the claim forward.

## Repeat the checks

```sh
npm test
python3 -m unittest discover -s tests -p 'test_*.py'
```

For the optional Qt tests, install PySide6 into a local virtual environment as described in [Preview](../preview/README.md):

```sh
.venv-preview/bin/python preview/run.py --test
.venv-preview/bin/python tests/main_integration.py
```

The C test can be compiled with the build's Zig compiler:

```sh
mkdir -p dist
/path/to/zig cc -Wall -Wextra -Werror tests/launcher-unit.c -o dist/launcher-unit
./dist/launcher-unit
```

## What these results do not prove

The desktop uses Qt 6 software rendering. The actual controls/editor run, but LG window/services and the full animated artwork renderer are mocked in the main integration test. This does not prove Qt 5/LG compatibility, service permission grants, graphics smoothness, cold-boot speed or physical remote behaviour.

The settings test proves a successful write and reload in a local temporary directory. QML Settings does not expose reliable disk-full/read-only status, so the mocked failure path is not proof of TV write-failure handling or power-loss durability.

The installer tests simulate remote responses. A real fresh installation, rendering, discovery, launching, persistence, uninstall and update must be verified before a supported release. The standalone package contains no default-Home/startup takeover; the personal development TV's five-second result does not apply automatically to it.

## Extended simulation

The production main integration test now exercises ten scenarios using real event-loop timers: permission denial, malformed service responses, no request token, a service that never replies, a response after timeout, a delayed response inside the deadline, damaged current settings, an unknown current schema plus damaged previous settings, missing packaged configuration, and delayed artwork readiness. All passed. Saved shortcuts survive discovery failures; recovery restores valid defaults; first-run setup waits for artwork. No production app changes were required by these additional tests.

LG’s [current Simulator documentation](https://webostv.developer.lge.com/develop/tools/simulator-introduction) explicitly excludes native apps. Our native QML application therefore uses its own desktop harness. LG’s [older emulator](https://webostv.developer.lge.com/develop/tools/emulator-introduction) was discontinued for webOS TV 22 onward and also has hardware/API limitations. Neither option certifies modern rooted Home/startup integration or Power-to-artwork timing.

Confidence is strongest in the exercised UI/configuration paths, lower in untested device-specific service permissions and native integration. The next hardware evidence can come from an informed volunteer or separate test TV; the owner’s daily-use installation need not be changed.
