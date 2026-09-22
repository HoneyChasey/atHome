// Entry point of configuration
import QtQuick
import Quickshell
ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar { }
    }
}
