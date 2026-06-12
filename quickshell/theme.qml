pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: themeRoot

    property color bg:          "#01010F"
    property color bgOpaque:    Qt.rgba(bg.r, bg.g, bg.b, 0.9)
    property color bgSolid:     Qt.rgba(bg.r, bg.g, bg.b, 1.0)
    property color bgBlur:      Qt.rgba(bg.r, bg.g, bg.b, 0.75)
    property color text:        "#C8D1E9"
    property color textDim:     Qt.rgba(text.r, text.g, text.b, 0.5)
    property color aiIcon:      "#DDAC26"
    property color danger:      "#F96565"
    property color separator:   Qt.rgba(text.r, text.g, text.b, 0.25)

    readonly property int barHeight:     32
    readonly property int marginTop:     8
    readonly property int marginSide:    8
    readonly property int fontSize:      12
    readonly property int iconSize:      16
    readonly property int spacing:       12

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontWeight:    Font.DemiBold

    property string currentPreset: "Midnight"

    readonly property var presets: [
        { name: "Midnight",        bg: "#01010F", text: "#C8D1E9", accent: "#DDAC26", danger: "#F96565" },
        { name: "Catppuccin Mocha",bg: "#1E1E2E", text: "#CDD6F4", accent: "#CBA6F7", danger: "#F38BA8" },
        { name: "Nord",            bg: "#2E3440", text: "#ECEFF4", accent: "#88C0D0", danger: "#BF616A" },
        { name: "Gruvbox",         bg: "#282828", text: "#EBDBB2", accent: "#FABD2F", danger: "#FB4934" },
        { name: "Tokyo Night",     bg: "#1A1B26", text: "#C0CAF5", accent: "#7AA2F7", danger: "#F7768E" },
        { name: "Rosé Pine",       bg: "#191724", text: "#E0DEF4", accent: "#EBBCBA", danger: "#EB6F92" },
        { name: "Dracula",         bg: "#282A36", text: "#F8F8F2", accent: "#BD93F9", danger: "#FF5555" }
    ]

    function applyPreset(presetName) {
        for (var i = 0; i < presets.length; i++) {
            var p = presets[i]
            if (p.name === presetName) {
                themeRoot.bg     = p.bg
                themeRoot.text   = p.text
                themeRoot.aiIcon = p.accent
                themeRoot.danger = p.danger
                themeRoot.currentPreset = presetName
                procSavePreset.command = ["bash", "-c",
                    "echo '" + presetName + "' > ~/.config/quickshell/.current_preset"]
                procSavePreset.running = true
                return
            }
        }
    }

    Process {
        id: procSavePreset
        running: false
    }

    Process {
        id: procLoadPreset
        command: ["bash", "-c", "cat ~/.config/quickshell/.current_preset 2>/dev/null || echo ''"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var name = data.trim()
                if (name !== "" && name !== themeRoot.currentPreset) {
                    themeRoot.applyPreset(name)
                }
            }
        }
    }
}
