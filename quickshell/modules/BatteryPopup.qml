import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../"

PopupWindow {
    id: root

    required property PanelWindow bar

    signal closeRequested()

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
            procReadEpp.running = true
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

    implicitWidth:  280
    implicitHeight: panelCol.implicitHeight + 24

    anchor.rect.x: bar.width - implicitWidth
    anchor.rect.y: Theme.barHeight + Theme.marginTop + 8

    // ── État batterie ────────────────────────────────────────────────────────
    property int    batteryPct:    0
    property bool   isCharging:    false
    property string batteryState:  ""
    property real   energyRate:    0
    property string timeRemaining: ""

    // ── État EPP ─────────────────────────────────────────────────────────────
    property string currentEpp: ""
    property bool   eppBusy:    false

    // ── Processus ────────────────────────────────────────────────────────────

    Process {
        id: procBattery
        command: ["bash", "-c",
            "bat=$(upower -e 2>/dev/null | grep BAT | head -1); " +
            "[ -n \"$bat\" ] && upower -i \"$bat\" | grep -E 'state:|percentage:|time to|energy-rate:' || " +
            "echo 'percentage: 0%\nstate: unknown'"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var m
                if ((m = data.match(/percentage:\s+(\d+)/)))
                    root.batteryPct = parseInt(m[1])
                if ((m = data.match(/state:\s+(.+)/))) {
                    root.batteryState = m[1].trim()
                    root.isCharging   = m[1].indexOf("charging") >= 0 && m[1].indexOf("discharging") < 0
                }
                if ((m = data.match(/energy-rate:\s+([0-9.]+)/)))
                    root.energyRate = parseFloat(m[1])
                if ((m = data.match(/time to (?:full|empty):\s+(.+)/)))
                    root.timeRemaining = m[1].trim()
            }
        }
    }

    Timer {
        interval: 30000; repeat: true; running: root.visible; triggeredOnStart: true
        onTriggered: { if (!procBattery.running) procBattery.running = true }
    }

    Process {
        id: procReadEpp
        command: ["bash", "-c",
            "cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo ''"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var v = data.trim()
                if (v !== "") root.currentEpp = v
            }
        }
    }

    Process {
        id: procSetEpp
        running: false
        onRunningChanged: {
            if (!running) {
                root.eppBusy = false
                procReadEpp.running = true
            }
        }
    }

    function setEpp(mode) {
        if (root.eppBusy) return
        root.eppBusy    = true
        root.currentEpp = mode
        procSetEpp.command = ["sudo", "/usr/local/bin/set-cpu-epp", mode]
        procSetEpp.running = true
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    function batteryIcon(level, chg) {
        if (chg) {
            if (level < 20)  return "󰢜"
            if (level < 40)  return "󰂇"
            if (level < 60)  return "󰂈"
            if (level < 80)  return "󰂉"
            if (level < 100) return "󰂋"
            return "󰂅"
        }
        if (level < 10)  return "󰁺"
        if (level < 20)  return "󰁻"
        if (level < 30)  return "󰁼"
        if (level < 50)  return "󰁾"
        if (level < 70)  return "󰁿"
        if (level < 90)  return "󰂁"
        return "󰁹"
    }

    function batteryColor(level) {
        if (level <= 15) return Theme.danger
        if (level <= 30) return Theme.warning
        return Theme.success
    }

    // ── UI ───────────────────────────────────────────────────────────────────

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
                top:         parent.top
                left:        parent.left
                right:       parent.right
                topMargin:   12
                leftMargin:  16
                rightMargin: 16
            }
            spacing: 14

            // — Header —
            Text {
                text:           "Batterie & énergie"
                color:          Theme.textDim
                font.family:    Theme.fontFamily
                font.pixelSize: 10
                font.weight:    Font.Bold
                opacity:        0.7
            }

            // — Carte batterie —
            Rectangle {
                width:  parent.width
                height: batteryCardCol.implicitHeight + 24
                radius: 8
                color:  Qt.rgba(1, 1, 1, 0.04)

                Column {
                    id: batteryCardCol
                    anchors {
                        left:           parent.left
                        right:          parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin:     14
                        rightMargin:    14
                    }
                    spacing: 8

                    RowLayout {
                        width:   parent.width
                        spacing: 12

                        Text {
                            text:             root.batteryIcon(root.batteryPct, root.isCharging)
                            color:            root.batteryColor(root.batteryPct)
                            font.family:      Theme.fontFamily
                            font.pixelSize:   26
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 3

                            RowLayout {
                                width:   parent.width
                                spacing: 8

                                Text {
                                    text:           root.batteryPct + "%"
                                    color:          root.batteryColor(root.batteryPct)
                                    font.family:    Theme.fontFamily
                                    font.pixelSize: 18
                                    font.weight:    Font.Bold
                                }
                                Text {
                                    text: {
                                        if (root.isCharging)                        return "En charge"
                                        if (root.batteryState === "discharging")    return "Décharge"
                                        if (root.batteryState === "fully-charged")  return "Chargé"
                                        return root.batteryState
                                    }
                                    color:            Theme.textDim
                                    font.family:      Theme.fontFamily
                                    font.pixelSize:   Theme.fontSize
                                    Layout.fillWidth: true
                                }
                                Text {
                                    visible:        root.energyRate > 0
                                    text:           root.energyRate.toFixed(1) + " W"
                                    color:          Theme.textDim
                                    font.family:    Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                }
                            }

                            Rectangle {
                                width:  parent.width
                                height: 5
                                radius: 2
                                color:  Qt.rgba(1, 1, 1, 0.1)

                                Rectangle {
                                    width:  parent.width * (root.batteryPct / 100)
                                    height: parent.height
                                    radius: parent.radius
                                    color:  root.batteryColor(root.batteryPct)
                                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                }
                            }
                        }
                    }

                    Text {
                        visible:        root.timeRemaining !== ""
                        text:           root.isCharging
                                        ? "Plein dans " + root.timeRemaining
                                        : root.timeRemaining + " restant"
                        color:          Theme.textDim
                        font.family:    Theme.fontFamily
                        font.pixelSize: 10
                        opacity:        0.8
                    }
                }
            }

            // — Séparateur —
            Rectangle { width: parent.width; height: 1; color: Theme.separator }

            // — Section Mode CPU —
            Column {
                width:   parent.width
                spacing: 8

                Text {
                    text:           "MODE CPU"
                    color:          Theme.textDim
                    font.family:    Theme.fontFamily
                    font.pixelSize: 9
                    font.weight:    Font.Bold
                    opacity:        0.7
                }

                Row {
                    width:   parent.width
                    spacing: 8

                    Repeater {
                        model: [
                            { epp: "power",               icon: "󰁹", label: "Eco"        },
                            { epp: "balance_power",       icon: "󰾅", label: "Équil.-"    },
                            { epp: "balance_performance", icon: "󱐋", label: "Équil.+"    },
                            { epp: "performance",         icon: "󱐌", label: "Perf"       }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            property bool isActive: root.currentEpp === modelData.epp
                            property bool hov:      false

                            width:  (parent.width - 24) / 4
                            height: 58
                            radius: 6
                            color:  isActive
                                    ? Qt.rgba(0xDD/255, 0xAC/255, 0x26/255, 0.18)
                                    : hov ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.04)
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Rectangle {
                                visible:      parent.isActive
                                anchors.fill: parent
                                radius:       parent.radius
                                color:        "transparent"
                                border.color: Theme.aiIcon
                                border.width: 1
                                opacity:      0.6
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text:           modelData.icon
                                    color:          parent.parent.isActive ? Theme.aiIcon : Theme.text
                                    font.family:    Theme.fontFamily
                                    font.pixelSize: Theme.iconSize
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text:           modelData.label
                                    color:          parent.parent.isActive ? Theme.text : Theme.textDim
                                    font.family:    Theme.fontFamily
                                    font.pixelSize: 9
                                    font.weight:    Font.DemiBold
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                            }

                            Rectangle {
                                visible:      root.eppBusy && !parent.isActive
                                anchors.fill: parent
                                radius:       parent.radius
                                color:        Qt.rgba(0, 0, 0, 0.35)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape:  root.eppBusy ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered:    parent.hov = true
                                onExited:     parent.hov = false
                                onClicked:    if (!root.eppBusy) root.setEpp(modelData.epp)
                            }
                        }
                    }
                }

                Text {
                    text: {
                        switch (root.currentEpp) {
                            case "power":               return "Économies max — fréquences réduites"
                            case "balance_power":       return "Quotidien — équilibre batterie/perf"
                            case "balance_performance": return "Modéré — bonnes performances"
                            case "performance":         return "Perf max — batterie en retrait"
                            default: return root.currentEpp !== "" ? root.currentEpp : "Lecture en cours…"
                        }
                    }
                    color:          Theme.textDim
                    font.family:    Theme.fontFamily
                    font.pixelSize: 10
                    opacity:        0.7
                    width:          parent.width
                    wrapMode:       Text.WordWrap
                }
            }

            Item { width: 1; height: 2 }
        }
    }
}
