import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root

    readonly property string wallpaperDir: "/home/adrien/.config/hypr/wallpapers/"

    property var    wallpaperFiles: []
    property string currentWallpaper: ""
    property string pendingWallpaper: ""

    property var    gtkThemes:    []
    property var    iconThemes:   []
    property var    cursorThemes: []
    property string currentGtkTheme:    ""
    property string currentIconTheme:   ""
    property string currentCursorTheme: ""

    property string expandedIconTheme:   ""
    property string expandedCursorTheme: ""
    property var    cursorPreviewList:   []

    property string _wallBuf:   ""
    property string _gtkBuf:    ""
    property string _iconBuf:   ""
    property string _cursorBuf: ""

    property int currentTab: 0
    onCurrentTabChanged: flick.contentY = 0

    // — Inline component: one icon with 4-path fallback —
    component IconPreview: Item {
        required property string themeName
        required property string iconName
        required property string category   // "places", "mimetypes", "apps"
        width: 38; height: 38

        // path/48/<name>.svg  (candy-icons, breeze)
        Image {
            id: ip1; anchors.fill: parent
            source: "file:///usr/share/icons/" + themeName + "/" + category + "/48/" + iconName + ".svg"
            fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true
            visible: status === Image.Ready
        }
        // scalable/path/<name>.svg  (Fluent, Adwaita)
        Image {
            id: ip2; anchors.fill: parent
            source: ip1.status !== Image.Ready
                ? "file:///usr/share/icons/" + themeName + "/scalable/" + category + "/" + iconName + ".svg" : ""
            fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true
            visible: ip1.status !== Image.Ready && status === Image.Ready
        }
        // path/32/<name>.svg  (breeze mimetypes)
        Image {
            id: ip3; anchors.fill: parent
            source: (ip1.status !== Image.Ready && ip2.status !== Image.Ready)
                ? "file:///usr/share/icons/" + themeName + "/" + category + "/32/" + iconName + ".svg" : ""
            fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true
            visible: ip1.status !== Image.Ready && ip2.status !== Image.Ready && status === Image.Ready
        }
        // 48x48/path/<name>.png  (AdwaitaLegacy)
        Image {
            id: ip4; anchors.fill: parent
            source: (ip1.status !== Image.Ready && ip2.status !== Image.Ready && ip3.status !== Image.Ready)
                ? "file:///usr/share/icons/" + themeName + "/48x48/" + category + "/" + iconName + ".png" : ""
            fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true
            visible: ip1.status !== Image.Ready && ip2.status !== Image.Ready && ip3.status !== Image.Ready && status === Image.Ready
        }
        // Fallback glyph
        Text {
            anchors.centerIn: parent
            font.family: Theme.fontFamily; font.pixelSize: 22
            color: Theme.textDim; opacity: 0.4
            visible: ip1.status !== Image.Ready && ip2.status !== Image.Ready &&
                     ip3.status !== Image.Ready && ip4.status !== Image.Ready
            text: {
                if (iconName === "folder")                      return "󰉋"
                if (iconName === "user-trash")                  return "󰩺"
                if (iconName.startsWith("image"))               return "󰋩"
                if (iconName.startsWith("audio"))               return "󰎆"
                if (iconName.startsWith("video"))               return "󰈫"
                if (iconName === "application-x-executable")   return "󰘔"
                if (iconName === "preferences-system")          return "󰒓"
                return "󰈔"
            }
        }
    }

    // — Wallpaper processes —
    Process {
        id: procListWallpapers
        command: ["bash", "-c",
            "ls -1 " + root.wallpaperDir + " 2>/dev/null | grep -iE '\\.(png|jpg|jpeg|webp)$'"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var f = data.trim()
                if (f !== "") root._wallBuf += (root._wallBuf ? "\n" : "") + f
            }
        }
        onRunningChanged: {
            if (!running && root._wallBuf !== "") { root.wallpaperFiles = root._wallBuf.split("\n"); root._wallBuf = "" }
        }
    }

    Process {
        id: procGetActive
        command: ["bash", "-c", "hyprctl hyprpaper listactive 2>/dev/null | awk -F'= ' '{print $2}' | head -1 | xargs"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => { var f = data.trim(); if (f !== "") root.currentWallpaper = f }
        }
    }

    Process {
        id: procPreload
        running: false
        onRunningChanged: {
            if (!running && root.pendingWallpaper !== "") {
                procSetWallpaper.command = ["hyprctl", "hyprpaper", "wallpaper",
                    "," + root.pendingWallpaper]
                procSetWallpaper.running = true
            }
        }
    }

    Process {
        id: procSetWallpaper
        running: false
        onRunningChanged: {
            if (!running) {
                var old = root.currentWallpaper
                root.currentWallpaper = root.pendingWallpaper
                if (old !== "" && old !== root.pendingWallpaper) {
                    procUnload.command = ["hyprctl", "hyprpaper", "unload", old]
                    procUnload.running = true
                }
            }
        }
    }

    Process { id: procUnload; running: false }

    function applyWallpaper(filename) {
        var fullPath = root.wallpaperDir + filename
        root.pendingWallpaper = fullPath
        procPreload.command = ["hyprctl", "hyprpaper", "preload", fullPath]
        procPreload.running = true
    }

    // — Theme processes —
    Process {
        id: procListGtkThemes
        command: ["bash", "-c",
            "for d in /usr/share/themes ~/.local/share/themes ~/.themes; do " +
            "  [ -d \"$d\" ] && ls -1 \"$d\" 2>/dev/null; " +
            "done | sort -u | grep -v '^$'"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var t = data.trim()
                if (t !== "") root._gtkBuf += (root._gtkBuf ? "\n" : "") + t
            }
        }
        onRunningChanged: {
            if (!running && root._gtkBuf !== "") { root.gtkThemes = root._gtkBuf.split("\n"); root._gtkBuf = "" }
        }
    }

    Process {
        id: procListIconThemes
        command: ["bash", "-c",
            "for d in /usr/share/icons ~/.local/share/icons ~/.icons; do " +
            "  [ -d \"$d\" ] && ls -1 \"$d\" 2>/dev/null; " +
            "done | sort -u | grep -v '^$\\|^default$'"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var t = data.trim()
                if (t !== "") root._iconBuf += (root._iconBuf ? "\n" : "") + t
            }
        }
        onRunningChanged: {
            if (!running && root._iconBuf !== "") { root.iconThemes = root._iconBuf.split("\n"); root._iconBuf = "" }
        }
    }

    Process {
        id: procListCursorThemes
        command: ["bash", "-c",
            "for d in /usr/share/icons ~/.local/share/icons ~/.icons; do " +
            "  [ -d \"$d\" ] && ls -1 \"$d\" 2>/dev/null | while read t; do " +
            "    [ -d \"$d/$t/cursors\" ] && echo \"$t\"; " +
            "  done; " +
            "done | sort -u"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var t = data.trim()
                if (t !== "") root._cursorBuf += (root._cursorBuf ? "\n" : "") + t
            }
        }
        onRunningChanged: {
            if (!running && root._cursorBuf !== "") { root.cursorThemes = root._cursorBuf.split("\n"); root._cursorBuf = "" }
        }
    }

    Process {
        id: procGetCurrentThemes
        command: ["bash", "-c",
            "echo \"GTK:$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d \"'\")\"; " +
            "echo \"ICON:$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d \"'\")\"; " +
            "echo \"CURSOR:$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d \"'\")\";"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.startsWith("GTK:"))    root.currentGtkTheme    = data.slice(4).trim()
                if (data.startsWith("ICON:"))   root.currentIconTheme   = data.slice(5).trim()
                if (data.startsWith("CURSOR:")) root.currentCursorTheme = data.slice(7).trim()
            }
        }
    }

    Process {
        id: procSetTheme
        running: false
    }

    // Lists cursor filenames for the currently expanded cursor theme
    Process {
        id: procListCursors
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var f = data.trim()
                if (f !== "") root.cursorPreviewList = root.cursorPreviewList.concat([f])
            }
        }
    }

    Component.onCompleted: {
        procListWallpapers.running = true
        procGetActive.running = true
        procListGtkThemes.running = true
        procListIconThemes.running = true
        procListCursorThemes.running = true
        procGetCurrentThemes.running = true
    }

    function gtkThemeBg(name) {
        var n = name.toLowerCase()
        if (n.includes("dark"))        return "#1e1e2e"
        if (n.includes("gruvbox"))     return "#282828"
        if (n.includes("nord"))        return "#2e3440"
        if (n.includes("dracula"))     return "#282a36"
        if (n.includes("arc"))         return "#2f343f"
        if (n.includes("materia"))     return "#263238"
        if (n.includes("breeze"))      return "#1b1e24"
        if (n.includes("adwaita"))     return "#242424"
        return "#2a2a2a"
    }

    function gtkThemeAccent(name) {
        var n = name.toLowerCase()
        if (n.includes("catppuccin") || n.includes("mocha")) return "#cba6f7"
        if (n.includes("nord"))        return "#88c0d0"
        if (n.includes("gruvbox"))     return "#fabd2f"
        if (n.includes("arc"))         return "#5294e2"
        if (n.includes("breeze"))      return "#3daee9"
        if (n.includes("materia"))     return "#00bcd4"
        if (n.includes("dracula"))     return "#bd93f9"
        if (n.includes("adwaita"))     return "#3584e4"
        return "#7aa2f7"
    }

    Row {
        id: tabBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 36
        spacing: 0

        Repeater {
            model: ["Bar", "Fond d'écran", "GTK", "Icônes", "Curseurs"]
            delegate: Rectangle {
                required property string modelData
                required property int    index
                property bool active: root.currentTab === index
                property bool hov:    false

                width: tabBar.width / 5; height: 36
                color: active ? Qt.rgba(Theme.aiIcon.r, Theme.aiIcon.g, Theme.aiIcon.b, 0.12)
                             : hov ? Qt.rgba(1,1,1,0.05) : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }

                Rectangle {
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: 2; radius: 1
                    color: parent.active ? Theme.aiIcon : Theme.separator
                    Behavior on color { ColorAnimation { duration: 80 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: parent.modelData
                    color: parent.active ? Theme.aiIcon : Theme.textDim
                    font.family: Theme.fontFamily; font.pixelSize: 11
                    font.weight: parent.active ? Font.DemiBold : Font.Normal
                    Behavior on color { ColorAnimation { duration: 80 } }
                }

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                    onEntered: parent.hov = true; onExited: parent.hov = false
                    onClicked: root.currentTab = parent.index
                }
            }
        }
    }

    Flickable {
        id: flick
        anchors { top: tabBar.bottom; bottom: parent.bottom; left: parent.left; right: parent.right }
        contentHeight: pageCol.implicitHeight + 32
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: pageCol
            x: 16; y: 16
            width: flick.width - 32
            spacing: 16

            Column { visible: root.currentTab === 0; width: parent.width; spacing: 16

            // ═══════════════════════════════════════════
            // THÈME DU BAR
            // ═══════════════════════════════════════════
            Text {
                text: "THÈME DU BAR"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            Flow {
                width: parent.width
                spacing: 8

                Repeater {
                    model: Theme.presets

                    delegate: Rectangle {
                        required property var modelData
                        property bool presetHovered: false
                        property bool isActive: Theme.currentPreset === modelData.name

                        property color pBg:     Qt.color(modelData.bg)
                        property color pText:   Qt.color(modelData.text)
                        property color pAccent: Qt.color(modelData.accent)
                        property color pDanger: Qt.color(modelData.danger)

                        width: 108; height: 68; radius: 8
                        color: pBg
                        border.color: isActive ? pAccent : presetHovered ? Qt.rgba(1,1,1,0.35) : Qt.rgba(1,1,1,0.10)
                        border.width: isActive ? 2 : 1
                        clip: true
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        Rectangle {
                            visible: parent.isActive
                            anchors { top: parent.top; right: parent.right; margins: 5 }
                            width: 14; height: 14; radius: 7
                            color: parent.pAccent
                            Text {
                                anchors.centerIn: parent; text: "✓"
                                color: parent.parent.pBg
                                font.pixelSize: 8; font.weight: Font.Bold; font.family: Theme.fontFamily
                            }
                        }

                        Column {
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                            spacing: 5

                            Rectangle {
                                width: parent.width; height: 6; radius: 2
                                color: Qt.rgba(parent.parent.pText.r, parent.parent.pText.g, parent.parent.pText.b, 0.12)
                            }

                            Row {
                                spacing: 4
                                Rectangle { width: 10; height: 10; radius: 5; color: parent.parent.parent.pAccent }
                                Rectangle { width: 10; height: 10; radius: 5; color: parent.parent.parent.pDanger }
                                Rectangle { width: 10; height: 10; radius: 5; color: parent.parent.parent.pText }
                            }
                        }

                        Text {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 7 }
                            text: parent.modelData.name
                            color: parent.pText
                            font.family: Theme.fontFamily; font.pixelSize: 9; font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onEntered: parent.presetHovered = true
                            onExited:  parent.presetHovered = false
                            onClicked: Theme.applyPreset(parent.modelData.name)
                        }
                    }
                }
            }

            } // Tab 0: Bar

            Column { visible: root.currentTab === 1; width: parent.width; spacing: 16

            // ═══════════════════════════════════════════
            // FOND D'ÉCRAN
            // ═══════════════════════════════════════════
            Text {
                text: "FOND D'ÉCRAN"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            Text {
                visible: root.wallpaperFiles.length === 0
                text: "Aucun fond d'écran dans ~/.config/hypr/wallpapers/"
                color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
            }

            Flow {
                width: parent.width; spacing: 8

                Repeater {
                    model: root.wallpaperFiles

                    delegate: Rectangle {
                        required property string modelData
                        required property int    index
                        property string fullPath: root.wallpaperDir + modelData
                        property bool   isActive: fullPath === root.currentWallpaper
                        property bool   wpHovered: false
                        width: 128; height: 72; radius: 6; clip: true
                        border.color: isActive ? Theme.text : wpHovered ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.4) : "transparent"
                        border.width: isActive ? 2 : 1

                        Image {
                            anchors.fill: parent
                            source: "file://" + parent.fullPath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true; smooth: true
                            sourceSize.width: 128; sourceSize.height: 72
                        }

                        Rectangle {
                            visible: parent.isActive
                            anchors { right: parent.right; top: parent.top; margins: 4 }
                            width: 16; height: 16; radius: 8; color: "#4CAF50"
                            Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 9; font.weight: Font.Bold; font.family: Theme.fontFamily }
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onEntered: parent.wpHovered = true; onExited: parent.wpHovered = false
                            onClicked: root.applyWallpaper(parent.modelData)
                        }
                    }
                }
            }

            } // Tab 1: Fond d'écran

            Column { visible: root.currentTab === 2; width: parent.width; spacing: 16

            // ═══════════════════════════════════════════
            // THÈME GTK
            // ═══════════════════════════════════════════
            Text {
                text: "THÈME GTK"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            Text {
                visible: root.gtkThemes.length === 0
                text: "Chargement…"; color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
            }

            Flow {
                width: parent.width; spacing: 8

                Repeater {
                    model: root.gtkThemes

                    delegate: Rectangle {
                        required property string modelData
                        property bool thHov: false
                        property bool isActive: modelData === root.currentGtkTheme
                        property color cardBg:     Qt.color(root.gtkThemeBg(modelData))
                        property color cardAccent: Qt.color(root.gtkThemeAccent(modelData))

                        width: 110; height: 72; radius: 8
                        color: cardBg
                        border.color: isActive ? cardAccent : thHov ? Qt.rgba(1,1,1,0.25) : Qt.rgba(1,1,1,0.08)
                        border.width: isActive ? 2 : 1
                        clip: true
                        Behavior on border.color { ColorAnimation { duration: 80 } }

                        Rectangle {
                            visible: parent.isActive
                            anchors { top: parent.top; right: parent.right; margins: 5 }
                            width: 14; height: 14; radius: 7; color: parent.cardAccent
                            Text { anchors.centerIn: parent; text: "✓"; color: parent.parent.cardBg; font.pixelSize: 8; font.weight: Font.Bold; font.family: Theme.fontFamily }
                        }

                        Column {
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                            spacing: 4
                            Rectangle {
                                width: parent.width; height: 8; radius: 2
                                color: Qt.rgba(parent.parent.cardAccent.r, parent.parent.cardAccent.g, parent.parent.cardAccent.b, 0.3)
                            }
                            Rectangle { width: parent.width * 0.7; height: 3; radius: 1; color: Qt.rgba(1,1,1,0.15) }
                            Rectangle { width: parent.width * 0.5; height: 3; radius: 1; color: Qt.rgba(1,1,1,0.10) }
                            Rectangle { width: 16; height: 6; radius: 2; color: parent.parent.cardAccent; opacity: 0.8 }
                        }

                        Text {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 7 }
                            text: parent.modelData; color: "#cccccc"
                            font.family: Theme.fontFamily; font.pixelSize: 9; font.weight: Font.DemiBold; elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onEntered: parent.thHov = true; onExited: parent.thHov = false
                            onClicked: {
                                root.currentGtkTheme = parent.modelData
                                procSetTheme.command = ["bash", "-c",
                                    "gsettings set org.gnome.desktop.interface gtk-theme '" + parent.modelData + "' 2>/dev/null; " +
                                    "sed -i 's/^gtk-theme-name=.*/gtk-theme-name=" + parent.modelData + "/' ~/.config/gtk-3.0/settings.ini 2>/dev/null; " +
                                    "sed -i 's/^gtk-theme-name=.*/gtk-theme-name=" + parent.modelData + "/' ~/.config/gtk-4.0/settings.ini 2>/dev/null"]
                                procSetTheme.running = true
                            }
                        }
                    }
                }
            }

            } // Tab 2: GTK

            Column { visible: root.currentTab === 3; width: parent.width; spacing: 16

            // ═══════════════════════════════════════════
            // THÈME D'ICÔNES
            // ═══════════════════════════════════════════
            Text {
                text: "THÈME D'ICÔNES"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            Column {
                width: parent.width
                spacing: 3

                Repeater {
                    model: root.iconThemes

                    // Delegate is a Column containing header row + expandable preview
                    delegate: Column {
                        id: iconRow
                        required property string modelData
                        width: parent.width
                        spacing: 0

                        property bool isActive:   modelData === root.currentIconTheme
                        property bool isExpanded: root.expandedIconTheme === modelData
                        property bool rowHovered: false

                        // — Header row —
                        Rectangle {
                            width: parent.width; height: 40
                            radius: iconRow.isExpanded ? 0 : 6
                            color: iconRow.isActive
                                ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.10)
                                : iconRow.rowHovered ? Qt.rgba(1,1,1,0.05) : Qt.rgba(1,1,1,0.03)
                            Behavior on color { ColorAnimation { duration: 80 } }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 12 }
                                spacing: 10

                                // Small folder preview
                                Item {
                                    width: 26; height: 26
                                    Image {
                                        id: hdrPng; anchors.fill: parent
                                        source: root.currentTab === 3
                                            ? "file:///usr/share/icons/" + iconRow.modelData + "/48x48/places/folder.png" : ""
                                        fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true
                                        visible: status === Image.Ready
                                    }
                                    Image {
                                        id: hdrSvg1; anchors.fill: parent
                                        source: root.currentTab === 3 && hdrPng.status !== Image.Ready
                                            ? "file:///usr/share/icons/" + iconRow.modelData + "/places/48/folder.svg" : ""
                                        fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true
                                        visible: hdrPng.status !== Image.Ready && status === Image.Ready
                                    }
                                    Image {
                                        anchors.fill: parent
                                        source: root.currentTab === 3 && hdrPng.status !== Image.Ready && hdrSvg1.status !== Image.Ready
                                            ? "file:///usr/share/icons/" + iconRow.modelData + "/scalable/places/folder.svg" : ""
                                        fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true
                                        visible: hdrPng.status !== Image.Ready && hdrSvg1.status !== Image.Ready && status === Image.Ready
                                    }
                                    Text {
                                        anchors.centerIn: parent; text: "󰉋"
                                        color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 18
                                        visible: hdrPng.status !== Image.Ready && hdrSvg1.status !== Image.Ready
                                    }
                                }

                                Text {
                                    text: iconRow.modelData
                                    color: iconRow.isActive ? Theme.text : Theme.textDim
                                    font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                                    font.weight: iconRow.isActive ? Font.DemiBold : Font.Normal
                                    Layout.fillWidth: true; elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                }

                                // Active indicator
                                Text {
                                    visible: iconRow.isActive
                                    text: "●"; color: Theme.aiIcon
                                    font.family: Theme.fontFamily; font.pixelSize: 10
                                }

                                // Expand/collapse chevron
                                Text {
                                    text: iconRow.isExpanded ? "󰅃" : "󰅄"
                                    color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 14
                                    Behavior on text {}
                                }
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onEntered: iconRow.rowHovered = true
                                onExited:  iconRow.rowHovered = false
                                onClicked: {
                                    root.expandedIconTheme = iconRow.isExpanded ? "" : iconRow.modelData
                                }
                            }
                        }

                        // — Expanded preview panel —
                        Rectangle {
                            width: parent.width
                            height: iconRow.isExpanded ? (iconExpandContent.implicitHeight + 20) : 0
                            visible: height > 0
                            clip: true
                            radius: 6
                            color: Qt.rgba(1, 1, 1, 0.02)
                            border.color: Theme.separator
                            border.width: 1
                            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                            Column {
                                id: iconExpandContent
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                                spacing: 10

                                // Icon grid — 7 representative icons
                                Flow {
                                    width: parent.width; spacing: 10

                                    Repeater {
                                        model: iconRow.isExpanded ? [
                                            { n: "folder",                    c: "places",   l: "Dossier"   },
                                            { n: "user-trash",                c: "places",   l: "Corbeille" },
                                            { n: "text-x-generic",            c: "mimetypes",l: "Fichier"   },
                                            { n: "image-x-generic",           c: "mimetypes",l: "Image"     },
                                            { n: "audio-x-generic",           c: "mimetypes",l: "Audio"     },
                                            { n: "video-x-generic",           c: "mimetypes",l: "Vidéo"     },
                                            { n: "application-x-executable",  c: "apps",     l: "App"       },
                                            { n: "preferences-system",        c: "apps",     l: "Config"    }
                                        ] : []

                                        delegate: Column {
                                            required property var modelData
                                            spacing: 4; width: 52

                                            IconPreview {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                themeName: iconRow.modelData
                                                iconName:  parent.modelData.n
                                                category:  parent.modelData.c
                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: parent.modelData.l
                                                color: Theme.textDim; font.family: Theme.fontFamily
                                                font.pixelSize: 9
                                            }
                                        }
                                    }
                                }

                                // Valider button (hidden if already active)
                                Item {
                                    width: parent.width
                                    height: iconRow.isActive ? 0 : 28
                                    visible: height > 0

                                    Rectangle {
                                        anchors.right: parent.right
                                        width: 90; height: 26; radius: 5
                                        property bool btnHov: false
                                        color: btnHov
                                            ? Qt.rgba(Theme.aiIcon.r, Theme.aiIcon.g, Theme.aiIcon.b, 0.20)
                                            : Qt.rgba(Theme.aiIcon.r, Theme.aiIcon.g, Theme.aiIcon.b, 0.10)
                                        border.color: Theme.aiIcon; border.width: 1
                                        Behavior on color { ColorAnimation { duration: 80 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰄬  Valider"
                                            color: Theme.aiIcon; font.family: Theme.fontFamily
                                            font.pixelSize: 11; font.weight: Font.DemiBold
                                        }

                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                            onEntered: parent.btnHov = true; onExited: parent.btnHov = false
                                            onClicked: {
                                                root.currentIconTheme = iconRow.modelData
                                                root.expandedIconTheme = ""
                                                procSetTheme.command = ["bash", "-c",
                                                    "gsettings set org.gnome.desktop.interface icon-theme '" + iconRow.modelData + "' 2>/dev/null; " +
                                                    "sed -i 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=" + iconRow.modelData + "/' ~/.config/gtk-3.0/settings.ini 2>/dev/null"]
                                                procSetTheme.running = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            } // Tab 3: Icônes

            Column { visible: root.currentTab === 4; width: parent.width; spacing: 16

            // ═══════════════════════════════════════════
            // THÈME CURSEUR
            // ═══════════════════════════════════════════
            Text {
                text: "THÈME CURSEUR"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            Column {
                width: parent.width
                spacing: 3

                Repeater {
                    model: root.cursorThemes

                    delegate: Column {
                        id: cursorRow
                        required property string modelData
                        width: parent.width
                        spacing: 0

                        property bool isActive:   modelData === root.currentCursorTheme
                        property bool isExpanded: root.expandedCursorTheme === modelData
                        property bool rowHovered: false

                        // — Header row —
                        Rectangle {
                            width: parent.width; height: 34
                            radius: cursorRow.isExpanded ? 0 : 6
                            color: cursorRow.isActive
                                ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.10)
                                : cursorRow.rowHovered ? Qt.rgba(1,1,1,0.05) : Qt.rgba(1,1,1,0.03)
                            Behavior on color { ColorAnimation { duration: 80 } }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 8

                                Text {
                                    text: cursorRow.isActive ? "●" : "○"
                                    color: cursorRow.isActive ? Theme.aiIcon : Theme.textDim
                                    font.family: Theme.fontFamily; font.pixelSize: 10
                                }
                                Text {
                                    text: cursorRow.modelData
                                    color: cursorRow.isActive ? Theme.text : Theme.textDim
                                    font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                                    font.weight: cursorRow.isActive ? Font.DemiBold : Font.Normal
                                    Layout.fillWidth: true; elide: Text.ElideRight
                                }
                                Text {
                                    text: cursorRow.isExpanded ? "󰅃" : "󰅄"
                                    color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 14
                                }
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onEntered: cursorRow.rowHovered = true
                                onExited:  cursorRow.rowHovered = false
                                onClicked: {
                                    if (cursorRow.isExpanded) {
                                        root.expandedCursorTheme = ""
                                    } else {
                                        root.expandedCursorTheme = cursorRow.modelData
                                        root.cursorPreviewList = []
                                        procListCursors.command = ["bash", "-c",
                                            "for d in /usr/share/icons ~/.local/share/icons ~/.icons; do " +
                                            "  if [ -d \"$d/" + cursorRow.modelData + "/cursors\" ]; then " +
                                            "    ls \"$d/" + cursorRow.modelData + "/cursors\" | grep -v '\\.' | sort | head -30; break; " +
                                            "  fi; " +
                                            "done"]
                                        procListCursors.running = true
                                    }
                                }
                            }
                        }

                        // — Expanded cursor names panel —
                        Rectangle {
                            width: parent.width
                            height: cursorRow.isExpanded ? (cursorExpandContent.implicitHeight + 20) : 0
                            visible: height > 0
                            clip: true
                            radius: 6
                            color: Qt.rgba(1, 1, 1, 0.02)
                            border.color: Theme.separator
                            border.width: 1
                            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                            Column {
                                id: cursorExpandContent
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                                spacing: 10

                                // Cursor names as chips
                                Text {
                                    visible: root.expandedCursorTheme === cursorRow.modelData && root.cursorPreviewList.length === 0
                                    text: "Chargement…"
                                    color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 11
                                }

                                Flow {
                                    width: parent.width; spacing: 5
                                    visible: root.expandedCursorTheme === cursorRow.modelData && root.cursorPreviewList.length > 0

                                    Repeater {
                                        model: root.expandedCursorTheme === cursorRow.modelData ? root.cursorPreviewList : []

                                        delegate: Rectangle {
                                            required property string modelData
                                            height: 20; radius: 3
                                            color: Qt.rgba(1, 1, 1, 0.06)
                                            width: cursorNameText.implicitWidth + 14

                                            Text {
                                                id: cursorNameText
                                                anchors.centerIn: parent
                                                text: parent.modelData
                                                color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 10
                                            }
                                        }
                                    }
                                }

                                // Valider button
                                Item {
                                    width: parent.width
                                    height: cursorRow.isActive ? 0 : 28
                                    visible: height > 0

                                    Rectangle {
                                        anchors.right: parent.right
                                        width: 90; height: 26; radius: 5
                                        property bool btnHov: false
                                        color: btnHov
                                            ? Qt.rgba(Theme.aiIcon.r, Theme.aiIcon.g, Theme.aiIcon.b, 0.20)
                                            : Qt.rgba(Theme.aiIcon.r, Theme.aiIcon.g, Theme.aiIcon.b, 0.10)
                                        border.color: Theme.aiIcon; border.width: 1
                                        Behavior on color { ColorAnimation { duration: 80 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰄬  Valider"
                                            color: Theme.aiIcon; font.family: Theme.fontFamily
                                            font.pixelSize: 11; font.weight: Font.DemiBold
                                        }

                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                            onEntered: parent.btnHov = true; onExited: parent.btnHov = false
                                            onClicked: {
                                                root.currentCursorTheme = cursorRow.modelData
                                                root.expandedCursorTheme = ""
                                                procSetTheme.command = ["bash", "-c",
                                                    "gsettings set org.gnome.desktop.interface cursor-theme '" + cursorRow.modelData + "' 2>/dev/null; " +
                                                    "hyprctl setcursor '" + cursorRow.modelData + "' 20 2>/dev/null"]
                                                procSetTheme.running = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            } // Tab 4: Curseurs
        }
    }

    Rectangle {
        visible: flick.contentHeight > flick.height
        anchors { right: parent.right; rightMargin: 2 }
        width: 3; radius: 2; color: Qt.rgba(1, 1, 1, 0.15)
        y: flick.visibleArea.yPosition * flick.height
        height: Math.max(20, flick.visibleArea.heightRatio * flick.height)
    }
}
