// Menu under the clock: big time and date, month calendar, notifications (swaync)
// open: click the clock in the bar, or `qs ipc call calendar toggle`
pragma Singleton
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Singleton {
    id: root

    property bool open: false
    property var barWindow: null

    // ---- notifications, live from swaync ----
    property int count: 0
    property bool dnd: false

    function toggle(win) {
        if (open) { open = false; return }
        barWindow = win ?? null
        ControlCenter.open = false
        const now = new Date()
        viewYear = now.getFullYear()
        viewMonth = now.getMonth()
        open = true
    }

    function setDnd(on) {
        dnd = on
        Quickshell.execDetached(["swaync-client", on ? "-dn" : "-df"])
    }

    // `swaync-client -swb` prints one JSON line per change:
    // {"text": "<count>", "alt": "none|notification|dnd-none|dnd-notification|inhibited-...", ...}
    Process {
        id: swaync
        command: ["swaync-client", "-swb"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const j = JSON.parse(line)
                    root.count = parseInt(j.text) || 0
                    root.dnd = (j.alt ?? "").startsWith("dnd")
                } catch (e) {}
            }
        }
        onExited: restart.start()   // swaync restarted / not started yet
    }
    Timer { id: restart; interval: 3000; onTriggered: swaync.running = true }

    IpcHandler {
        target: "calendar"
        function toggle(): void { root.toggle(null) }
    }

    // ---- calendar ----
    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth()   // 0..11

    function shiftMonth(d) {
        const m = viewMonth + d
        viewYear += Math.floor(m / 12)
        viewMonth = ((m % 12) + 12) % 12
    }

    // 6 weeks starting on monday
    function cells() {
        const first = new Date(viewYear, viewMonth, 1)
        const offset = (first.getDay() + 6) % 7
        const today = new Date()
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(viewYear, viewMonth, 1 - offset + i)
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === viewMonth,
                today: d.toDateString() === today.toDateString(),
            })
        }
        return out
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    // ---- building blocks ----
    component Tile: Rectangle {
        radius: 0
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.6)
        border.width: 1
        border.color: Theme.surface
    }

    component Label: Text {
        font.family: Theme.font
        font.pixelSize: 12
        color: Theme.text
    }

    component IconButton: Rectangle {
        id: btn
        property string icon
        property string label
        property bool active: false
        signal clicked()
        implicitHeight: 30
        implicitWidth: btnRow.implicitWidth + 20
        radius: height / 2
        color: active ? Theme.accent
             : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, btnArea.containsMouse ? 0.2 : 0.1)
        Behavior on color { ColorAnimation { duration: 150 } }
        RowLayout {
            id: btnRow
            anchors.centerIn: parent
            spacing: 6
            Text {
                text: btn.icon
                font.family: Theme.font
                font.pixelSize: 14
                color: btn.active ? Theme.bg : Theme.text
            }
            Text {
                visible: btn.label !== ""
                text: btn.label
                font.family: Theme.font
                font.pixelSize: 11
                color: btn.active ? Theme.bg : Theme.text
            }
        }
        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    // ---- the popup, centered under the bar ----
    PanelWindow {
        id: panel
        screen: root.barWindow?.screen
             ?? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
             ?? Quickshell.screens[0]
        visible: root.open || card.opacity > 0
        anchors { top: true }
        margins { top: 6 }
        exclusiveZone: 0
        implicitWidth: card.width
        implicitHeight: card.height + 8
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-calendar"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        HyprlandFocusGrab {
            active: root.open && panel.visible
            windows: root.barWindow ? [panel, root.barWindow] : [panel]
            onCleared: root.open = false
        }

        Rectangle {
            id: card
            width: 320
            height: content.implicitHeight + 24
            radius: 0
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

                // ---- time & date ----
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm:ss")
                        font.family: Theme.font
                        font.pixelSize: 40
                        font.bold: true
                        color: Theme.text
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDateTime(clock.date, "dddd d MMMM yyyy")
                        color: Theme.subtext
                    }
                }

                // ---- calendar ----
                Tile {
                    Layout.fillWidth: true
                    implicitHeight: calCol.implicitHeight + 20
                    ColumnLayout {
                        id: calCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: "󰅁"
                                font.pixelSize: 16
                                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.shiftMonth(-1) }
                            }
                            Label {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                font.bold: true
                                text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                                MouseArea {   // back to this month
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { const n = new Date(); root.viewYear = n.getFullYear(); root.viewMonth = n.getMonth() }
                                }
                            }
                            Label {
                                text: "󰅂"
                                font.pixelSize: 16
                                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.shiftMonth(1) }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 7
                            rowSpacing: 2
                            columnSpacing: 2

                            // weekday names, monday first
                            Repeater {
                                model: 7
                                Label {
                                    required property int index
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: 11
                                    color: Theme.subtext
                                    text: Qt.locale().dayName((index + 1) % 7, Locale.ShortFormat).slice(0, 2)
                                }
                            }

                            Repeater {
                                model: root.open ? root.cells() : []
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 28
                                    radius: 8
                                    color: modelData.today ? Theme.accent : "transparent"
                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.day
                                        font.bold: modelData.today
                                        color: modelData.today ? Theme.bg
                                             : modelData.inMonth ? Theme.text
                                             : Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.5)
                                    }
                                }
                            }
                        }
                    }
                    // scroll to change month
                    WheelHandler {
                        onWheel: event => root.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
                    }
                }

                // ---- notifications ----
                Tile {
                    Layout.fillWidth: true
                    implicitHeight: notifCol.implicitHeight + 20
                    ColumnLayout {
                        id: notifCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Label {
                                text: root.dnd ? "󰂛" : root.count > 0 ? "󱅫" : "󰂚"
                                font.pixelSize: 16
                                color: root.count > 0 && !root.dnd ? Theme.accent : Theme.subtext
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Label { text: "Notifications"; font.bold: true }
                                Label {
                                    font.pixelSize: 11
                                    color: Theme.subtext
                                    text: (root.count === 0 ? "No notifications"
                                         : root.count === 1 ? "1 notification"
                                         : root.count + " notifications")
                                        + (root.dnd ? " · Do Not Disturb" : "")
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            IconButton {
                                Layout.fillWidth: true
                                icon: "󰂚"
                                label: "Show"
                                onClicked: {
                                    root.open = false
                                    Quickshell.execDetached(["swaync-client", "-op", "-sw"])
                                }
                            }
                            IconButton {
                                Layout.fillWidth: true
                                icon: "󰎟"
                                label: "Clear"
                                onClicked: Quickshell.execDetached(["swaync-client", "-C", "-sw"])
                            }
                            IconButton {
                                Layout.fillWidth: true
                                icon: "󰂛"
                                label: "DND"
                                active: root.dnd
                                onClicked: root.setDnd(!root.dnd)
                            }
                        }
                    }
                }

                // ---- appearance: dark / light mode (whole system, see Theme.qml) ----
                Tile {
                    Layout.fillWidth: true
                    implicitHeight: themeRow.implicitHeight + 20
                    RowLayout {
                        id: themeRow
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                        spacing: 6
                        Label {
                            Layout.fillWidth: true
                            text: "Appearance"
                            font.bold: true
                        }
                        IconButton {
                            icon: "󰖔"
                            label: "Dark"
                            active: Theme.dark
                            onClicked: Theme.setDark(true)
                        }
                        IconButton {
                            icon: "󰖙"
                            label: "Light"
                            active: !Theme.dark
                            onClicked: Theme.setDark(false)
                        }
                    }
                }
            }
        }
    }
}
