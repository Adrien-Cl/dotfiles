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
                if (f !== "") root.wallpaperFiles = root.wallpaperFiles.concat([f])
            }
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
                if (t !== "") root.gtkThemes = root.gtkThemes.concat([t])
            }
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
                if (t !== "") root.iconThemes = root.iconThemes.concat([t])
            }
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
                if (t !== "") root.cursorThemes = root.cursorThemes.concat([t])
            }
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

    Component.onCompleted: {
        procListWallpapers.running = true
        procGetActive.running = true
        procListGtkThemes.running = true
        procListIconThemes.running = true
        procListCursorThemes.running = true
        procGetCurrentThemes.running = true
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: pageCol.implicitHeight + 32
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: pageCol
            x: 16; y: 16
            width: flick.width - 32
            spacing: 16

            // — Fond d'écran —
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
                width: parent.width
                spacing: 8

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
                            asynchronous: true
                            smooth: true
                        }

                        Rectangle {
                            visible: parent.isActive
                            anchors { right: parent.right; top: parent.top; margins: 4 }
                            width: 16; height: 16; radius: 8
                            color: "#4CAF50"
                            Text {
                                anchors.centerIn: parent; text: "✓"
                                color: "white"; font.pixelSize: 9; font.weight: Font.Bold
                                font.family: Theme.fontFamily
                            }
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onEntered: parent.wpHovered = true
                            onExited: parent.wpHovered = false
                            onClicked: root.applyWallpaper(parent.modelData)
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.separator }

            // — Thème GTK —
            Text {
                text: "THÈME GTK"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            Column {
                width: parent.width; spacing: 4
                Text {
                    visible: root.gtkThemes.length === 0
                    text: "Chargement…"; color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                }
                Repeater {
                    model: root.gtkThemes
                    delegate: Rectangle {
                        required property string modelData
                        property bool thHov: false
                        property bool isActive: modelData === root.currentGtkTheme
                        width: parent.width; height: 34; radius: 6
                        color: isActive ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.10) : thHov ? Qt.rgba(1,1,1,0.05) : Qt.rgba(1,1,1,0.03)
                        Behavior on color { ColorAnimation { duration: 80 } }
                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 8
                            Text { text: isActive ? "●" : "○"; color: isActive ? "#4CAF50" : Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 10 }
                            Text { text: modelData; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight; Layout.fillWidth: true }
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

            Rectangle { width: parent.width; height: 1; color: Theme.separator }

            // — Thème icônes —
            Text {
                text: "THÈME D'ICÔNES"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            Column {
                width: parent.width; spacing: 4
                Repeater {
                    model: root.iconThemes
                    delegate: Rectangle {
                        required property string modelData
                        property bool icHov: false
                        property bool isActive: modelData === root.currentIconTheme
                        width: parent.width; height: 34; radius: 6
                        color: isActive ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.10) : icHov ? Qt.rgba(1,1,1,0.05) : Qt.rgba(1,1,1,0.03)
                        Behavior on color { ColorAnimation { duration: 80 } }
                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 8
                            Text { text: isActive ? "●" : "○"; color: isActive ? "#4CAF50" : Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 10 }
                            Text { text: modelData; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight; Layout.fillWidth: true }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onEntered: parent.icHov = true; onExited: parent.icHov = false
                            onClicked: {
                                root.currentIconTheme = parent.modelData
                                procSetTheme.command = ["bash", "-c",
                                    "gsettings set org.gnome.desktop.interface icon-theme '" + parent.modelData + "' 2>/dev/null; " +
                                    "sed -i 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=" + parent.modelData + "/' ~/.config/gtk-3.0/settings.ini 2>/dev/null"]
                                procSetTheme.running = true
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.separator }

            // — Thème curseur —
            Text {
                text: "THÈME CURSEUR"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            Column {
                width: parent.width; spacing: 4
                Repeater {
                    model: root.cursorThemes
                    delegate: Rectangle {
                        required property string modelData
                        property bool cuHov: false
                        property bool isActive: modelData === root.currentCursorTheme
                        width: parent.width; height: 34; radius: 6
                        color: isActive ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.10) : cuHov ? Qt.rgba(1,1,1,0.05) : Qt.rgba(1,1,1,0.03)
                        Behavior on color { ColorAnimation { duration: 80 } }
                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 8
                            Text { text: isActive ? "●" : "○"; color: isActive ? "#4CAF50" : Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 10 }
                            Text { text: modelData; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight; Layout.fillWidth: true }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onEntered: parent.cuHov = true; onExited: parent.cuHov = false
                            onClicked: {
                                root.currentCursorTheme = parent.modelData
                                procSetTheme.command = ["bash", "-c",
                                    "gsettings set org.gnome.desktop.interface cursor-theme '" + parent.modelData + "' 2>/dev/null; " +
                                    "hyprctl setcursor '" + parent.modelData + "' 20 2>/dev/null"]
                                procSetTheme.running = true
                            }
                        }
                    }
                }
            }
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
