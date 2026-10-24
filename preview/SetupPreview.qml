import QtQuick 2.12
import "../src/native" as Firewatch
import "../src/native/LauncherConfig.js" as LauncherConfig
import "PanelTests.js" as PanelTests

// Desktop-only harness: production controls, static art, mock inventory and saves.
Item {
    id: preview
    objectName: "setupPreview"
    width: 1280; height: 720; focus: true
    property var config: LauncherConfig.defaults()
    property int saves: 0
    property bool failSave: false
    property int stockHomeCount: 0
    property int launchCount: 0
    property string lastLaunch: ""
    property string notice: "Desktop mock • Arrows + Enter • Esc = Back • F2 = setup • F3 = unavailable apps • F4 = failed save"
    property string testReport: ""
    readonly property int plainTextFormat: Text.PlainText
    readonly property int containPosition: ListView.Contain
    property var appInventory: [
        {id: "youtube.leanback.v4", label: "YouTube"},
        {id: "bbc.iplayer.3.0", label: "BBC iPlayer"},
        {id: "com.fvp.itv", label: "ITVX"},
        {id: "com.fvp.ch4", label: "Channel 4"},
        {id: "amazon", label: "Prime Video"},
        {id: "netflix", label: "Netflix", icon: "/unavailable/device/icon.png"},
        {id: "com.disney.disneyplus-prod", label: "Disney+"},
        {id: "com.webos.app.browser", label: "Web Browser"}
    ]
    Item {
        id: stage
        width: 1920; height: 1080; anchors.centerIn: parent
        scale: Math.min(preview.width / width, preview.height / height)
        Image { anchors.fill: parent; source: "../src/native/assets/autumn/evening-vibrant.jpg"; fillMode: Image.PreserveAspectCrop }
        Firewatch.HomeControls {
            id: home; objectName: "mockHomeControls"
            anchors.fill: parent
            launcherConfig: preview.config; installedApps: preview.appInventory
            inventoryAvailable: true; reducedMotion: true
            inventoryMessage: "Mock app discovery is offline. Existing shortcuts can still be edited."
            onSetupRequested: function(config) {
                if (preview.failSave) { setupSaveFailed("Mock storage failure. Your original shortcuts are unchanged."); return; }
                preview.config = JSON.parse(JSON.stringify(config)); preview.saves++; setupSaved();
                preview.notice = "Saved in this mock only. No TV was contacted. F2 opens setup again.";
            }
            onTargetRequested: function(appId, label, index) { preview.launchCount++; preview.lastLaunch = appId; preview.notice = "Mock launch: " + label + " · " + appId + " (no TV connection)"; }
            onLgHomeRequested: { preview.stockHomeCount++; preview.notice = "Mock LG Home requested (no TV connection)"; }
        }
    }
    Rectangle {
        anchors.left: parent.left; anchors.top: parent.top; width: parent.width; height: 25; color: "#bb10191c"
        Text { anchors.centerIn: parent; text: preview.notice; color: "#e6e7dd"; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width - 24; horizontalAlignment: Text.AlignHCenter }
    }
    function findItem(item, name) {
        if (item.objectName === name) return item;
        for (var i = 0; i < item.children.length; i++) { var result = findItem(item.children[i], name); if (result) return result; }
        return null;
    }
    function findPanel(item) { return findItem(item, "appsInputsPanel"); }
    Keys.onPressed: {
        if (event.key === Qt.Key_F2) { home.openSetup(false); event.accepted = true; }
        else if (event.key === Qt.Key_F3) { home.inventoryAvailable = !home.inventoryAvailable; home.installedApps = home.inventoryAvailable ? preview.appInventory : []; event.accepted = true; }
        else if (event.key === Qt.Key_F4) { preview.failSave = !preview.failSave; preview.notice = "Mock storage failure: " + preview.failSave; event.accepted = true; }
    }
    function runTests() {
        try { testReport = JSON.stringify(PanelTests.run(findPanel(home), preview, home)); }
        catch (error) { testReport = JSON.stringify({passed: false, error: String(error) + "\n" + String(error.stack || "")}); }
    }
    function prepareCapture(mode) {
        var panel = findPanel(home);
        if (mode === "home") { panel.close(); home.select(0); }
        else { home.openSetup(true); if (mode === "inputs") panel.selectSection("inputs"); else if (mode === "rename") { panel.selectSection("inputs"); panel.row = 2; panel.beginRename(); } }
    }
    Component.onCompleted: { home.openSetup(true); home.forceActiveFocus(); }
}
