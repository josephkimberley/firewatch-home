# Portability progress

Updated 24 October 2026. The community checkout now differs from the installed personal-TV application. No community-setup changes have been deployed to that TV.

## Implemented and tested locally

- Shared versioned configuration validation in Qt-compatible JavaScript and the Node CLI.
- One target model with variable app/input counts, stable physical HDMI identity, independent order/labels, centred layout and focus limits.
- Apps & Inputs editor using the remote: installed-app picker, rename keyboard, reorder, add/remove, Save/Cancel and nested Back behaviour.
- Bounded installed-app discovery; denial/timeout leaves the existing configuration usable.
- Bundled configuration plus app-owned saved/previous values. Invalid current settings fall back to the previous valid version or bundled defaults. Unknown schema versions are rejected.
- System civil time by default, explicit UTC/Europe-London and 12/24-hour formatting. Automatic scene lighting uses the same zone as the clock.
- Original app icons, readable shortcut fallbacks, all 42 wallpaper mappings and required assets checked.
- Pinned native ARM build, deterministic app-only IPK writer, hashes and file manifest.
- Dry-run installer, read-only prerequisites, mock probes, checksummed candidate installation and refusal to overwrite an existing app.
- Desktop preview and tests of the production controls/editor using simulated inventory, saves and launch intents.

The underlying artwork and animation source remain intact apart from using the configured clock for automatic lighting. The desktop mock uses a static background and does not measure native shaders, compositor performance, cold boot or TV permissions.

## Next gate: fresh standalone installation

Use a separate rooted test TV or an informed volunteer. Record model, architecture, webOS and firmware. Verify native imports, app discovery, app/input launching, first-run setup, persisted settings after exit/restart, remote Back, stock Home access and uninstall. Test denied inventory and unavailable apps deliberately.

QSettings writes do not expose a reliable disk-error status through this QML API. The editor's error path is tested, but a disk-full/write-denied save cannot yet be promised durable or recoverable. A native persistence adapter with explicit atomic-write status remains work to do.

Updates must preserve settings and verify the previous package before replacing anything. The candidate installer intentionally refuses an existing app ID until that upgrade path is built and tested.

## Separate gate: default Home and startup

The standalone package does not include the personal TV's root hooks, cover permissions, remote adapter or screensaver helper. These cannot be copied blindly to other firmware. Extract original integration code with capability checks, firmware/hash guards, receipts, disable/uninstall and rollback testing.

CleanYourTV's manager pattern is useful here: app installation and taking over Home are distinct steps. The community candidate currently implements the first step only. A five-second development result is evidence about one TV, not a promise made by this package.

## Later improvements

- Verified installed-app icons and app discovery on more firmware.
- Configuration export/import/reset and stronger persistent-write diagnostics.
- Additional regions/timezones and localisation.
- Theme-pack import and updates; the six built-in variants already work through Appearance.
- A tested release package and update channel so ordinary users do not need a compiler or AI assistant.

Use “buildable community candidate” until the fresh-install gate passes. Use “plug and play” only once installation, configuration, update and recovery have all been demonstrated outside the development setup.
