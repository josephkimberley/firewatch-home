# Portability assessment and release plan

Assessed against the repository on 24 October 2026. These are planned changes unless explicitly marked present.

## What is portable already

The 42 wallpaper assets, fonts and most visual QML/JavaScript/shader logic are packaged as source. Theme mappings and hashes are inventoried. There is a working Node configuration validator with tests. Screenshots and artwork can be browsed without touching a TV.

The native shell is tied to LG's QML modules, ARM/device ABI, Luna service permissions and app lifecycle. The startup/root changes used on the development TV are absent from the repository. This is the main distinction between portable artwork and a portable home-screen replacement.

## Recommended user experience

**Install a verified app package → choose apps and HDMI names → enjoy the home screen.** No source edits, AI subscription or always-on computer should be required. Advanced rooted integration should be a separate, optional step with its own compatibility report and rollback.

The app should discover installed applications, let the user select/reorder a small set, and display their icons with a readable fallback. HDMI rows should use explicit physical port numbers, optional friendly names and independent ordering. Hide unused ports. An Apps & Inputs editor should use the existing visual style and work entirely with the remote.

## Milestone 1: make app and HDMI choices real

Current `HomeControls.qml` contains six parallel arrays, a nine-item repeater, fixed five-app/four-input positioning, hard-coded focus limits and footer index 9. Changing only `config/default.json` does nothing; changing only array lengths breaks layout/navigation assumptions.

- Load a versioned configuration from an app-owned location; bundle a default.
- Replace parallel arrays with one target model and derive navigation/layout from the actual app/input counts. Keep the first release within five apps/four inputs.
- Enumerate installed apps only through a verified permitted interface; handle unavailable inventory without blocking startup. Do not install applications automatically.
- Populate native app icons or a bundled generic fallback; do not depend on the development Mac's omitted logo folder.
- Keep port identity independent of labels and ordering. Handle missing/unavailable app launches visibly.
- Add remote-friendly selection, reorder, rename, hide, restore defaults and import/export.
- Validate before saving, commit atomically and preserve last-known-good data. Existing invalid/missing config must not prevent the launcher opening.
- Test a minimum of one target, apps-only, inputs-only, full groups, missing icons/apps, rapid edits and focus restoration.

Acceptance: a new user can choose their tiles on the TV without editing QML, and updating the app preserves those choices.

## Milestone 2: complete and reproduce the standalone package

- Pin a compatible compiler/ABI and reconcile the checked-in C launcher with the working build. Produce a complete IPK plus checksums.
- Supply the missing app icon/large icon and all runtime assets with appropriate notices; verify every reference.
- Preserve or explicitly migrate the existing app ID and preference paths; a title change must not break installed startup rules.
- Detect unavailable LG modules/services and present useful diagnostics. Stock Home access must work without the development TV's red-key mapping.
- Verify app-only install, launch, update and uninstall on a clean supported target before documenting runnable installation commands.
- Add a desktop visual harness with mocked platform services if useful; label it a visual preview, not proof of TV compatibility.

Acceptance: someone can reproduce the package from a clean checkout and follow tested app-only installation instructions.

## Milestone 3: regional settings and theme configuration

`UKClock.js` currently computes UK GMT/BST, and both the display and automatic scene schedule need to use the same configured clock. The JSON validator's host IANA support does not establish TV support. Implement system timezone first, then explicit zones if supported, with 12/24-hour formatting and DST tests.

Unify theme identifiers: the JSON example uses `autumn`, while the inventory uses identifiers such as `valley-autumn-wide`, and runtime preferences store scene/season/framing separately. Define and validate the mapping before advertising theme import. Provide clear current choices and retain the existing Appearance controls. A folder of arbitrary wallpapers is not yet an importable theme pack.

Acceptance: time and automatic lighting follow the user's region; all six built-in variants and seven periods resolve correctly; unknown selections fail safely.

## Milestone 4: optional rooted integration

Extract only the necessary integration from the private development records into maintainable original code/configuration. Do not distribute LG firmware dumps. Build an allowlist of verified firmware/stock hashes, a read-only preflight, staged changes with receipts, and independently tested rollback. Unknown state must stop integration without stopping the standalone app.

Keep Home/red routing, wake behavior, cover readiness and screensaver suppression separate. Measure true cold boot and standby return separately; record Quick Start+, firmware, timings and failed trials. Preserve normal settings, input, power-off and HDMI/CEC behavior. No broad update/power policy changes hidden in installation.

Acceptance: enable/disable/update/uninstall each supported component without losing stock Home or requiring the maintainer's private scripts.

## Public positioning

The current project can be described as a developer preview and artwork showcase. “Plug and play,” “any LG TV,” “five-second startup” and “just ask an AI to install it” would overstate what this checkout provides. AI-assisted guidance is useful for contributors; it should become unnecessary for ordinary users once the package and setup editor are complete.
