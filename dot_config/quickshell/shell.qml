//@ pragma NativeTextRendering
//@ pragma IconTheme Adwaita
// Entry point of configuration
import QtQuick
import Quickshell
ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar { }
    }
    Variants {
        model: Quickshell.screens
        Dock { }  // macOS-like dock, auto-hidden at the bottom
    }
    Osd { }   // volume / brightness popup
}
