// Workspace indicators widget: one rounded square per workspace, with the icons of its open apps
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

RowLayout {
    spacing: 4

    // icon of one app, found by the freedesktop standards: app_id -> .desktop file -> icon theme
    // falls back to a generic window glyph when the app has no icon
    component AppIcon: Item {
        id: icon
        required property string appId
        property color glyphColor: Theme.text

        readonly property string desktopIcon: {
            // desktop entries load in the background after startup:
            // reading the list makes this re-run once they are loaded
            DesktopEntries.applications.values
            const entry = DesktopEntries.heuristicLookup(appId)
            return entry ? Quickshell.iconPath(entry.icon, true) : ""
        }

        implicitWidth: 16
        implicitHeight: 16

        IconImage {
            anchors.fill: parent
            visible: icon.desktopIcon !== ""
            source: icon.desktopIcon
        }
        Text {
            anchors.centerIn: parent
            visible: icon.desktopIcon === ""
            text: "󰖯"
            font.family: Theme.font
            font.pixelSize: 15
            color: icon.glyphColor
        }
    }

    Repeater {
        model: Hyprland.workspaces

        Rectangle {
            id: ws
            required property var modelData

            // windows on THIS workspace
            property var wsToplevels: Hyprland.toplevels.values.filter(
                t => t.workspace && t.workspace.id === modelData.id)

            // unique app ids on this workspace
            property var apps: {
                let seen = ({})
                let out = []
                for (const t of wsToplevels) {
                    const id = t.wayland ? t.wayland.appId
                             : (t.lastIpcObject ? t.lastIpcObject.class : "")
                    if (id && !seen[id]) { seen[id] = true; out.push(id) }
                }
                return out
            }

            visible: modelData.id > 0       // hide special workspaces
            implicitWidth: row.implicitWidth + 14
            implicitHeight: 22
            radius: 7
            color: modelData.focused ? Theme.accent
                 : hover.containsMouse ? Theme.surface
                 : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.55)
            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: ws.modelData.id
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.bold: ws.modelData.focused
                    color: ws.modelData.focused ? Theme.bg : Theme.text
                }

                Repeater {
                    model: ws.apps
                    AppIcon {
                        required property string modelData
                        appId: modelData
                        glyphColor: ws.modelData.focused ? Theme.bg : Theme.text
                    }
                }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ws.modelData.activate()
            }
        }
    }
}
