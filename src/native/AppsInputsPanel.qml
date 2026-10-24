import QtQuick 2.12
import "LauncherConfig.js" as LauncherConfig

// Presentation only. No services, filesystem writes, or changes to the TV.
// Save emits a complete draft; the owning application validates and persists it.
Item {
    id: panel
    objectName: "appsInputsPanel"
    anchors.fill: parent
    visible: opened
    property bool opened: false
    property var launcherConfig: LauncherConfig.defaults()
    property var installedApps: []
    property bool inventoryAvailable: false
    property string inventoryMessage: ""
    property string fontFamily: "Arial"
    property bool firstRun: false
    property var draft: LauncherConfig.defaults()
    property string section: "apps"
    property string view: "list" // list, picker, rename
    property int row: 0
    property int action: 0 // title, earlier, later, remove
    property int zone: 1 // tabs, list, footer
    property int footer: 0 // Cancel, Save
    property int pickerRow: 0
    property bool adding: false
    property string renameValue: ""
    property string originalName: ""
    property int keyboardIndex: 0
    property bool lowerCase: false
    property string errorText: ""
    readonly property var entries: section === "apps" ? draft.apps : draft.inputs
    readonly property int capacity: section === "apps" ? 5 : 4
    readonly property bool canAdd: entries.length < capacity
    readonly property int listCount: entries.length + (canAdd ? 1 : 0)
    readonly property var keyboardKeys: (lowerCase ? "abcdefghijklmnopqrstuvwxyz0123456789" : "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").split("").concat(["Space", "⌫", "Clear", "Aa", "-", "&", ".", "'", "Done"])
    readonly property var choices: buildChoices()
    signal saveRequested(var value)
    signal dismissed()

    function clone(value) { return JSON.parse(JSON.stringify(value)); }
    function open(isFirstRun) {
        draft = clone(launcherConfig);
        firstRun = !!isFirstRun;
        section = "apps"; view = "list"; row = 0; action = 0; zone = 1; footer = 0;
        errorText = ""; opened = true;
    }
    function close() { opened = false; dismissed(); }
    function changed() { draft = clone(draft); errorText = ""; }
    function selectSection(value) { section = value; row = 0; action = 0; zone = 1; errorText = ""; }
    function containsId(id) {
        for (var i = 0; i < draft.apps.length; ++i) if (draft.apps[i].id === id) return i;
        return -1;
    }
    function containsPort(port) {
        for (var i = 0; i < draft.inputs.length; ++i) if (draft.inputs[i].port === port) return i;
        return -1;
    }
    function appUnavailable(entry) {
        if (section !== "apps" || !inventoryAvailable || !entry || !entry.id) return false;
        for (var i = 0; i < installedApps.length; ++i) if (installedApps[i].id === entry.id) return false;
        return true;
    }
    function buildChoices() {
        var result = [], seen = {}, source = installedApps || [];
        if (section === "apps") {
            // Existing choices remain editable if enumeration is unavailable;
            // a successful inventory never offers a known-missing replacement.
            source = inventoryAvailable ? source : source.concat(draft.apps);
            for (var i = 0; i < source.length; ++i) {
                var item = source[i];
                if (!item || !item.id || seen[item.id]) continue;
                seen[item.id] = true;
                if (containsId(item.id) >= 0 && (adding || (!entries[row] || entries[row].id !== item.id))) continue;
                result.push({ id: item.id, label: item.label || item.title || item.id, icon: item.icon || "" });
            }
        } else {
            for (var p = 1; p <= 4; ++p) {
                if (containsPort(p) >= 0 && (adding || (!entries[row] || entries[row].port !== p))) continue;
                result.push({ port: p, label: "HDMI " + p });
            }
        }
        return result;
    }
    function beginPicker(isAdding) {
        adding = isAdding; pickerRow = 0; errorText = ""; view = "picker";
    }
    function choose(index) {
        if (index < 0 || index >= choices.length) return;
        var choice = clone(choices[index]);
        if (!choice.icon || !/^(?:[A-Za-z0-9_-]+\/)*[A-Za-z0-9_-]+\.(png|svg)$/.test(choice.icon)) delete choice.icon;
        var next = clone(draft), list = section === "apps" ? next.apps : next.inputs;
        if (adding) {
            if (list.length >= capacity) return;
            list.push(choice); row = list.length - 1;
        } else list[row] = choice;
        draft = next; view = "list"; action = 0; zone = 1; errorText = "";
    }
    function moveEntry(direction) {
        var destination = row + direction;
        if (row >= entries.length || destination < 0 || destination >= entries.length) return;
        var next = clone(draft), list = section === "apps" ? next.apps : next.inputs;
        var item = list.splice(row, 1)[0]; list.splice(destination, 0, item);
        draft = next; row = destination; errorText = "";
    }
    function removeEntry() {
        if (row >= entries.length) return;
        var next = clone(draft), list = section === "apps" ? next.apps : next.inputs;
        list.splice(row, 1); draft = next;
        row = Math.min(row, entries.length); action = 0; errorText = "";
    }
    function beginRename() {
        if (row >= entries.length) return;
        originalName = entries[row].label;
        renameValue = originalName; keyboardIndex = 44; view = "rename"; errorText = "";
    }
    function commitRename() {
        var name = renameValue.trim();
        if (!name.length) { errorText = "Give this tile a name first."; return; }
        if (name.length > 40) { errorText = "Use 40 characters or fewer."; return; }
        var next = clone(draft), list = section === "apps" ? next.apps : next.inputs;
        list[row].label = name; draft = next; view = "list"; action = 0; errorText = "";
    }
    function typeKey(index) {
        var key = keyboardKeys[index];
        if (key === "Done") { commitRename(); return; }
        if (key === "Aa") { lowerCase = !lowerCase; return; }
        if (key === "⌫") renameValue = renameValue.slice(0, -1);
        else if (key === "Clear") renameValue = "";
        else if (renameValue.length < 40) renameValue += key === "Space" ? " " : key;
        errorText = "";
    }
    function save() {
        // Validator API is shared with file import; malformed data never escapes.
        try { LauncherConfig.validateConfig(draft); }
        catch (error) { errorText = String(error.message || error); zone = 2; footer = 1; return; }
        saveRequested(clone(draft));
        // The owner closes after persistence succeeds. On failure, retain the draft.
    }
    function saved() { close(); }
    function saveFailed(message) { errorText = message || "Could not save. Your changes are still here."; }
    function activate() {
        if (view === "picker") { choose(pickerRow); return; }
        if (view === "rename") { typeKey(keyboardIndex); return; }
        if (zone === 0) { zone = 1; return; }
        if (zone === 2) { if (footer === 0) close(); else save(); return; }
        if (row === entries.length) { beginPicker(true); return; }
        if (action === 0) beginRename();
        else if (action === 1) beginPicker(false);
        else if (action === 2) moveEntry(-1);
        else if (action === 3) moveEntry(1);
        else removeEntry();
    }
    function handle(key, repeat) {
        if (!opened) return false;
        if (key === Qt.Key_Back || key === Qt.Key_Escape || key === 461) {
            if (!repeat) { if (view !== "list") { view = "list"; errorText = ""; } else close(); }
            return true;
        }
        if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Select) {
            if (!repeat) activate(); return true;
        }
        var horizontal = key === Qt.Key_Left ? -1 : key === Qt.Key_Right ? 1 : 0;
        var vertical = key === Qt.Key_Up ? -1 : key === Qt.Key_Down ? 1 : 0;
        if (!horizontal && !vertical) return false;
        if (view === "rename") {
            keyboardIndex = (keyboardIndex + (horizontal || vertical * 9) + 45) % 45;
            return true;
        }
        if (view === "picker") {
            pickerRow = Math.max(0, Math.min(choices.length - 1, pickerRow + vertical)); return true;
        }
        if (zone === 0) {
            if (horizontal) section = section === "apps" ? "inputs" : "apps";
            row = 0; action = 0;
            if (vertical > 0) zone = 1;
        } else if (zone === 2) {
            if (horizontal) footer = 1 - footer;
            if (vertical < 0) { zone = 1; row = Math.max(0, listCount - 1); action = 0; }
        } else {
            if (horizontal && row < entries.length) action = (action + horizontal + 5) % 5;
            if (vertical < 0 && row === 0) zone = 0;
            else if (vertical > 0 && row >= listCount - 1) { zone = 2; footer = 1; }
            else if (vertical) { row = Math.max(0, Math.min(listCount - 1, row + vertical)); action = 0; }
        }
        return true;
    }

    // Modal pointer shield: clicking behind the editor must not launch an app
    // or change launcher focus while a draft is open. Back/Cancel are explicit.
    MouseArea { anchors.fill: parent; onClicked: function(mouse) { mouse.accepted = true; } }

    // A compact floating sheet leaves the chosen landscape visible around it.
    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 100
        anchors.bottom: parent.bottom; anchors.bottomMargin: 110
        width: 880; height: 660; radius: 12
        color: "#f01a2528"; border.width: 1; border.color: "#25fff0dc"
        Text { textFormat: Text.PlainText;
            x: 30; y: 22; text: panel.firstRun ? "Choose your shortcuts" : "Apps & Inputs"
            font.family: panel.fontFamily; font.pixelSize: 34; color: "#fff1dc"
        }
        Text { textFormat: Text.PlainText;
            x: 30; y: 66; width: 820
            text: panel.view === "rename" ? "Name your tile" : panel.view === "picker" ? (panel.section === "apps" ? (panel.inventoryAvailable ? "Choose an app already installed on this TV" : "Existing shortcuts · app discovery unavailable") : "Choose a physical HDMI port") : "Choose your apps and inputs."
            font.family: panel.fontFamily; font.pixelSize: 22; color: "#c5c8bd"; elide: Text.ElideRight
        }
        Item {
            visible: panel.view === "list"; x: 30; y: 114; width: 820; height: 430
            Row {
                spacing: 12
                Repeater {
                    model: ["Apps", "HDMI inputs"]
                    delegate: Rectangle {
                        width: 172; height: 46; radius: 5
                        readonly property bool current: panel.section === (index === 0 ? "apps" : "inputs")
                        color: current ? "#23fff1dc" : "transparent"
                        border.color: "#fff1dc"; border.width: panel.zone === 0 && current ? 2 : 0
                        Text { textFormat: Text.PlainText; anchors.centerIn: parent; text: modelData; color: "#fff1dc"; font.family: panel.fontFamily; font.pixelSize: 25 }
                        MouseArea { anchors.fill: parent; onClicked: panel.selectSection(index === 0 ? "apps" : "inputs") }
                        Accessible.role: Accessible.Button; Accessible.name: modelData; Accessible.onPressAction: panel.selectSection(index === 0 ? "apps" : "inputs")
                    }
                }
            }
            Text { textFormat: Text.PlainText; x: 706; y: 10; text: panel.entries.length + " / " + panel.capacity; color: "#c5c8bd"; font.family: panel.fontFamily; font.pixelSize: 23 }
            Repeater {
                model: panel.listCount
                delegate: Item {
                    id: tileRow
                    x: 0; y: 62 + index * 55; width: 820; height: 49
                    readonly property bool add: index === panel.entries.length
                    readonly property var entry: add ? ({}) : panel.entries[index]
                    readonly property bool current: panel.zone === 1 && panel.row === index
                    Rectangle { anchors.fill: parent; radius: 5; color: tileRow.current ? "#0efff1dc" : "transparent" }
                    Repeater {
                        model: tileRow.add ? 1 : 5
                        delegate: Rectangle {
                            x: [0, 432, 542, 614, 686][index]; width: [420, 100, 62, 62, 126][index]; height: 49; radius: 5
                            color: tileRow.current && panel.action === index ? "#14fff1dc" : "transparent"
                            border.width: tileRow.current && (tileRow.add || panel.action === index) ? 2 : 0; border.color: "#fff1dc"
                            Text { textFormat: Text.PlainText;
                                objectName: "shortcutLabel" + tileRow.entryIndex + "_" + index
                                anchors.verticalCenter: parent.verticalCenter; x: index === 0 ? 13 : 0; width: parent.width - (index === 0 ? 26 : 0)
                                text: tileRow.add ? "+ Add " + (panel.section === "apps" ? "an app" : "an input") : index === 0 ? tileRow.entry.label + (panel.appUnavailable(tileRow.entry) ? " · Not found on this TV" : "") : index === 1 ? "Change" : index === 2 ? "↑" : index === 3 ? "↓" : "Remove"
                                horizontalAlignment: index === 0 ? Text.AlignLeft : Text.AlignHCenter
                                elide: Text.ElideRight; font.family: panel.fontFamily; font.pixelSize: 24; color: "#fff1dc"
                                opacity: (index === 2 && tileRow.entryIndex === 0) || (index === 3 && tileRow.entryIndex === panel.entries.length - 1) ? 0.38 : 1
                            }
                            MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: { panel.zone = 1; panel.row = tileRow.entryIndex; panel.action = index; } onClicked: { panel.zone = 1; panel.row = tileRow.entryIndex; panel.action = index; panel.activate(); } }
                            Accessible.role: Accessible.Button
                            Accessible.name: tileRow.add ? "Add a shortcut" : index === 0 ? "Rename " + tileRow.entry.label : index === 1 ? "Change " + tileRow.entry.label : index === 2 ? "Move earlier" : index === 3 ? "Move later" : "Remove " + tileRow.entry.label
                            Accessible.onPressAction: { panel.zone = 1; panel.row = tileRow.entryIndex; panel.action = index; panel.activate(); }
                        }
                    }
                    readonly property int entryIndex: index
                }
            }
            Text { textFormat: Text.PlainText;
                x: 0; y: 397; width: 820; elide: Text.ElideRight; color: "#c5c8bd"; font.family: panel.fontFamily; font.pixelSize: 20
                text: panel.section === "inputs" && panel.row < panel.entries.length ? "Physical port: HDMI " + panel.entries[panel.row].port + "  ·  Remove hides only this shortcut" : !panel.inventoryAvailable ? (panel.inventoryMessage || "App discovery unavailable. You can still edit existing shortcuts and HDMI inputs.") : panel.appUnavailable(panel.entries[panel.row]) ? "This app was not found on the TV. Choose Change to select an installed app." : "OK renames  ·  ↑ ↓ reorder  ·  Remove hides only this shortcut"
            }
        }
        Item {
            visible: panel.view === "picker"; x: 30; y: 120; width: 820; height: 410
            ListView {
                id: pickerList; objectName: "appPickerList"; anchors.fill: parent; clip: true; model: panel.choices; currentIndex: panel.pickerRow
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                spacing: 8
                delegate: Rectangle {
                    width: 820; height: 54; radius: 5; color: index === panel.pickerRow ? "#18fff1dc" : "transparent"
                    border.width: index === panel.pickerRow ? 2 : 0; border.color: "#fff1dc"
                    Text { textFormat: Text.PlainText; x: 16; anchors.verticalCenter: parent.verticalCenter; width: 780; text: modelData.label; color: "#fff1dc"; font.family: panel.fontFamily; font.pixelSize: 26; elide: Text.ElideRight }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: panel.pickerRow = index; onClicked: panel.choose(index) }
                    Accessible.role: Accessible.Button; Accessible.name: modelData.label; Accessible.onPressAction: panel.choose(index)
                }
            }
            Text { textFormat: Text.PlainText; anchors.centerIn: parent; visible: !panel.choices.length; width: 700; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; text: "No more apps are available to add. Back returns to your shortcuts."; color: "#c5c8bd"; font.family: panel.fontFamily; font.pixelSize: 26 }
        }
        Item {
            visible: panel.view === "rename"; x: 30; y: 120; width: 820; height: 410
            Rectangle {
                width: 820; height: 64; radius: 5; color: "#151e20"; border.width: 1; border.color: "#66fff1dc"
                Text { textFormat: Text.PlainText; x: 18; anchors.verticalCenter: parent.verticalCenter; width: 780; text: panel.renameValue + "▏"; elide: Text.ElideLeft; color: "#fff1dc"; font.family: panel.fontFamily; font.pixelSize: 30 }
            }
            Grid {
                y: 88; columns: 9; spacing: 8
                Repeater {
                    model: panel.keyboardKeys
                    delegate: Rectangle {
                        width: 84; height: 48; radius: 5; color: panel.keyboardIndex === index ? "#24fff1dc" : "#09fff1dc"
                        border.width: panel.keyboardIndex === index ? 2 : 0; border.color: "#fff1dc"
                        Text { textFormat: Text.PlainText; anchors.centerIn: parent; text: modelData; color: "#fff1dc"; font.family: panel.fontFamily; font.pixelSize: index < 36 ? 26 : 20 }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: panel.keyboardIndex = index; onClicked: panel.typeKey(index) }
                        Accessible.role: Accessible.Button; Accessible.name: modelData === "⌫" ? "Delete last character" : modelData; Accessible.onPressAction: panel.typeKey(index)
                    }
                }
            }
            Text { textFormat: Text.PlainText; y: 368; text: "Back cancels this name change  ·  " + panel.renameValue.length + " / 40"; color: "#c5c8bd"; font.family: panel.fontFamily; font.pixelSize: 21 }
        }
        Text { textFormat: Text.PlainText;
            x: 30; y: 546; width: 820; height: 38; text: panel.errorText
            color: "#ffd09f"; font.family: panel.fontFamily; font.pixelSize: 21; wrapMode: Text.WordWrap
        }
        Rectangle { x: 30; y: 586; width: 820; height: 1; color: "#25fff1dc" }
        Text { textFormat: Text.PlainText; x: 30; y: 603; text: panel.view === "list" ? "Back cancels without saving" : "Back returns"; font.family: panel.fontFamily; font.pixelSize: 21; color: "#c5c8bd" }
        Row {
            x: 574; y: 596; spacing: 14; visible: panel.view === "list"
            Repeater {
                model: ["Cancel", "Save"]
                delegate: Rectangle {
                    width: 131; height: 48; radius: 5; color: index === 1 ? "#20fff1dc" : "transparent"
                    border.width: panel.zone === 2 && panel.footer === index ? 2 : 0; border.color: "#fff1dc"
                    Text { textFormat: Text.PlainText; anchors.centerIn: parent; text: modelData; color: "#fff1dc"; font.family: panel.fontFamily; font.pixelSize: 25 }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: { panel.zone = 2; panel.footer = index; } onClicked: { panel.zone = 2; panel.footer = index; panel.activate(); } }
                    Accessible.role: Accessible.Button; Accessible.name: modelData; Accessible.onPressAction: { panel.zone = 2; panel.footer = index; panel.activate(); }
                }
            }
        }
    }
}
