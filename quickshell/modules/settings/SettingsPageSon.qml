import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root

    // === Volume sortie ===
    property real   vol:        0
    property bool   muted:      false
    property bool   volDragging: false

    // === Volume entrée ===
    property real   micVol:     0
    property bool   micMuted:   false
    property bool   micDragging: false

    // === Sinks / Sources ===
    property var sinkList:   []
    property var sourceList: []

    Process {
        id: procVolumeGet
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: !root.volDragging
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var isMuted = data.indexOf("[MUTED]") >= 0
                var m = data.match(/Volume:\s+([0-9.]+)/)
                if (!m) return
                var v = parseFloat(m[1])
                if (!isNaN(v)) { root.vol = Math.min(1.0, v); root.muted = isMuted }
            }
        }
    }

    Process {
        id: procVolumeSet
        running: false
    }

    Process {
        id: procVolumeMute
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        running: false
    }

    Process {
        id: procMicGet
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var isMuted = data.indexOf("[MUTED]") >= 0
                var m = data.match(/Volume:\s+([0-9.]+)/)
                if (!m) return
                var v = parseFloat(m[1])
                if (!isNaN(v)) { root.micVol = Math.min(1.0, v); root.micMuted = isMuted }
            }
        }
    }

    Process {
        id: procMicSet
        running: false
    }

    Process {
        id: procMicMute
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
        running: false
    }

    Process {
        id: procSinkList
        command: ["bash", "-c",
            "wpctl status | awk '/Audio/,0' | awk '/Sinks:/,/Sources:/' | grep -E '^\\s+[*]?\\s*[0-9]+\\.' | " +
            "while IFS= read -r l; do " +
            "  active=$(echo \"$l\" | grep -c '[*]'); " +
            "  id=$(echo \"$l\" | grep -oE '[0-9]+' | head -1); " +
            "  name=$(echo \"$l\" | sed 's/.*[0-9]\\. //; s/ \\[.*//; s/^\\s*//'); " +
            "  echo \"${id}|${active}|${name}\"; " +
            "done"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var p = data.trim().split("|")
                if (p.length < 3 || p[0] === "") return
                var entry = { id: p[0].trim(), active: p[1].trim() === "1", name: p[2].trim() }
                if (entry.name === "") return
                var arr = root.sinkList.slice()
                arr.push(entry)
                root.sinkList = arr
            }
        }
        onRunningChanged: if (!running && root.sinkList.length === 0) { root.sinkList = [] }
    }

    Process {
        id: procSourceList
        command: ["bash", "-c",
            "wpctl status | awk '/Sources:/,/Filters:/' | grep -E '^\\s+[*]?\\s*[0-9]+\\.' | " +
            "while IFS= read -r l; do " +
            "  active=$(echo \"$l\" | grep -c '[*]'); " +
            "  id=$(echo \"$l\" | grep -oE '[0-9]+' | head -1); " +
            "  name=$(echo \"$l\" | sed 's/.*[0-9]\\. //; s/ \\[.*//; s/^\\s*//'); " +
            "  echo \"${id}|${active}|${name}\"; " +
            "done"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var p = data.trim().split("|")
                if (p.length < 3 || p[0] === "") return
                var entry = { id: p[0].trim(), active: p[1].trim() === "1", name: p[2].trim() }
                if (entry.name === "") return
                var arr = root.sourceList.slice()
                arr.push(entry)
                root.sourceList = arr
            }
        }
    }

    Process {
        id: procSetDefault
        running: false
    }

    Component.onCompleted: {
        procSinkList.running = true
        procSourceList.running = true
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
            spacing: 14

            // — Volume sortie —
            RowLayout {
                width: parent.width; spacing: 8
                Text {
                    text: { if (root.muted || root.vol <= 0) return "󰝟"; if (root.vol < 0.34) return "󰕿"; if (root.vol < 0.67) return "󰖀"; return "󰕾" }
                    color: root.muted ? Theme.danger : Theme.text
                    font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                }
                Text {
                    text: "Volume sortie"
                    color: Theme.text; font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight
                    Layout.fillWidth: true
                }
                Text {
                    text: root.muted ? "muet" : Math.round(root.vol * 100) + "%"
                    color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                }
            }

            RowLayout {
                width: parent.width; spacing: 8
                Text {
                    text: root.muted ? "󰝟" : "󰕾"
                    color: root.muted ? Theme.danger : Theme.textDim
                    font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.muted = !root.muted; procVolumeMute.running = true }
                    }
                }
                Item {
                    Layout.fillWidth: true; height: 20
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 4; radius: 2; color: Theme.textDim
                        Rectangle {
                            width: parent.width * root.vol; height: parent.height; radius: parent.radius
                            color: root.muted ? Theme.danger : Theme.text
                        }
                    }
                    Rectangle {
                        width: 12; height: 12; radius: 6
                        color: root.muted ? Theme.danger : "white"
                        anchors.verticalCenter: parent.verticalCenter
                        x: root.vol * (parent.width - width)
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.SizeHorCursor
                        function apply(mx) {
                            var v = Math.max(0.0, Math.min(1.0, mx / width))
                            root.muted = false; root.vol = v
                            procVolumeSet.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(v * 100) + "%"]
                            procVolumeSet.running = true
                        }
                        onPressed: (e) => { root.volDragging = true; apply(e.x) }
                        onReleased: root.volDragging = false
                        onPositionChanged: (e) => apply(e.x)
                    }
                }
            }

            // — Sélecteur sortie audio —
            Text {
                text: "PÉRIPHÉRIQUE DE SORTIE"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            Column {
                width: parent.width; spacing: 4
                Text {
                    visible: root.sinkList.length === 0
                    width: parent.width; text: "Chargement…"
                    color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                    horizontalAlignment: Text.AlignHCenter
                }
                Repeater {
                    model: root.sinkList
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width; height: 36; radius: 6
                        color: modelData.active ? Qt.rgba(0x4C/255, 0xAF/255, 0x50/255, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 8
                            Text {
                                text: modelData.active ? "󰓃" : "󰓂"
                                color: modelData.active ? "#4CAF50" : Theme.textDim
                                font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                            }
                            Text {
                                text: modelData.name; color: Theme.text
                                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                                font.weight: Theme.fontWeight; elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Rectangle {
                                visible: !modelData.active
                                width: 60; height: 22; radius: 4; color: Qt.rgba(1, 1, 1, 0.07)
                                Text {
                                    anchors.centerIn: parent; text: "Utiliser"
                                    color: Theme.textDim; font.family: Theme.fontFamily
                                    font.pixelSize: 10; font.weight: Theme.fontWeight
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        procSetDefault.command = ["wpctl", "set-default", modelData.id]
                                        procSetDefault.running = true
                                        for (var i = 0; i < root.sinkList.length; i++) {
                                            root.sinkList[i].active = (root.sinkList[i].id === modelData.id)
                                        }
                                        root.sinkList = root.sinkList.slice()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.separator }

            // — Volume micro —
            RowLayout {
                width: parent.width; spacing: 8
                Text {
                    text: root.micMuted ? "󰍭" : "󰍬"
                    color: root.micMuted ? Theme.danger : Theme.text
                    font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                }
                Text {
                    text: "Volume micro"
                    color: Theme.text; font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight; Layout.fillWidth: true
                }
                Text {
                    text: root.micMuted ? "muet" : Math.round(root.micVol * 100) + "%"
                    color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                }
            }

            RowLayout {
                width: parent.width; spacing: 8
                Text {
                    text: root.micMuted ? "󰍭" : "󰍬"
                    color: root.micMuted ? Theme.danger : Theme.textDim
                    font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.micMuted = !root.micMuted; procMicMute.running = true }
                    }
                }
                Item {
                    Layout.fillWidth: true; height: 20
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 4; radius: 2; color: Theme.textDim
                        Rectangle {
                            width: parent.width * root.micVol; height: parent.height; radius: parent.radius
                            color: root.micMuted ? Theme.danger : Theme.text
                        }
                    }
                    Rectangle {
                        width: 12; height: 12; radius: 6
                        color: root.micMuted ? Theme.danger : "white"
                        anchors.verticalCenter: parent.verticalCenter
                        x: root.micVol * (parent.width - width)
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.SizeHorCursor
                        function apply(mx) {
                            var v = Math.max(0.0, Math.min(1.0, mx / width))
                            root.micMuted = false; root.micVol = v
                            procMicSet.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", Math.round(v * 100) + "%"]
                            procMicSet.running = true
                        }
                        onPressed: (e) => { root.micDragging = true; apply(e.x) }
                        onReleased: root.micDragging = false
                        onPositionChanged: (e) => apply(e.x)
                    }
                }
            }

            // — Sélecteur source audio —
            Text {
                text: "PÉRIPHÉRIQUE D'ENTRÉE"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            Column {
                width: parent.width; spacing: 4
                Text {
                    visible: root.sourceList.length === 0
                    width: parent.width; text: "Chargement…"
                    color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                    horizontalAlignment: Text.AlignHCenter
                }
                Repeater {
                    model: root.sourceList
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width; height: 36; radius: 6
                        color: modelData.active ? Qt.rgba(0x4C/255, 0xAF/255, 0x50/255, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 8
                            Text {
                                text: modelData.active ? "󰍬" : "󰍭"
                                color: modelData.active ? "#4CAF50" : Theme.textDim
                                font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                            }
                            Text {
                                text: modelData.name; color: Theme.text
                                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                                font.weight: Theme.fontWeight; elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            Rectangle {
                                visible: !modelData.active
                                width: 60; height: 22; radius: 4; color: Qt.rgba(1, 1, 1, 0.07)
                                Text {
                                    anchors.centerIn: parent; text: "Utiliser"
                                    color: Theme.textDim; font.family: Theme.fontFamily
                                    font.pixelSize: 10; font.weight: Theme.fontWeight
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        procSetDefault.command = ["wpctl", "set-default", modelData.id]
                                        procSetDefault.running = true
                                        for (var i = 0; i < root.sourceList.length; i++) {
                                            root.sourceList[i].active = (root.sourceList[i].id === modelData.id)
                                        }
                                        root.sourceList = root.sourceList.slice()
                                    }
                                }
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
