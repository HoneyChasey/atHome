// Apps of the dock: pinned apps (saved on disk) and open windows grouped by app
// shared by the docks of every screen
// pinned apps are saved in ~/.local/state/quickshell/by-shell/<id>/dock.json
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    // pinned at first start: names of the .desktop files (without .desktop)
    readonly property var defaultPinned: [
        "org.gnome.Nautilus",
        "com.mitchellh.ghostty",
        "app.zen_browser.zen",
        "md.obsidian.Obsidian",
        "com.discordapp.Discord",
    ]

    readonly property var pinned: Array.from(store.pinned)

    // windows grouped by app: { "<desktop id>": [HyprlandToplevel, ...] }
    // the key is the .desktop file of the window (same lookup as the workspace icons),
    // or its app_id when it has none
    readonly property var windows: {
        DesktopEntries.applications.values   // re-run once desktop entries are loaded
        const out = ({})
        for (const t of Hyprland.toplevels.values) {
            const appId = t.wayland ? t.wayland.appId
                        : (t.lastIpcObject ? t.lastIpcObject.class : "")
            if (!appId) continue
            const key = keyOf(appId)
            if (!out[key]) out[key] = []
            out[key].push(t)
        }
        return out
    }

    // apps shown in the dock: pinned first, then the other open apps
    readonly property var apps: {
        const list = pinned.slice()
        for (const key of Object.keys(windows))
            if (!list.includes(key)) list.push(key)
        return list
    }

    function keyOf(appId) {
        const entry = DesktopEntries.heuristicLookup(appId)
        return entry ? entry.id : appId
    }

    function entryOf(key) {
        DesktopEntries.applications.values
        return DesktopEntries.byId(key) ?? DesktopEntries.heuristicLookup(key)
    }

    function launch(key) {
        const entry = entryOf(key)
        if (entry) entry.execute()
        else Quickshell.execDetached([key])     // no .desktop file: try the app_id as a command
    }

    function focus(t) {
        const addr = t.address.startsWith("0x") ? t.address : "0x" + t.address
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${addr}" })`)
    }

    // like macOS: open the app, or focus its window (next window if one is already focused)
    function activate(key) {
        const wins = windows[key] ?? []
        if (wins.length === 0) { launch(key); return false }
        const current = wins.findIndex(t => t.activated)
        focus(wins[(current + 1) % wins.length])
        return true
    }

    function quit(key) {
        for (const t of windows[key] ?? [])
            if (t.wayland) t.wayland.close()
    }

    function isPinned(key) { return pinned.includes(key) }

    function setPinned(key, pin) {
        if (pin === isPinned(key)) return
        store.pinned = pin ? pinned.concat([key]) : pinned.filter(k => k !== key)
        file.writeAdapter()
    }

    FileView {
        id: file
        path: Quickshell.statePath("dock.json")
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }

        JsonAdapter {
            id: store
            property list<string> pinned: root.defaultPinned
        }
    }

    IpcHandler {
        target: "dock"
        function pin(key: string): void { root.setPinned(key, true) }
        function unpin(key: string): void { root.setPinned(key, false) }
    }
}
