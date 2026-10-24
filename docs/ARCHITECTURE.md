# Architecture and startup findings

The entry point creates an app-owned preference directory, sets rendering environment variables for its own process and executes LG's qml-runner. The UI uses QtQuick and LG's Eos.Window/WebOSServices modules. HomeControls emits launch intent; main.qml owns Luna application-manager requests and preferences. PaintedScene, shaders and BirdMesh draw the scene. StartupCover handles the separate system-cover readiness interaction.

The community C entry point retains the existing app ID and preference directory, resolves its QML relative to the executable, and is compiled with pinned Zig 0.13.0. The build creates a static ARM launcher and a checksummed app-only IPK; see [Build](BUILD.md). No LG Qt libraries, LG executables or toolchain are bundled.

Community `main.qml` loads the packaged configuration with a bounded timeout, restores valid saved/previous settings, and requests a bounded installed-app inventory. `HomeControls` derives its model, geometry and focus from that configuration. `AppsInputsPanel` edits a draft and emits Save intent; `main.qml` owns persistence. Failed discovery leaves the existing shortcuts available. The desktop integration tests replace only the LG platform modules and artwork renderer, preserving the production main/controls/editor logic and real temporary Qt Settings.

Optional rooted integration is separate from rendering: startup-input selection, Home/red mapping, cover presentation/readiness, and a narrowly scoped foreground screensaver helper. Those integrations must be independently installable and reversible. They are deliberately absent from this initial source export because the development scripts contain personal paths and firmware-specific LG copies.

The delay investigation found different intervals: system initialization, settings readiness, SAM prelaunch, process/QML startup, first artwork, and cover dismissal. A native window appearing does not establish that artwork is ready or visible under the system cover. Earlier traces measured about five seconds before process creation, and separate cover overlap.

The working app manifest includes `needNetworkToLaunchOnBoot: false`, `lockable: false`, `noSplashOnLaunch: true` and `spinnerOnLaunch: false`. The app-specific lockable metadata change removed the remaining approximately five-second prelaunch wait in the recorded development test. Rooted settings-readiness/cover changes were also active; changing this flag alone is not a universal five-second recipe.

The user's latest reported result was around four seconds black, then about one second of spinner before the forest. An earlier OpenLauncher result was approximately three seconds on an Active Standby return. Keep power-state and procedure differences explicit; neither result establishes a universal comparative benchmark.

For publishable benchmarks record model/firmware, Quick Start+, exact off/unplug procedure, power-state evidence, app/version/hash, button-to-usable timing and internal stage timings separately. Repeat trials and report spread. No new measurements have been made during this GitHub preparation.

OpenLauncher reference: https://github.com/Shantil-K/OpenLauncher . Its locally inspected app identifies GPL v3 and QwQHome ancestry. Do not copy its code into a differently licensed project without completing the licence/provenance review. A separate upstream issue or contribution should contain a minimal reproducible finding relevant to that project, not private TV dumps.

## Back-button routing

LG may show its exit dialog before QML sees Back. The native window declares `_WEBOS_ACCESS_POLICY_KEYS_BACK` as string `true` through its `windowProperties` map. `WebOS.Key_webOS_Back` is normalized alongside Qt Back, Escape and browser keycode 461. The gesture is consumed on press and acted on non-repeated release: An open panel or nested editor closes and restores its focus; Back on the main screen does nothing. In the community app, Red requests LG Home while Firewatch Home has focus, and the LG Home footer is also focusable/clickable. A global Home/red mapping remains a separate integration.
