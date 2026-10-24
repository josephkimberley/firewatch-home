#!/usr/bin/env python3
"""Desktop setup preview. No TV access; all inventory and saves are simulated."""
import argparse
import json
import os
from pathlib import Path
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--view", choices=["setup", "home", "inputs", "rename"], default="setup", help="Initial preview view")
parser.add_argument("--size", default="1280x720", help="Window size, for example 960x540; screenshots default to 1920x1080")
parser.add_argument("--test", action="store_true", help="Run the production panel's remote-navigation cases headlessly")
parser.add_argument("--screenshot", type=Path, help="Write a 1920×1080 screenshot and exit")
args = parser.parse_args()
if args.test or args.screenshot:
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")
try:
    from PySide6.QtCore import QMetaObject, QTimer, QUrl, Q_ARG, Qt, QObject, QPoint
    from PySide6.QtGui import QGuiApplication
    from PySide6.QtQuick import QQuickView
except ImportError:
    raise SystemExit("Install the optional preview dependency first: python -m pip install PySide6")

app = QGuiApplication(sys.argv[:1])
view = QQuickView()
view.setTitle("Firewatch Home — Apps & Inputs mock (no TV connection)")
view.setResizeMode(QQuickView.SizeRootObjectToView)
size = (1920, 1080) if args.screenshot and args.size == "1280x720" else tuple(int(value) for value in args.size.split("x"))
view.resize(*size)
view.setSource(QUrl.fromLocalFile(str(Path(__file__).with_name("SetupPreview.qml").resolve())))
if view.status() == QQuickView.Error:
    raise SystemExit("Preview could not load: " + "\n".join(error.toString() for error in view.errors()))
QMetaObject.invokeMethod(view.rootObject(), "prepareCapture", Q_ARG("QVariant", args.view))
view.show()  # Normal resizable window, never fullscreen.

def run_tests():
    QMetaObject.invokeMethod(view.rootObject(), "runTests")
    result = json.loads(view.rootObject().property("testReport"))
    if result.get("passed"):
        from PySide6.QtTest import QTest
        panel = view.rootObject().findChild(QObject, "appsInputsPanel")
        # Send the real Qt press/release gesture through HomeControls.Keys, not only handleKey().
        launch_count = view.rootObject().property("launchCount")
        QTest.mouseClick(view, Qt.LeftButton, Qt.NoModifier, QPoint(round(view.width() * 348 / 1920), round(view.height() * 930 / 1080)))
        pointer_shield = panel.property("opened") and view.rootObject().property("launchCount") == launch_count
        result["modalPointerShield"] = pointer_shield
        QTest.keyPress(view, Qt.Key_Escape)
        press_open = panel.property("opened")
        QTest.keyRelease(view, Qt.Key_Escape)
        release_closed = not panel.property("opened")
        result["backGesture"] = {"pressKeepsPanelOpen": press_open, "releaseClosesPanel": release_closed}
        result["passed"] = bool(pointer_shield and press_open and release_closed)
    print(json.dumps(result, indent=2))
    app.exit(0 if result.get("passed") else 1)

def screenshot():
    args.screenshot.parent.mkdir(parents=True, exist_ok=True)
    ok = view.grabWindow().save(str(args.screenshot.resolve()))
    print(str(args.screenshot.resolve()) if ok else "Screenshot failed")
    app.exit(0 if ok else 1)

if args.test:
    QTimer.singleShot(200, run_tests)
elif args.screenshot:
    QTimer.singleShot(800, screenshot)
raise SystemExit(app.exec())
