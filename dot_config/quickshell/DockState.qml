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
    readonly property var pinned: store.pinned

    function isPinned(id) { return store.pinned.includes(id) }

    function pin(id, index) {
        if (isPinned(id)) return
        const list = store.pinned.slice()
        list.splice(index ?? list.length, 0, id)
        store.pinned = list
    }

    function unpin(id) {
        store.pinned = store.pinned.filter(p => p !== id)
    }

    function move(id, index) {
        const from = store.pinned.indexOf(id)
        if (from < 0 || from === index) return
        const list = store.pinned.slice()
        list.splice(from, 1)
        list.splice(index, 0, id)
        store.pinned = list
    }

    FileView {
        path: Quickshell.statePath("dock.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter() }

        JsonAdapter {
            id: store
            // first start: the apps from packages.yaml
            property list<string> pinned: [
                "org.gnome.Nautilus",
                "com.mitchellh.ghostty",
                "app.zen_browser.zen",
                "dev.zed.Zed",
                "md.obsidian.Obsidian",
                "com.discordapp.Discord",
                "signal",
                "steam",
            ]
        }
    }
}
