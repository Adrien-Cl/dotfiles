import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../"

PopupWindow {
    id: root

    required property PanelWindow bar

    signal closeRequested()
    signal btSettingsRequested()

    anchor.window: bar
    visible: false
    color:   "transparent"

    property bool shown: false

    onShownChanged: {
        if (shown) {
            animOut.stop()
            contentRect.opacity = 0
            slideTranslate.y = -10
            root.visible = true
            animIn.start()
        } else if (root.visible) {
            animIn.stop()
            animOut.start()
        }
    }

    ParallelAnimation {
        id: animIn
        NumberAnimation { target: contentRect; property: "opacity"; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: slideTranslate; property: "y"; to: 0; duration: 200; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: animOut
        NumberAnimation { target: contentRect; property: "opacity"; to: 0; duration: 140; easing.type: Easing.InCubic }
        NumberAnimation { target: slideTranslate; property: "y"; to: -10; duration: 140; easing.type: Easing.InCubic }
        onFinished: root.visible = false
    }

    implicitWidth:  260
    implicitHeight: panelCol.implicitHeight + 24

    anchor.rect.x: bar.width - implicitWidth
    anchor.rect.y: Theme.barHeight + Theme.marginTop + 8

    property real brightnessMax: 255
    property real brightnessCurrent: 0

    property real cpuUsage:    0
    property int  cpuPrevBusy:  0
    property int  cpuPrevTotal: 0
    property bool cpuFirstRead: true

    property real ramUsedGb:  0
    property real ramTotalGb: 0

    property string diskUsed:  ""
    property string diskTotal: ""
    property int    diskPct:   0

    property real tempC: 0

    Process {
        id: procBrightnessMax
        command: ["brightnessctl", "m"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var v = parseInt(data.trim())
                if (!isNaN(v) && v > 0) root.brightnessMax = v
            }
        }
    }

    Process {
        id: procBrightnessGet
        command: ["brightnessctl", "g"]
        running: root.visible
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var v = parseInt(data.trim())
                if (!isNaN(v)) root.brightnessCurrent = v
            }
        }
    }

    Process {
        id: procBrightnessSet
        running: false
    }

    Process {
        id: procCpu
        command: ["bash", "-c", "head -1 /proc/stat"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var p = data.trim().split(/\s+/)
                var busy  = (parseInt(p[1])||0)+(parseInt(p[2])||0)+(parseInt(p[3])||0)+(parseInt(p[6])||0)+(parseInt(p[7])||0)+(parseInt(p[8])||0)
                var total = busy + (parseInt(p[4])||0) + (parseInt(p[5])||0)
                if (root.cpuFirstRead) {
                    root.cpuFirstRead = false
                } else {
                    var db = busy - root.cpuPrevBusy, dt = total - root.cpuPrevTotal
                    if (dt > 0) root.cpuUsage = Math.round(db / dt * 100)
                }
                root.cpuPrevBusy = busy; root.cpuPrevTotal = total
            }
        }
    }
    Timer { interval: 2000; running: root.visible; repeat: true; onTriggered: procCpu.running = true }

    Process {
        id: procRam
        command: ["bash", "-c", "grep -E 'MemTotal|MemAvailable' /proc/meminfo"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var m = data.match(/^(MemTotal|MemAvailable):\s+(\d+)/)
                if (!m) return
                var gb = parseInt(m[2]) / 1024 / 1024
                if (m[1] === "MemTotal") root.ramTotalGb = Math.round(gb * 10) / 10
                else root.ramUsedGb = Math.round((root.ramTotalGb - gb) * 10) / 10
            }
        }
    }
    Timer { interval: 3000; running: root.visible; repeat: true; onTriggered: procRam.running = true }

    Process {
        id: procDisk
        command: ["bash", "-c", "df -h / | awk 'NR==2{print $3, $2, $5}'"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var p = data.trim().split(/\s+/)
                if (p.length < 3) return
                root.diskUsed  = p[0]
                root.diskTotal = p[1]
                root.diskPct   = parseInt(p[2]) || 0
            }
        }
    }
    Timer { interval: 30000; running: root.visible; repeat: true; onTriggered: procDisk.running = true }

    Process {
        id: procTemp
        command: ["bash", "-c", "sort -n /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | tail -1"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var raw = parseInt(data.trim())
                root.tempC = isNaN(raw) ? 0 : Math.round(raw / 1000)
            }
        }
    }
    Timer { interval: 5000; running: root.visible; repeat: true; onTriggered: procTemp.running = true }

    Rectangle {
        id:           contentRect
        anchors.fill: parent
        color:        Theme.bgSolid
        radius:       8
        opacity:      0
        transform:    Translate { id: slideTranslate; y: 0 }

        Column {
            id: panelCol
            anchors {
                top:        parent.top
                left:       parent.left
                right:      parent.right
                topMargin:  12
                leftMargin: 16
                rightMargin: 16
            }
            spacing: 14

            // — WiFi —
            RowLayout {
                width:   parent.width
                spacing: 8

                Text {
                    text:           "󰤨"
                    color:          Networking.wifiEnabled ? Theme.text : Theme.textDim
                    font.family:    Theme.fontFamily
                    font.pixelSize: Theme.iconSize
                }
                Text {
                    text:             "WiFi"
                    color:            Theme.text
                    font.family:      Theme.fontFamily
                    font.pixelSize:   Theme.fontSize
                    font.weight:      Theme.fontWeight
                    Layout.fillWidth: true
                }
                Rectangle {
                    width:  36
                    height: 18
                    radius: 9
                    color:  Networking.wifiEnabled ? "#4CAF50" : Theme.textDim

                    Rectangle {
                        width:  14
                        height: 14
                        radius: 7
                        color:  "white"
                        anchors.verticalCenter: parent.verticalCenter
                        x: Networking.wifiEnabled ? parent.width - width - 2 : 2
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }
            }

            // — Bluetooth —
            RowLayout {
                width:   parent.width
                spacing: 8

                // Zone cliquable icône + label → ouvre BluetoothPanel
                Item {
                    Layout.fillWidth: true
                    height:           btLeftRow.implicitHeight

                    RowLayout {
                        id:       btLeftRow
                        anchors.fill: parent
                        spacing:  8

                        Text {
                            text:           "󰂯"
                            color:          Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? Theme.text : Theme.textDim
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.iconSize
                        }
                        Text {
                            text:             "Bluetooth"
                            color:            Theme.text
                            font.family:      Theme.fontFamily
                            font.pixelSize:   Theme.fontSize
                            font.weight:      Theme.fontWeight
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.btSettingsRequested()
                    }
                }

                Rectangle {
                    id:     btToggle
                    width:  36
                    height: 18
                    radius: 9
                    color:  Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "#4CAF50" : Theme.textDim

                    Rectangle {
                        width:  14
                        height: 14
                        radius: 7
                        color:  "white"
                        anchors.verticalCenter: parent.verticalCenter
                        x: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? parent.width - width - 2 : 2
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            if (Bluetooth.defaultAdapter)
                                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                        }
                    }
                }
            }

            // — Séparateur —
            Rectangle {
                width:  parent.width
                height: 1
                color:  Theme.separator
            }

            // — Volume —
            Column {
                id:      volSection
                width:   parent.width
                spacing: 8

                property real vol:        0
                property bool muted:      false
                property real volPre:     0.5
                property bool isDragging: false

                Process {
                    id: procVolumeGet
                    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
                    running: root.visible && !volSection.isDragging
                    stdout: SplitParser {
                        splitMarker: "\n"
                        onRead: data => {
                            var isMuted = data.indexOf("[MUTED]") >= 0
                            var m = data.match(/Volume:\s+([0-9.]+)/)
                            if (!m) return
                            var v = parseFloat(m[1])
                            if (!isNaN(v)) {
                                volSection.vol   = Math.min(1.0, v)
                                volSection.muted = isMuted
                            }
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

                // Label row
                RowLayout {
                    width:   parent.width
                    spacing: 8

                    Text {
                        text: {
                            if (volSection.muted || volSection.vol <= 0) return "󰝟"
                            if (volSection.vol < 0.34) return "󰕿"
                            if (volSection.vol < 0.67) return "󰖀"
                            return "󰕾"
                        }
                        color:          volSection.muted ? Theme.danger : Theme.text
                        font.family:    Theme.fontFamily
                        font.pixelSize: Theme.iconSize
                    }
                    Text {
                        text:             "Volume"
                        color:            Theme.text
                        font.family:      Theme.fontFamily
                        font.pixelSize:   Theme.fontSize
                        font.weight:      Theme.fontWeight
                        Layout.fillWidth: true
                    }
                    Text {
                        text:           volSection.muted ? "muet" : Math.round(volSection.vol * 100) + "%"
                        color:          Theme.textDim
                        font.family:    Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight:    Theme.fontWeight
                    }
                }

                // Slider row — bouton mute + track
                RowLayout {
                    width:   parent.width
                    spacing: 8

                    Text {
                        text:           volSection.muted ? "󰝟" : "󰕾"
                        color:          volSection.muted ? Theme.danger : Theme.textDim
                        font.family:    Theme.fontFamily
                        font.pixelSize: Theme.iconSize

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                volSection.muted = !volSection.muted
                                procVolumeMute.running = true
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        height: 20

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width:  parent.width
                            height: 4
                            radius: 2
                            color:  Theme.textDim

                            Rectangle {
                                width:  parent.width * volSection.vol
                                height: parent.height
                                radius: parent.radius
                                color:  volSection.muted ? Theme.danger : Theme.text
                            }
                        }

                        Rectangle {
                            width:  12
                            height: 12
                            radius: 6
                            color:  volSection.muted ? Theme.danger : "white"
                            anchors.verticalCenter: parent.verticalCenter
                            x: volSection.vol * (parent.width - width)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.SizeHorCursor

                            function apply(mx) {
                                var v = Math.max(0.0, Math.min(1.0, mx / width))
                                volSection.muted = false
                                volSection.vol   = v
                                procVolumeSet.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(v * 100) + "%"]
                                procVolumeSet.running = true
                            }

                            onPressed:         (mouse) => { volSection.isDragging = true; apply(mouse.x) }
                            onReleased:        (mouse) => volSection.isDragging = false
                            onPositionChanged: (mouse) => apply(mouse.x)
                        }
                    }
                }
            }

            // — Luminosité —
            Column {
                id:      brightSection
                width:   parent.width
                spacing: 8

                property real bright: root.brightnessMax > 0
                                      ? root.brightnessCurrent / root.brightnessMax : 0

                // Label row
                RowLayout {
                    width:   parent.width
                    spacing: 8

                    Text {
                        text: {
                            var b = brightSection.bright
                            if (b < 0.34) return "󰃞"
                            if (b < 0.67) return "󰃝"
                            return "󰃠"
                        }
                        color:          Theme.text
                        font.family:    Theme.fontFamily
                        font.pixelSize: Theme.iconSize
                    }
                    Text {
                        text:             "Luminosité"
                        color:            Theme.text
                        font.family:      Theme.fontFamily
                        font.pixelSize:   Theme.fontSize
                        font.weight:      Theme.fontWeight
                        Layout.fillWidth: true
                    }
                    Text {
                        text:           Math.round(brightSection.bright * 100) + "%"
                        color:          Theme.textDim
                        font.family:    Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight:    Theme.fontWeight
                    }
                }

                // Slider row
                Item {
                    width:  parent.width
                    height: 20

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width:  parent.width
                        height: 4
                        radius: 2
                        color:  Theme.textDim

                        Rectangle {
                            width:  parent.width * brightSection.bright
                            height: parent.height
                            radius: parent.radius
                            color:  Theme.text
                        }
                    }

                    Rectangle {
                        width:  12
                        height: 12
                        radius: 6
                        color:  "white"
                        anchors.verticalCenter: parent.verticalCenter
                        x: brightSection.bright * (parent.width - width)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.SizeHorCursor

                        function apply(mx) {
                            var v = Math.max(0.0, Math.min(1.0, mx / width))
                            root.brightnessCurrent = Math.round(v * root.brightnessMax)
                            procBrightnessSet.command = ["brightnessctl", "s", Math.round(v * 100) + "%"]
                            procBrightnessSet.running = true
                        }

                        onPressed:         (mouse) => apply(mouse.x)
                        onPositionChanged: (mouse) => apply(mouse.x)
                    }
                }
            }

            // — Séparateur système —
            Rectangle {
                width:  parent.width
                height: 1
                color:  Theme.separator
            }

            // — Système (4 mini cartes) —
            Row {
                width:   parent.width
                spacing: 8

                Rectangle {
                    width:  (parent.width - 24) / 4
                    height: 58
                    radius: 8
                    color:  Qt.rgba(1, 1, 1, 0.05)

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:           String.fromCodePoint(0xF4BC)
                            color:          Theme.text
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.iconSize
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:           root.cpuUsage + "%"
                            color:          Theme.textDim
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight:    Theme.fontWeight
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:           "CPU"
                            color:          Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.3)
                            font.family:    Theme.fontFamily
                            font.pixelSize: 9
                            font.weight:    Theme.fontWeight
                        }
                    }
                }

                Rectangle {
                    width:  (parent.width - 24) / 4
                    height: 58
                    radius: 8
                    color:  Qt.rgba(1, 1, 1, 0.05)

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:           String.fromCodePoint(0xF061A)
                            color:          Theme.text
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.iconSize
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:           root.ramTotalGb > 0 ? Math.round(root.ramUsedGb / root.ramTotalGb * 100) + "%" : "—"
                            color:          Theme.textDim
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight:    Theme.fontWeight
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:           "RAM"
                            color:          Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.3)
                            font.family:    Theme.fontFamily
                            font.pixelSize: 9
                            font.weight:    Theme.fontWeight
                        }
                    }
                }

                Rectangle {
                    width:  (parent.width - 24) / 4
                    height: 58
                    radius: 8
                    color:  Qt.rgba(1, 1, 1, 0.05)

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:           "󰋊"
                            color:          Theme.text
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.iconSize
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:           root.diskPct + "%"
                            color:          Theme.textDim
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight:    Theme.fontWeight
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:           "DISQUE"
                            color:          Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.3)
                            font.family:    Theme.fontFamily
                            font.pixelSize: 9
                            font.weight:    Theme.fontWeight
                        }
                    }
                }

                Rectangle {
                    width:  (parent.width - 24) / 4
                    height: 58
                    radius: 8
                    color:  Qt.rgba(1, 1, 1, 0.05)

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:           "󰔄"
                            color:          root.tempC >= 80 ? Theme.danger : root.tempC >= 60 ? "#FFA500" : "#4CAF50"
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.iconSize
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:           root.tempC + "°C"
                            color:          root.tempC >= 80 ? Theme.danger : root.tempC >= 60 ? "#FFA500" : "#4CAF50"
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight:    Theme.fontWeight
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:           "TEMP"
                            color:          Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.3)
                            font.family:    Theme.fontFamily
                            font.pixelSize: 9
                            font.weight:    Theme.fontWeight
                        }
                    }
                }
            }
        }
    }
}
