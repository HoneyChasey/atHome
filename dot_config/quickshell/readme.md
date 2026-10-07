# Quickshell bar

## App icons in the workspaces

You don't need to add icons one by one: the bar finds the icon of each app automatically,
the same way docks and app launchers do on GNOME / KDE.

### How it works

It's not a Wayland protocol, but two freedesktop standards working together:

1. **The app tells the compositor its id.** Every Wayland window sends an *app_id*
   (it's the `class` in `hyprctl clients`), e.g. `com.mitchellh.ghostty`.
2. **The app_id matches the `.desktop` file.** By convention the app_id is the name of the
   app's desktop file (`com.mitchellh.ghostty.desktop`), which contains `Icon=com.mitchellh.ghostty`.
   ([Desktop Entry spec](https://specifications.freedesktop.org/desktop-entry-spec/latest/))
3. **The icon theme finds the image.** The icon name is looked up in the icon themes
   (`/usr/share/icons/hicolor/...`, and for flatpaks `/var/lib/flatpak/exports/share/icons/...`).
   ([Icon Theme spec](https://specifications.freedesktop.org/icon-theme-spec/latest/))

The folders searched come from `$XDG_DATA_DIRS`, which already includes the flatpak folders.

In `Workspaces.qml` this is done by:

```qml
const entry = DesktopEntries.heuristicLookup(appId)   // find the .desktop file
Quickshell.iconPath(entry.icon, true)                 // find the icon in the theme
```

### Icon priority

For each app, `Workspaces.qml` tries in order:

1. a Nerd Font glyph from `glyphMap`
2. a custom svg in `icons/<app_id>.svg`
3. the app's own icon (desktop file + icon theme)
4. a generic window icon `󰖯`

So `glyphMap` and `icons/` are only overrides: use them when you want a different look,
or for an app that has no icon.

### When it fails

Some apps send an app_id that doesn't match their `.desktop` file name (often Electron or old
X11 apps). They show the generic window icon. To fix one:

```bash
hyprctl clients | grep -i class    # find the app_id
```

then either add it to `glyphMap` in `Workspaces.qml`, or drop an svg named `<app_id>.svg` in `icons/`.

To check if an app has an icon on the system:

```bash
grep '^Icon=' /usr/share/applications/<app_id>.desktop \
              /var/lib/flatpak/exports/share/applications/<app_id>.desktop 2>/dev/null
```

## Reloading

Quickshell doesn't always hot-reload after `chezmoi apply`. If a change doesn't show up:

```bash
pkill qs; qs & disown
```
