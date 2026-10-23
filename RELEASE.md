# Firewatch Home release checklist — 23 October 2026

## Private development snapshot

- [x] Independent project in the private `josephkimberley/firewatch-home` repository.
- [x] QML/JS/shader snapshot refreshed from installed `back-panel-v3`.
- [x] All 42 approved wallpapers, 28 previews and three Winter compositing assets copied exactly and inventoried.
- [x] Barlow fonts and OFL notice bundled.
- [x] Floating Cards menu; seven manual times and separate Auto; Ember excluded.
- [x] Configuration contract, offline validator and app/HDMI mapping tests.
- [x] Artwork credits and separation from the future code licence documented.

## Before it is plug-and-play

- [ ] Integrate configuration into QML: automatic app discovery, variable tile counts, ordering, HDMI naming, icon fallback and missing apps.
- [ ] Add import/export/reset and atomic preference migration.
- [ ] Make timezone configurable beyond the existing UK clock.
- [ ] Pin the ARM toolchain; reconcile the C launcher source with the current binary and make compilation/package creation reproducible.
- [ ] Include and inventory required launcher icons; validate every runtime asset reference.
- [ ] Build theme import/update tooling and configuration UI.
- [ ] Extract generic root integration with compatibility detection, firmware/hash guards, receipts and tested rollback. No LG source/binary dumps.
- [ ] Provide one supported installation path, preference-preserving updates and complete uninstall restoring stock LG Home.
- [ ] Verify on clean supported installations; state tested hardware/firmware and startup measurement conditions. Approximately five seconds is a reported C2 result, not a universal LG guarantee.

## Before public release

- [ ] Complete source provenance review and select a compatible source licence.
- [ ] Resolve/document artwork redistribution status; bundling locally does not establish permission.
- [ ] Sanitize per-image processing/provenance records and verify logo/dependency notices.
- [x] Scan the initial private export for private data, credentials, personal paths and hidden/symlinked files; repeat before public release.
- [x] Owner and private repository confirmed: `josephkimberley/firewatch-home`.
- [ ] Review final public contents and obtain explicit approval before changing visibility.
- [ ] Document existing Minimal Home package ID and any future migration without breaking installed preferences/startup.

This is an independent Firewatch Home repository, not an OpenLauncher skin. Repository-only SSH publishing access is configured on the development Mac; credentials are excluded from the repository.

The app-only Back fix is installed separately on the development TV with rollback records. The source snapshot reflects current UI/art behaviour, but app tiles are still fixed in QML; configuration tooling is not connected to the runtime. No compiled binaries or private root integration scripts are included.
