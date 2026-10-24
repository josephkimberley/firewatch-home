# Local Apps & Inputs preview

This runs the **production `HomeControls.qml` and `AppsInputsPanel.qml`** in a desktop Qt window with a mocked app inventory and mocked saves. It does not discover or connect to a TV, run root commands, install anything, or change personal preferences. The background is a static bundled wallpaper; missing device icons use the production label fallback. The Qt 6 software renderer does not reproduce native Qt 5 shader effects. This is not a simulation of LG's native compositor, boot time, GPU shaders or Luna permissions.

Use Python 3.10+ in an optional local virtual environment:

```sh
python3 -m venv .venv-preview
.venv-preview/bin/python -m pip install PySide6
.venv-preview/bin/python preview/run.py
```

The window is resizable and never requests fullscreen. Use arrow keys and **Enter** as the TV remote, **Escape** for Back, or click controls.

- **F2:** open Apps & Inputs again.
- **F3:** simulate app-discovery failure/recovery.
- **F4:** simulate a persistence failure; Save must leave the draft open.
- Changes last for this preview process only. Relaunching resets the mock.

The compact editor has Apps and HDMI tabs. Select a name to rename it with the remote keyboard; select **Change** to choose a discovered app or physical port. Up/down arrow buttons change order. **Remove** hides a launcher tile without uninstalling an app or changing a TV input. Save validates the complete configuration; Cancel and Back discard the draft. HDMI port identity is independent from its friendly name and order.

Run the headless navigation/validation tests:

```sh
.venv-preview/bin/python preview/run.py --test
```

Capture the first-run panel without opening a desktop window:

```sh
.venv-preview/bin/python preview/run.py --screenshot /tmp/firewatch-setup.png
.venv-preview/bin/python preview/run.py --view home --screenshot /tmp/firewatch-home.png
.venv-preview/bin/python preview/run.py --view rename --size 960x540 --screenshot /tmp/firewatch-rename.png
```

Tests exercise the real QML panel: reorder boundaries, add/remove limits, unavailable inventory, duplicate-port prevention, remote rename, nested Back, repeat-key suppression, Cancel, failed saves, empty-launcher rejection and single-input configuration, literal rendering of HTML-looking app labels, and remote navigation/selection through a 50-app inventory. They also exercise actual HomeControls navigation for apps-only/inputs-only layouts, physical HDMI launch IDs, footer routing, Red and Back behavior, repeated panel opens and a Qt key-press/key-release Back gesture. Passing these does **not** establish hardware compatibility. Qt 5 and the actual LG remote/platform still require device validation before a release is advertised as supported.

The production native shell and persistent settings can also be tested with fake LG modules:

```sh
.venv-preview/bin/python tests/main_integration.py
```

That test uses real Qt Settings in a temporary directory and reloads the QML engine. LG window/service modules and the artwork renderer are stubs; it does not connect to a TV.
