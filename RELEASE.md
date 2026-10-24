# Community candidate checklist — 24 October 2026

## Present and locally verified

- [x] Independent private repository, with artwork credits and licence limitations.
- [x] All 42 wallpaper mappings, 28 previews, fonts and compositing assets checked.
- [x] Configuration connected to the native controls; variable app/input counts and safe defaults.
- [x] Remote Apps & Inputs editor, discovered-app selection, rename/reorder/hide and Cancel.
- [x] Inventory failure path and invalid-settings fallback.
- [x] Shared clock zone for display and automatic lighting; system/UTC/London, 12/24-hour format.
- [x] Original app icons and readable shortcut fallback.
- [x] Pinned ARM build and deterministic standalone package with checksums/manifest.
- [x] Desktop mock and production-control navigation tests; no TV required.
- [x] Dry-run installation plan, mock/read-only preflight and app-only candidate installer.

## Before calling it a supported standalone release

- [ ] Fresh-TV install, LG imports/permissions, render/animation and remote tests.
- [ ] App/input launching and app discovery verified across supported firmware.
- [ ] Durable persistence errors reported through a native adapter; import/export/reset.
- [ ] Preference-preserving update with previous-package backup and tested rollback.
- [ ] Complete uninstall verified on fresh and upgraded installations.
- [ ] Publish tested hardware/firmware and reproducible performance measurements.
- [ ] Provide downloadable tested release artifacts so users need no compiler.

## Before default Home integration

- [ ] Portable compatibility checks and firmware/hash guards.
- [ ] Home/red routing, startup and screensaver components separately enabled/disabled.
- [ ] Receipts, independent disable path and tested stock-Home rollback.
- [ ] Cold/warm startup tests with normal Settings, power-off and HDMI/CEC behaviour.

## Before making the repository public

- [ ] Finish provenance review and select the source-code licence.
- [ ] Resolve artwork redistribution status; fan-project attribution is not permission.
- [ ] Repeat private-data/credential audit and review third-party notices.
- [ ] Obtain approval for public visibility.

The candidate retains `uk.local.minimalhome.native` and its app-owned settings directory. The installer refuses to replace an existing copy. No community candidate or setup-editor change has been deployed to the owner's daily-use TV. [Build](docs/BUILD.md), [Getting started](docs/GETTING_STARTED.md), [Recovery](docs/RECOVERY.md), [Remaining portability work](docs/PORTABILITY.md).
