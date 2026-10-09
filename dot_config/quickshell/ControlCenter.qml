// Control center, like on macOS: wifi, bluetooth, do not disturb, dark / light mode,
// brightness, volume and the media playing
// open: control center icon in the bar, or `qs ipc call controlcenter toggle`
pragma Singleton
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

Singleton {
    id: root

    property bool open: false
    property var barWindow: null       // bar that opened it: the popup shows on its screen

    // ---- state ----
    property bool wifiOn: false
    property string ssid: ""
    property bool dnd: false
    property bool hasBacklight: false
    property real brightness: 0        // 0..1, perceptual (same -e4 curve as the hyprland keybinds)

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevice: adapter ? adapter.devices.values.find(d => d.connected) ?? null : null
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    function toggle(win) {
        if (open) { open = false; return }
        barWindow = win ?? null
        refreshProc.running = true
        open = true
    }

    // close first so the popup isn't in the screenshot / lock screen
    function closeAndRun(cmd) {
        open = false
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; " + cmd])
    }

    function setWifi(on) {
        wifiOn = on
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"])
    }

    function setDnd(on) {
        dnd = on
        Quickshell.execDetached(["swaync-client", on ? "-dn" : "-df"])
    }

    // brightnessctl is slow to start: send the last value once the previous call is done
    property real pendingBrightness: -1
    function setBrightness(v) {
        brightness = v
        pendingBrightness = v
        if (!brightSet.running) brightSet.send()
    }

    PwObjectTracker { objects: [root.sink] }

    Process {
        id: refreshProc
        command: ["sh", "-c", `
            echo "wifi|$(nmcli radio wifi 2>/dev/null)"
            echo "ssid|$(nmcli -t -f ACTIVE,SSID dev wifi list --rescan no 2>/dev/null | grep '^yes:' | head -n1 | cut -d: -f2-)"
            echo "dnd|$(swaync-client -D 2>/dev/null)"
            echo "bright|$(brightnessctl -m 2>/dev/null)"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const sep = line.indexOf("|")
                    const key = line.slice(0, sep), val = line.slice(sep + 1).trim()
                    if (key === "wifi") root.wifiOn = val === "enabled"
                    else if (key === "ssid") root.ssid = val.replace(/\\:/g, ":")
                    else if (key === "dnd") root.dnd = val === "true"
                    else if (key === "bright") {
                        const f = val.split(",")              // device,class,cur,pct%,max
                        const cur = Number(f[2]), max = Number(f[4])
                        root.hasBacklight = max > 0
                        if (max > 0 && !brightSet.running) root.brightness = Math.pow(cur / max, 1 / 4)
                    }
                }
            }
        }
    }

    Process {
        id: brightSet
        function send() {
            command = ["brightnessctl", "-e4", "-n2", "set", Math.round(root.pendingBrightness * 100) + "%"]
            root.pendingBrightness = -1
            running = true
        }
        onExited: if (root.pendingBrightness >= 0) send()
    }

    Timer {
        interval: 3000; repeat: true
        running: root.open
        onTriggered: refreshProc.running = true
    }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { root.toggle(null) }
    }

    // ---- building blocks ----

    // rounded block holding a group of controls
    component Tile: Rectangle {
        radius: 16
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.6)
        border.width: 1
        border.color: Theme.surface
    }

    component Label: Text {
        font.family: Theme.font
        font.pixelSize: 12
        color: Theme.text
        elide: Text.ElideRight
    }

    // round icon button: accent when on
    component RoundButton: Rectangle {
        id: btn
        property string icon
        property bool active: false
        signal clicked()
        implicitWidth: 32
        implicitHeight: 32
        radius: width / 2
        color: active ? Theme.accent
             : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, btnArea.containsMouse ? 0.2 : 0.12)
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
            anchors.centerIn: parent
            text: btn.icon
            font.family: Theme.font
            font.pixelSize: 16
            color: btn.active ? Theme.bg : Theme.text
        }
        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    // round toggle + title / status, clicking the text opens the settings app
    component ToggleRow: RowLayout {
        id: tr
        property string icon
        property bool active
        property string title
        property string subtitle
        signal toggled()
        signal openSettings()
        spacing: 10
        RoundButton { icon: tr.icon; active: tr.active; onClicked: tr.toggled() }
        Item {
            Layout.fillWidth: true
            implicitHeight: texts.implicitHeight
            ColumnLayout {
                id: texts
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 0
                Label { Layout.fillWidth: true; text: tr.title; font.bold: true }
                Label { Layout.fillWidth: true; text: tr.subtitle; color: Theme.subtext; font.pixelSize: 11 }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: tr.openSettings()
            }
        }
    }

    // macOS style slider: thick pill, icon inside the fill
    component Slider: Item {
        id: sl
        property real value: 0
        property string icon
        property bool dim: false
        signal moved(real v)
        signal iconClicked()

        property bool dragging: false
        property real dragValue: 0
        readonly property real shown: Math.max(0, Math.min(1, dragging ? dragValue : value))

        implicitHeight: 26
        Layout.fillWidth: true

        function valueAt(x) { return Math.max(0, Math.min(1, (x - height / 2) / (width - height))) }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
        }
        Rectangle {
            width: sl.height + (sl.width - sl.height) * sl.shown
            height: parent.height
            radius: height / 2
            color: sl.dim ? Theme.subtext : Theme.accent
            Behavior on width { enabled: !sl.dragging; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => {
                sl.dragValue = sl.valueAt(mouse.x)
                sl.dragging = true
                sl.moved(sl.dragValue)
            }
            onPositionChanged: mouse => {
                if (!pressed) return
                sl.dragValue = sl.valueAt(mouse.x)
                sl.moved(sl.dragValue)
            }
            onReleased: sl.dragging = false
            onWheel: wheel => sl.moved(Math.max(0, Math.min(1, sl.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
        Text {
            x: (sl.height - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            text: sl.icon
            font.family: Theme.font
            font.pixelSize: 14
            color: Theme.bg
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: sl.iconClicked()
            }
        }
    }

    // ---- the popup ----
    PanelWindow {
        id: panel
        screen: root.barWindow?.screen
             ?? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
             ?? Quickshell.screens[0]
        visible: root.open || card.opacity > 0
        anchors { top: true; right: true }
        margins { top: 6; right: 10 }
        exclusiveZone: 0                 // sits under the bar, reserves no space
        implicitWidth: card.width
        implicitHeight: card.height + 8
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-control-center"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        // click outside closes it (clicks on the bar still reach the bar button)
        HyprlandFocusGrab {
            active: root.open && panel.visible
            windows: root.barWindow ? [panel, root.barWindow] : [panel]
            onCleared: root.open = false
        }

        Rectangle {
            id: card
            width: 360
            height: content.implicitHeight + 24
            radius: 20
            color: Theme.bg
            border.width: 1
            border.color: Theme.surface
            opacity: root.open ? 1 : 0
            y: root.open ? 0 : -8
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            focus: root.open
            Keys.onEscapePressed: root.open = false

            ColumnLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // ---- connectivity ----
                    Tile {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 150
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 0

                            ToggleRow {
                                icon: root.wifiOn ? "󰤨" : "󰤭"
                                active: root.wifiOn
                                title: "Wi-Fi"
                                subtitle: !root.wifiOn ? "Off" : root.ssid !== "" ? root.ssid : "Not connected"
                                onToggled: root.setWifi(!root.wifiOn)
                                onOpenSettings: root.closeAndRun("ghostty -e nmtui")
                            }
                            Item { Layout.fillHeight: true }
                            ToggleRow {
                                icon: root.adapter?.enabled ? "󰂯" : "󰂲"
                                active: root.adapter?.enabled ?? false
                                title: "Bluetooth"
                                subtitle: !root.adapter ? "Unavailable"
                                        : !root.adapter.enabled ? "Off"
                                        : root.btDevice ? root.btDevice.name : "On"
                                onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                                onOpenSettings: root.closeAndRun("ghostty -e bluetui")
                            }
                            Item { Layout.fillHeight: true }
                            ToggleRow {
                                icon: root.dnd ? "󰂛" : "󰂚"
                                active: root.dnd
                                title: "Focus"
                                subtitle: root.dnd ? "Do Not Disturb" : "Off"
                                onToggled: root.setDnd(!root.dnd)
                                onOpenSettings: root.setDnd(!root.dnd)
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: 10

                        // ---- dark / light mode ----
                        Tile {
                            Layout.fillWidth: true
                            implicitHeight: 70
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10
                                RoundButton {
                                    icon: Theme.dark ? "󰖔" : "󰖙"
                                    active: true
                                    onClicked: Theme.setDark(!Theme.dark)
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Label { Layout.fillWidth: true; text: "Appearance"; font.bold: true }
                                    Label { Layout.fillWidth: true; text: Theme.dark ? "Dark" : "Light"; color: Theme.subtext; font.pixelSize: 11 }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                z: -1
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Theme.setDark(!Theme.dark)
                            }
                        }

                        // ---- quick actions ----
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Repeater {
                                model: [
                                    { icon: "󰹑", name: "Screenshot", cmd: "hyprshot -m region" },
                                    { icon: "󰌾", name: "Lock",       cmd: "hyprlock" },
                                ]
                                Tile {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 70
                                    color: actionArea.containsMouse
                                         ? Theme.surface
                                         : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.6)
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData.icon
                                            font.family: Theme.font
                                            font.pixelSize: 20
                                            color: Theme.text
                                        }
                                        Label { Layout.alignment: Qt.AlignHCenter; text: modelData.name; font.pixelSize: 11 }
                                    }
                                    MouseArea {
                                        id: actionArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.closeAndRun(modelData.cmd)
                                    }
                                }
                            }
                        }
                    }
                }

                // ---- display ----
                Tile {
                    Layout.fillWidth: true
                    visible: root.hasBacklight
                    implicitHeight: displayCol.implicitHeight + 24
                    ColumnLayout {
                        id: displayCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                        spacing: 8
                        Label { text: "Display"; font.bold: true }
                        Slider {
                            icon: root.brightness < 0.34 ? "󰃞" : root.brightness < 0.67 ? "󰃟" : "󰃠"
                            value: root.brightness
                            onMoved: v => root.setBrightness(Math.max(0.05, v))
                        }
                    }
                }

                // ---- sound ----
                Tile {
                    Layout.fillWidth: true
                    visible: root.sink?.audio ?? false
                    implicitHeight: soundCol.implicitHeight + 24
                    ColumnLayout {
                        id: soundCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Sound"; font.bold: true }
                            Label {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                text: root.sink?.description ?? ""
                                color: Theme.subtext
                                font.pixelSize: 11
                            }
                        }
                        Slider {
                            readonly property real vol: root.sink?.audio?.volume ?? 0
                            readonly property bool muted: root.sink?.audio?.muted ?? false
                            icon: muted || vol <= 0 ? "󰝟" : vol < 0.34 ? "󰕿" : vol < 0.67 ? "󰖀" : "󰕾"
                            value: vol
                            dim: muted
                            onMoved: v => {
                                if (!root.sink?.audio) return
                                root.sink.audio.volume = v
                                if (v > 0 && root.sink.audio.muted) root.sink.audio.muted = false
                            }
                            onIconClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
                        }
                    }
                }

                // ---- now playing ----
                Tile {
                    Layout.fillWidth: true
                    visible: root.player !== null
                    implicitHeight: 68
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        ClippingRectangle {
                            implicitWidth: 44
                            implicitHeight: 44
                            radius: 8
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
                            Text {
                                anchors.centerIn: parent
                                visible: art.status !== Image.Ready
                                text: "󰎆"
                                font.family: Theme.font
                                font.pixelSize: 20
                                color: Theme.subtext
                            }
                            Image {
                                id: art
                                anchors.fill: parent
                                source: root.player?.trackArtUrl ?? ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Label {
                                Layout.fillWidth: true
                                text: root.player?.trackTitle || root.player?.identity || ""
                                font.bold: true
                            }
                            Label {
                                Layout.fillWidth: true
                                text: root.player?.trackArtist || root.player?.identity || ""
                                color: Theme.subtext
                                font.pixelSize: 11
                            }
                        }

                        Repeater {
                            model: [
                                { icon: "󰒮", act: "prev" },
                                { icon: root.player?.isPlaying ? "󰏤" : "󰐊", act: "play" },
                                { icon: "󰒭", act: "next" },
                            ]
                            Text {
                                required property var modelData
                                text: modelData.icon
                                font.family: Theme.font
                                font.pixelSize: 18
                                color: Theme.text
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const p = root.player
                                        if (!p) return
                                        if (modelData.act === "prev" && p.canGoPrevious) p.previous()
                                        else if (modelData.act === "next" && p.canGoNext) p.next()
                                        else if (modelData.act === "play" && p.canTogglePlaying) p.togglePlaying()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
