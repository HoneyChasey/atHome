// Workspace indicators widget
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    spacing: 4
    Repeater {
        model: Hyprland.workspaces

        Rectangle {
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

            implicitWidth: row.implicitWidth + 12
            implicitHeight: 22
            radius: 4
            color: modelData.focused ? "#89b4fa" : "#313244"

            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: modelData.id
                    color: modelData.focused ? "#1e1e2e" : "#cdd6f4"
                }

                Repeater {
                    model: apps

                    Item {
                        required property var modelData
                        property string appId: modelData

                        property var glyphMap: ({ // use hyprctl clients | grep -i class to find the class
                            "discord": "󰙯",
                            "steam": "",
                            "org.mozilla.firefox": "",
                            "thunar": "",
                            "org.pwmt.zathura": "󱔘",
                            "nvim": "", // TODO fix this. How change the logo based on the window title
                            "com.moonlight_stream.Moonlight": ""

                        })
                        property string glyph: glyphMap[appId] ?? ""
                        property string svgPath: "root:/icons/" + appId + ".svg"

                        implicitWidth: 18
                        implicitHeight: 18

                        Text {
                            anchors.centerIn: parent
                            visible: glyph !== ""
                            text: glyph
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 16
                            color: "#cdd6f4"
                        }

                        Image {
                            anchors.centerIn: parent
                            visible: glyph === "" && status === Image.Ready
                            source: glyph === "" ? svgPath : ""
                            sourceSize.width: 16
                            sourceSize.height: 16
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + modelData.id)
            }
        }
    }
}
