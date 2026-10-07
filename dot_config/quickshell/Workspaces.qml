// Workspace indicators widget: one rounded square per workspace, with the icons of its open apps
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

RowLayout {
    spacing: 4

    // icon of one app: nerd glyph > custom svg in icons/ > desktop entry icon > generic window
    component AppIcon: Item {
        id: icon
        required property string appId
        property color glyphColor: Theme.text

        readonly property var glyphMap: ({ // use hyprctl clients | grep -i class to find the class
            "discord": "󰙯",
            "steam": "",
            "org.mozilla.firefox": "",
            "thunar": "",
            "org.pwmt.zathura": "󱔘",
            "nvim": "", // TODO fix this. How change the logo based on the window title
            "com.moonlight_stream.Moonlight": ""
        })
        readonly property string glyph: glyphMap[appId] ?? ""
        readonly property string desktopIcon: {
            const entry = DesktopEntries.heuristicLookup(appId)
            return entry ? Quickshell.iconPath(entry.icon, true) : ""
        }
        readonly property bool useGlyph: glyph !== ""
        readonly property bool useCustom: !useGlyph && custom.status === Image.Ready
        readonly property bool useDesktop: !useGlyph && !useCustom && desktopIcon !== ""

        implicitWidth: 16
        implicitHeight: 16

        Text {
            anchors.centerIn: parent
            visible: icon.useGlyph || (!icon.useCustom && !icon.useDesktop)
            text: icon.useGlyph ? icon.glyph : "󰖯"
            font.family: Theme.font
            font.pixelSize: 15
            color: icon.glyphColor
        }
        Image {
            id: custom
            anchors.fill: parent
            visible: icon.useCustom
            source: icon.useGlyph ? "" : "root:/icons/" + icon.appId + ".svg"
            sourceSize.width: 16
            sourceSize.height: 16
        }
        IconImage {
            anchors.fill: parent
            visible: icon.useDesktop
            source: icon.useDesktop ? icon.desktopIcon : ""
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
