import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root

    property real  vol:          0
    property bool  muted:        false
    property bool  volDragging:  false
    property real  micVol:       0
    property bool  micMuted:     false
    property bool  micDragging:  false
    property var   sinkList:     []
    property var   sourceList:   []

    function refreshDevices() {
        root.sinkList   = []
        root.sourceList = []
        procSinkList.running   = true
        procSourceList.running = true
    }

    // ── Processes ──────────────────────────────────────────────────────────

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

    Process { id: procVolumeSet; running: false }

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

    Process { id: procMicSet; running: false }

    Process {
        id: procMicMute
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
        running: false
    }

    Process {
        id: procSinkList
        command: ["bash", "-c",
            "d=$(pactl get-default-sink 2>/dev/null); " +
            "pactl list sinks 2>/dev/null | awk -v def=\"$d\" '" +
            "/^Sink #/{if(id!=\"\")print id\"|\"act\"|\"name\"|\"nick; " +
            "id=substr($0,7); name=\"\"; nick=\"\"; act=\"0\"} " +
            "/^\\tName:/{name=$2; act=(name==def)?\"1\":\"0\"} " +
            "/node\\.nick/{match($0,/\"([^\"]+)\"/,a); nick=a[1]} " +
            "END{if(id!=\"\")print id\"|\"act\"|\"name\"|\"nick}'"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var p = data.trim().split("|")
                if (p.length < 4 || p[2] === "") return
                var entry = { id: p[0].trim(), active: p[1].trim() === "1",
                              name: p[2].trim(), displayName: p[3].trim() }
                if (entry.displayName === "") entry.displayName = entry.name
                var arr = root.sinkList.slice(); arr.push(entry); root.sinkList = arr
            }
        }
    }

    Process {
        id: procSourceList
        command: ["bash", "-c",
            "d=$(pactl get-default-source 2>/dev/null); " +
            "pactl list sources 2>/dev/null | awk -v def=\"$d\" '" +
            "/^Source #/{if(id!=\"\"&&!skip)print id\"|\"act\"|\"name\"|\"nick; " +
            "id=substr($0,9); name=\"\"; nick=\"\"; act=\"0\"; skip=0} " +
            "/^\\tName:/{name=$2; act=(name==def)?\"1\":\"0\"; skip=(name~/.monitor$/)?1:0} " +
            "/node\\.nick/{match($0,/\"([^\"]+)\"/,a); nick=a[1]} " +
            "END{if(id!=\"\"&&!skip)print id\"|\"act\"|\"name\"|\"nick}'"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var p = data.trim().split("|")
                if (p.length < 4 || p[2] === "") return
                var entry = { id: p[0].trim(), active: p[1].trim() === "1",
                              name: p[2].trim(), displayName: p[3].trim() }
                if (entry.displayName === "") entry.displayName = entry.name
                var arr = root.sourceList.slice(); arr.push(entry); root.sourceList = arr
            }
        }
    }

    Process { id: procSetDefaultSink;   running: false }
    Process { id: procSetDefaultSource; running: false }

    Component.onCompleted: refreshDevices()

    // ── UI ─────────────────────────────────────────────────────────────────

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
            spacing: 10

            // ════════════════════ SORTIE ════════════════════

            Text {
                text: "SORTIE"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            // Volume card — sortie
            // Column with padding drives the card height (avoids implicit-height binding loop)
            Rectangle {
                width: parent.width
                height: volOutPad.implicitHeight
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.04)

                Column {
                    id: volOutPad
                    x: 14; y: 0
                    width: parent.width - 28
                    topPadding: 14; bottomPadding: 14; spacing: 10

                    RowLayout {
                        width: parent.width; spacing: 10

                        Text {
                            text: {
                                if (root.muted || root.vol <= 0) return "󰝟"
                                if (root.vol < 0.34) return "󰕿"
                                if (root.vol < 0.67) return "󰖀"
                                return "󰕾"
                            }
                            color: root.muted ? Theme.danger : Theme.text
                            font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            text: "Volume sortie"
                            color: Theme.text; font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: root.muted ? "muet" : Math.round(root.vol * 100) + "%"
                            color: root.muted ? Theme.danger : Theme.textDim
                            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Rectangle {
                            width: 36; height: 18; radius: 9
                            color: root.muted ? Theme.danger : Theme.success
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Rectangle {
                                id: volToggleThumb
                                width: 14; height: 14; radius: 7; color: "white"
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.muted ? 2 : parent.width - width - 2
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { root.muted = !root.muted; procVolumeMute.running = true }
                            }
                        }
                    }

                    Item {
                        width: parent.width; height: 20
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width; height: 4; radius: 2
                            color: Qt.rgba(1, 1, 1, 0.10)
                            Rectangle {
                                width: parent.width * root.vol
                                height: parent.height; radius: parent.radius
                                color: root.muted ? Theme.danger : Theme.text
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                        Rectangle {
                            width: 12; height: 12; radius: 6
                            color: root.muted ? Theme.danger : "white"
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.vol * (parent.width - width)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.SizeHorCursor
                            function apply(mx) {
                                var v = Math.max(0.0, Math.min(1.0, mx / width))
                                root.muted = false; root.vol = v
                                procVolumeSet.command = ["wpctl", "set-volume",
                                    "@DEFAULT_AUDIO_SINK@", Math.round(v * 100) + "%"]
                                procVolumeSet.running = true
                            }
                            onPressed:        (e) => { root.volDragging = true; apply(e.x) }
                            onReleased:             root.volDragging = false
                            onPositionChanged: (e) => apply(e.x)
                        }
                    }
                }
            }

            // Device header + refresh button
            RowLayout {
                width: parent.width
                Text {
                    text: "PÉRIPHÉRIQUE DE SORTIE"
                    color: Theme.textDim; font.family: Theme.fontFamily
                    font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 82; height: 22; radius: 4
                    color: refreshArea.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                    Behavior on color { ColorAnimation { duration: 100 } }
                    RowLayout {
                        anchors.centerIn: parent; spacing: 4
                        Text {
                            text: (procSinkList.running || procSourceList.running) ? "…" : "↻"
                            color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 11
                        }
                        Text {
                            text: "Actualiser"
                            color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 9
                        }
                    }
                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onClicked: refreshDevices()
                    }
                }
            }

            // Sink list
            Column {
                width: parent.width; spacing: 3

                Text {
                    visible: root.sinkList.length === 0
                    width: parent.width
                    text: procSinkList.running ? "Chargement…" : "Aucun périphérique"
                    color: Theme.textDim; font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize; horizontalAlignment: Text.AlignHCenter
                }

                Repeater {
                    model: root.sinkList
                    delegate: Rectangle {
                        required property var modelData
                        property bool hovered: false

                        width: parent.width; height: 40; radius: 6
                        color: modelData.active ? Qt.rgba(0x4C/255, 0xAF/255, 0x50/255, 0.10)
                             : hovered           ? Qt.rgba(1, 1, 1, 0.07)
                             :                     Qt.rgba(1, 1, 1, 0.04)
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Rectangle {
                            visible: modelData.active
                            width: 3; height: 20; radius: 2; color: Theme.success
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 14; rightMargin: 12 }
                            spacing: 10
                            Text {
                                text: modelData.active ? "󰓃" : "󰓂"
                                color: modelData.active ? Theme.success : Theme.textDim
                                font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                            }
                            Text {
                                text: modelData.displayName; color: Theme.text
                                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                                font.weight: Theme.fontWeight; elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Rectangle {
                                visible: !modelData.active
                                property bool btnHovered: false
                                width: 60; height: 24; radius: 4
                                color: btnHovered ? Qt.rgba(0.3, 0.75, 0.3, 0.12) : Qt.rgba(1, 1, 1, 0.07)
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text {
                                    anchors.centerIn: parent; text: "Utiliser"
                                    color: parent.btnHovered ? Theme.success : Theme.textDim
                                    font.family: Theme.fontFamily; font.pixelSize: 10
                                    font.weight: Theme.fontWeight
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered:  parent.btnHovered = true
                                    onExited:   parent.btnHovered = false
                                    onClicked: {
                                        procSetDefaultSink.command = ["pactl", "set-default-sink", modelData.name]
                                        procSetDefaultSink.running = true
                                        for (var i = 0; i < root.sinkList.length; i++)
                                            root.sinkList[i].active = (root.sinkList[i].name === modelData.name)
                                        root.sinkList = root.sinkList.slice()
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
                            onEntered: parent.hovered = true
                            onExited:  parent.hovered = false
                        }
                    }
                }
            }

            // ── Séparateur ──
            Item { width: parent.width; height: 4 }
            Rectangle { width: parent.width; height: 1; color: Theme.separator }
            Item { width: parent.width; height: 4 }

            // ════════════════════ ENTRÉE ════════════════════

            Text {
                text: "ENTRÉE"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            // Volume card — entrée
            Rectangle {
                width: parent.width
                height: volInPad.implicitHeight
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.04)

                Column {
                    id: volInPad
                    x: 14; y: 0
                    width: parent.width - 28
                    topPadding: 14; bottomPadding: 14; spacing: 10

                    RowLayout {
                        width: parent.width; spacing: 10

                        Text {
                            text: root.micMuted ? "󰍭" : "󰍬"
                            color: root.micMuted ? Theme.danger : Theme.text
                            font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            text: "Volume micro"
                            color: Theme.text; font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: root.micMuted ? "muet" : Math.round(root.micVol * 100) + "%"
                            color: root.micMuted ? Theme.danger : Theme.textDim
                            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Rectangle {
                            width: 36; height: 18; radius: 9
                            color: root.micMuted ? Theme.danger : Theme.success
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Rectangle {
                                id: micToggleThumb
                                width: 14; height: 14; radius: 7; color: "white"
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.micMuted ? 2 : parent.width - width - 2
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { root.micMuted = !root.micMuted; procMicMute.running = true }
                            }
                        }
                    }

                    Item {
                        width: parent.width; height: 20
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width; height: 4; radius: 2
                            color: Qt.rgba(1, 1, 1, 0.10)
                            Rectangle {
                                width: parent.width * root.micVol
                                height: parent.height; radius: parent.radius
                                color: root.micMuted ? Theme.danger : Theme.text
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                        Rectangle {
                            width: 12; height: 12; radius: 6
                            color: root.micMuted ? Theme.danger : "white"
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.micVol * (parent.width - width)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.SizeHorCursor
                            function apply(mx) {
                                var v = Math.max(0.0, Math.min(1.0, mx / width))
                                root.micMuted = false; root.micVol = v
                                procMicSet.command = ["wpctl", "set-volume",
                                    "@DEFAULT_AUDIO_SOURCE@", Math.round(v * 100) + "%"]
                                procMicSet.running = true
                            }
                            onPressed:         (e) => { root.micDragging = true; apply(e.x) }
                            onReleased:              root.micDragging = false
                            onPositionChanged: (e) => apply(e.x)
                        }
                    }
                }
            }

            Text {
                text: "PÉRIPHÉRIQUE D'ENTRÉE"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            // Source list
            Column {
                width: parent.width; spacing: 3

                Text {
                    visible: root.sourceList.length === 0
                    width: parent.width
                    text: procSourceList.running ? "Chargement…" : "Aucun périphérique"
                    color: Theme.textDim; font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize; horizontalAlignment: Text.AlignHCenter
                }

                Repeater {
                    model: root.sourceList
                    delegate: Rectangle {
                        required property var modelData
                        property bool hovered: false

                        width: parent.width; height: 40; radius: 6
                        color: modelData.active ? Qt.rgba(0x4C/255, 0xAF/255, 0x50/255, 0.10)
                             : hovered           ? Qt.rgba(1, 1, 1, 0.07)
                             :                     Qt.rgba(1, 1, 1, 0.04)
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Rectangle {
                            visible: modelData.active
                            width: 3; height: 20; radius: 2; color: Theme.success
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 14; rightMargin: 12 }
                            spacing: 10
                            Text {
                                text: modelData.active ? "󰍬" : "󰍭"
                                color: modelData.active ? Theme.success : Theme.textDim
                                font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                            }
                            Text {
                                text: modelData.displayName; color: Theme.text
                                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                                font.weight: Theme.fontWeight; elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Rectangle {
                                visible: !modelData.active
                                property bool btnHovered: false
                                width: 60; height: 24; radius: 4
                                color: btnHovered ? Qt.rgba(0.3, 0.75, 0.3, 0.12) : Qt.rgba(1, 1, 1, 0.07)
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text {
                                    anchors.centerIn: parent; text: "Utiliser"
                                    color: parent.btnHovered ? Theme.success : Theme.textDim
                                    font.family: Theme.fontFamily; font.pixelSize: 10
                                    font.weight: Theme.fontWeight
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onEntered:  parent.btnHovered = true
                                    onExited:   parent.btnHovered = false
                                    onClicked: {
                                        procSetDefaultSource.command = ["pactl", "set-default-source", modelData.name]
                                        procSetDefaultSource.running = true
                                        for (var i = 0; i < root.sourceList.length; i++)
                                            root.sourceList[i].active = (root.sourceList[i].name === modelData.name)
                                        root.sourceList = root.sourceList.slice()
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
                            onEntered: parent.hovered = true
                            onExited:  parent.hovered = false
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
