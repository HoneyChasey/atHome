// Shared state of the dock (all screens): the apps kept in the dock, saved in
// ~/.local/state/quickshell/by-shell/<id>/dock.json so the order survives a restart
// (not in the chezmoi repo: it changes each time you pin / move an app)
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // `qs ipc call dock toggle`: keep the dock shown / back to auto-hide
    property bool forced: false

    IpcHandler {
        target: "dock"
        function toggle(): void { root.forced = !root.forced }
        function reveal(): void { root.forced = true }
        function autohide(): void { root.forced = false }
    }

    // desktop entry ids (the .desktop file name without the extension)
    // the list lives in a plain JS property, the file is only used to save it (a JsonAdapter
    // list ignored an assignment made right after another change: "Keep in Dock" did nothing)
    readonly property var defaults: [   // first start: the apps from packages.yaml
        "org.gnome.Nautilus",
        "com.mitchellh.ghostty",
        "app.zen_browser.zen",
        "dev.zed.Zed",
        "md.obsidian.Obsidian",
        "com.discordapp.Discord",
        "signal",
        "steam",
    ]
    property var pinned: []

    function isPinned(id) { return pinned.includes(id) }

    function save(list) {
        pinned = list
        file.setText(JSON.stringify({ pinned: list }, null, 4) + "\n")
    }

    function pin(id, index) {
        if (isPinned(id)) return
        const list = pinned.slice()
        list.splice(index === undefined ? list.length : index, 0, id)
        save(list)
    }

    function unpin(id) {
        save(pinned.filter(p => p !== id))
    }

    function move(id, index) {
        const from = pinned.indexOf(id)
        if (from < 0 || from === index) return
        const list = pinned.slice()
        list.splice(from, 1)
        list.splice(index, 0, id)
        save(list)
    }

    FileView {
        id: file
        path: Quickshell.statePath("dock.json")
        onLoaded: {
            try {
                const list = JSON.parse(text()).pinned
                root.pinned = Array.isArray(list) ? list : root.defaults
            } catch (e) {
                root.pinned = root.defaults
            }
        }
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) root.save(root.defaults) }
    }
}
