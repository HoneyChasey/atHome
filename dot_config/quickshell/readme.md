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

### No custom icons

The bar only uses the system icons: there is no `icons/` folder or glyph list to maintain.
If an app has no icon, it shows a generic window icon `󰖯`.

### When it fails

Some apps send an app_id that doesn't match their `.desktop` file name (often Electron or old
X11 apps). They show the generic window icon.

Find the app_id:

```bash
hyprctl clients | grep -i class
```

Check if the app has a desktop file and an icon on the system:

```bash
grep '^Icon=' /usr/share/applications/<app_id>.desktop \
              /var/lib/flatpak/exports/share/applications/<app_id>.desktop 2>/dev/null
```

To fix it the standard way (no bar change), create `~/.local/share/applications/<app_id>.desktop`
pointing to an existing icon name:

```ini
[Desktop Entry]
Type=Application
Name=My App
Exec=myapp
Icon=myapp
NoDisplay=true
```

## Control center

The `󰔡` icon at the right of the bar (or `SUPER + N`) opens a macOS-like control center:
Wi-Fi, Bluetooth, Do Not Disturb (swaync), dark / light mode, screenshot, lock, brightness,
volume and the media playing. Clicking the Wi-Fi / Bluetooth text opens `nmtui` / `bluetui`.

### Dark / light mode

The switch (or `SUPER + SHIFT + T`, or `qs ipc call theme toggle`) sets
`org.gnome.desktop.interface color-scheme` and `gtk-theme` with `gsettings`:

- the bar and the control center change colors (`Theme.qml`)
- GTK / libadwaita apps follow, and the xdg portal tells browsers, electron apps and flatpaks
- ghostty switches with `theme = light:...,dark:...`

## Reloading

Quickshell doesn't always hot-reload after `chezmoi apply`. If a change doesn't show up:

```bash
pkill qs; qs & disown
```
