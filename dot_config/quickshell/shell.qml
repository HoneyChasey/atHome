//@ pragma NativeTextRendering
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
        Dock { }  // macOS-like dock at the bottom
    }
    Osd { }   // volume / brightness popup
}
