# Test the experimental community preview

Thanks for helping test Firewatch Home. **Desktop feedback is useful; you do not need to change your TV to contribute.** Successful reports help establish compatibility just as much as bug reports.

Version 3.1.0 builds locally and has automated UI, configuration, packaging and simulated-service tests. **No fresh TV has yet been validated with this community package.** The existing TV screenshots show the personal development installation, not proof that the community installer works on your model.

## Choose your route

| Route | What you can check | What it cannot establish |
| --- | --- | --- |
| Desktop preview — start here | Setup, navigation, rename/reorder/hide, Save/Cancel and simulated failures | LG permissions, real app/input launching, animation performance or boot speed |
| Optional rooted test TV | Native rendering, remote behaviour, app discovery, launching and saved settings on your exact firmware | Compatibility with other models, a working upgrade path or automatic Home replacement |

This is a **standalone app**, not a root tool or default-Home installer. It does not include the personal TV's startup optimisation, global Home/Red remapping or screensaver helper. There is no five-second boot promise. Updates over an existing installation and complete uninstall/settings cleanup are still unverified. The installer refuses to replace the existing `uk.local.minimalhome.native` app ID; do not bypass that protection to try this preview.

## Desktop: a short test with no TV connection

Download or clone this repository, open a terminal in its folder, and use Python 3.10 or newer:

```sh
python3 -m venv .venv-preview
.venv-preview/bin/python -m pip install PySide6
.venv-preview/bin/python preview/run.py
```

On Windows, use `.venv-preview\Scripts\python.exe` instead of `.venv-preview/bin/python`. The preview opens in a normal, resizable window. Arrow keys move, Enter selects, and Escape acts as Back. The app list and saves are simulated; nothing connects to a TV.

Try these steps (roughly five minutes):

- [ ] Rename an app, reorder two shortcuts and hide an HDMI tile. Save: the launcher should reflect the changes.
- [ ] Press F2 to reopen Apps & Inputs. Make another edit, then Cancel: the saved configuration should remain.
- [ ] Open the rename keyboard or app picker and press Escape: close that nested view first. Escape at the editor closes it without saving the draft.
- [ ] Press F3 to simulate unavailable app discovery. Existing shortcuts should remain and the editor should explain the unavailable list. Press F3 again to restore discovery.
- [ ] Press F4 to simulate a save failure, then Save: the draft should stay open with feedback. Press F4 again to restore saves.
- [ ] Resize the window and check that names and controls remain readable.

Changes in this preview last only until you close it. Its static background does not demonstrate the TV animations. Optional automated checks and screenshots are covered in [Preview instructions](../preview/README.md).

## Optional TV testing

Only choose this route if you already have a rooted test TV, working root SSH access and a known way to return to stock LG Home. Rooting instructions are outside this preview. You do not need to use your daily TV.

1. Follow [Getting started](GETTING_STARTED.md) to build the package. There is no tested release download yet; do not assume the screenshots imply a ready-made installer.
2. Run the documented **dry run** first. It validates the local package and makes no TV connection.
3. If you choose to proceed, run `--doctor` against **your test TV**. This reads prerequisites only; passing is not a compatibility certificate. The tool requires root SSH, a supported ARM runtime, `qml-runner`, `luna-send` and the Homebrew persistence directory.
4. Read [Recovery](RECOVERY.md), then use the explicitly documented `--apply` command. That installs the standalone app only. If an existing app ID or unsupported prerequisite is reported, stop and include that result in your report.
5. Open Firewatch Home manually from LG Home. Installation/registration success alone does not count as a successful runtime test.

Record **Pass / Fail / Not tested** for each item:

| Check | Expected result |
| --- | --- |
| First launch | Forest and controls appear; first-run setup opens after artwork is ready |
| Apps & Inputs | Installed apps are listed, or unavailable discovery is clearly reported without losing configured shortcuts |
| Save / reopen | A renamed/reordered shortcut survives closing and reopening the app normally |
| Cancel / Back | Draft edits are discarded; Back closes nested views, then the panel; Back on the home screen does not show a quit prompt |
| App shortcut | A chosen installed app opens |
| HDMI shortcut | A chosen port opens; reordering or renaming does not change its physical port identity |
| Appearance | Scene, season, close-up, time, Auto and Motion behave as labelled; check a daytime and nighttime scene |
| Rendering / remote | Clock and logos are legible, animations and arrows/OK respond normally |
| LG Home | Red or the on-screen LG Home action opens stock Home while Firewatch Home is active |
| Removal — optional | Stock LG app-management UI removes the app; record any error and whether its icon remains |

HDMI tests may wake a connected device through its existing CEC settings. Choose an input that you are happy to switch to. No reboot or global Home/startup changes are needed for this checklist. You can skip any item; mark it **Not tested**.

If the app hangs, renders incorrectly or affects input/power behaviour, stop testing and use stock Home/Settings if responsive. Report what happened; do not change system permissions, restart LG services or delete existing installations to force a pass. Settings may remain after removal, and complete cleanup is not yet verified.

## Report back

**[Open a preview test report →](https://github.com/josephkimberley/firewatch-home/issues/new?template=preview-report.yml)**

The same form accepts a successful test, a partial result or a bug. The repository and reports are public; sign in to GitHub to submit a report. If the form does not load, open a normal issue and copy the outline below.

```text
Outcome: Works / Partly works / Blocked / Problem found
Environment: Desktop mock or real TV
Version and commit:
Desktop OS + Python/PySide6 versions, OR TV model + webOS + firmware:
Installation: New install / Existing ID refused / Desktop only
Checklist results: Pass / Fail / Not tested for each item attempted
Steps to reproduce (if relevant):
Expected / actual result:
Exact error or relevant log excerpt:
Optional image/video:
```

You can obtain the checkout revision with `git rev-parse --short HEAD`. Include the model and firmware, **not** the TV serial number, MAC/IP address, SSH keys, pairing tokens or account details. Review logs and screenshots before attaching them; do not upload full backups or credentials. A short relevant error excerpt is usually enough.

For timing feedback, say exactly what you measured: **selecting the app to usable controls**, or **Power to picture**, and whether the app had already run. Keep these separate. This standalone preview does not take over startup, and desktop timings cannot establish TV performance.

Reports will inform a hardware/firmware compatibility list. Until hardware results exist, local tests remain evidence of the simulated paths only. See the [verification record](TESTING.md) and [remaining release gates](../RELEASE.md).
