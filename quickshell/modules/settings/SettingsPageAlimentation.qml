import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root

    property int    batteryPct:      0
    property string batteryState:    ""
    property real   energyRate:      0
    property string timeRemaining:   ""
    property bool   isCharging:      false
    property string currentMode:     ""
    property bool   eppBusy:         false

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
                if ((m = data.match(/percentage:\s+(\d+)/)))     root.batteryPct = parseInt(m[1])
                if ((m = data.match(/state:\s+(.+)/)))            { root.batteryState = m[1].trim(); root.isCharging = m[1].indexOf("charging") >= 0 && m[1].indexOf("discharging") < 0 }
                if ((m = data.match(/energy-rate:\s+([0-9.]+)/))) root.energyRate = parseFloat(m[1])
                if ((m = data.match(/time to (?:full|empty):\s+(.+)/))) root.timeRemaining = m[1].trim()
            }
        }
        onRunningChanged: { }
    }

    Timer {
        interval: 30000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: { if (!procBattery.running) procBattery.running = true }
    }

    Process {
        id: procReadEpp
        command: ["bash", "-c", "cat /tmp/qs-cpu-mode 2>/dev/null || echo 'reset'"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var v = data.trim()
                if (v !== "") root.currentMode = v
            }
        }
    }

    Process {
        id: procSetEpp
        running: false
        onRunningChanged: {
            if (!running) {
                root.eppBusy = false
            }
        }
    }

    Process {
        id: procWriteMode
        running: false
    }

    Component.onCompleted: procReadEpp.running = true

    function setEpp(mode) {
        if (root.eppBusy) return
        root.eppBusy     = true
        root.currentMode = mode
        procWriteMode.command = ["bash", "-c", "echo '" + mode + "' > /tmp/qs-cpu-mode"]
        procWriteMode.running = true
        procSetEpp.command = ["sudo", "/usr/local/bin/set-acf-mode", mode]
        procSetEpp.running = true
    }

    function batteryIcon(level, chg) {
        if (chg) return "󰂈"
        if (level < 10) return "󰁺"
        if (level < 20) return "󰁻"
        if (level < 30) return "󰁼"
        if (level < 50) return "󰁾"
        if (level < 70) return "󰁿"
        if (level < 90) return "󰂁"
        return "󰁹"
    }

    function batteryColor(level) {
        if (level <= 15) return Theme.danger
        if (level <= 30) return Theme.warning
        return Theme.success
    }

    Column {
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 16; leftMargin: 16; rightMargin: 16 }
        spacing: 16

        // — Carte batterie —
        Rectangle {
            width: parent.width; height: 90; radius: 10
            color: Qt.rgba(1, 1, 1, 0.04)

            Column {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 16; rightMargin: 16 }
                spacing: 10

                RowLayout {
                    width: parent.width; spacing: 12

                    Text {
                        text: root.batteryIcon(root.batteryPct, root.isCharging)
                        color: root.batteryColor(root.batteryPct)
                        font.family: Theme.fontFamily; font.pixelSize: 28
                    }

                    Column {
                        Layout.fillWidth: true; spacing: 3

                        RowLayout {
                            width: parent.width; spacing: 8
                            Text {
                                text: root.batteryPct + "%"
                                color: root.batteryColor(root.batteryPct)
                                font.family: Theme.fontFamily; font.pixelSize: 18; font.weight: Font.Bold
                            }
                            Text {
                                text: {
                                    if (root.isCharging) return "En charge"
                                    if (root.batteryState === "discharging") return "Décharge"
                                    if (root.batteryState === "fully-charged") return "Chargé"
                                    return root.batteryState
                                }
                                color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                                Layout.fillWidth: true
                            }
                            Text {
                                visible: root.timeRemaining !== ""
                                text: root.timeRemaining
                                color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                            }
                        }

                        // Progress bar
                        Rectangle {
                            width: parent.width; height: 6; radius: 3
                            color: Qt.rgba(1, 1, 1, 0.1)
                            Rectangle {
                                width: parent.width * (root.batteryPct / 100)
                                height: parent.height; radius: parent.radius
                                color: root.batteryColor(root.batteryPct)
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }
            }
        }

        // — Détails —
        Row {
            width: parent.width; spacing: 8

            Rectangle {
                width: (parent.width - 8) / 2; height: 48; radius: 8
                color: Qt.rgba(1, 1, 1, 0.04)
                Column {
                    anchors.centerIn: parent; spacing: 3
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.energyRate > 0 ? root.energyRate.toFixed(1) + " W" : "—"
                        color: Theme.textDim; font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "PUISSANCE"; color: Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.35)
                        font.family: Theme.fontFamily; font.pixelSize: 9; font.weight: Theme.fontWeight
                    }
                }
            }

            Rectangle {
                width: (parent.width - 8) / 2; height: 48; radius: 8
                color: Qt.rgba(1, 1, 1, 0.04)
                Column {
                    anchors.centerIn: parent; spacing: 3
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.timeRemaining !== "" ? root.timeRemaining : "—"
                        color: Theme.textDim; font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.isCharging ? "JUSQU'AU PLEIN" : "RESTANT"
                        color: Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.35)
                        font.family: Theme.fontFamily; font.pixelSize: 9; font.weight: Theme.fontWeight
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.separator }

        // — Mode CPU —
        Column {
            width:   parent.width
            spacing: 10

            Text {
                text:           "MODE CPU"
                color:          Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            Row {
                width:   parent.width
                spacing: 8

                Repeater {
                    model: [
                        { mode: "powersave",   icon: "󰁹", label: "Éco"  },
                        { mode: "reset",       icon: "󰾅", label: "Auto" },
                        { mode: "performance", icon: "󱐌", label: "Perf" }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        property bool isActive: root.currentMode === modelData.mode
                        property bool hov:      false

                        width:  (parent.width - 16) / 3
                        height: 58
                        radius: 6
                        color:  isActive
                                ? Qt.rgba(0xDD/255, 0xAC/255, 0x26/255, 0.18)
                                : hov ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.04)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            visible:      parent.isActive
                            anchors.fill: parent; radius: parent.radius
                            color:        "transparent"
                            border.color: Theme.aiIcon; border.width: 1; opacity: 0.6
                        }

                        Column {
                            anchors.centerIn: parent; spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text:           modelData.icon
                                color:          parent.parent.isActive ? Theme.aiIcon : Theme.text
                                font.family:    Theme.fontFamily; font.pixelSize: Theme.iconSize
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text:           modelData.label
                                color:          parent.parent.isActive ? Theme.text : Theme.textDim
                                font.family:    Theme.fontFamily; font.pixelSize: 9; font.weight: Font.DemiBold
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                        }

                        Rectangle {
                            visible:      root.eppBusy && !parent.isActive
                            anchors.fill: parent; radius: parent.radius
                            color:        Qt.rgba(0, 0, 0, 0.35)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  root.eppBusy ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered:    parent.hov = true
                            onExited:     parent.hov = false
                            onClicked:    if (!root.eppBusy) root.setEpp(modelData.mode)
                        }
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.separator }

        // — Actions —
        Text {
            text: "ACTIONS"
            color: Theme.textDim; font.family: Theme.fontFamily
            font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
        }

        Column {
            width: parent.width; spacing: 6

            Repeater {
                model: [
                    { icon: "󰒲", label: "Veille",       desc: "Suspend le système",   cmd: ["bash", "-c", "hyprlock & sleep 0.5 && systemctl suspend"], danger: false },
                    { icon: "󰌾", label: "Verrouiller",  desc: "Verrouille l'écran",   cmd: ["hyprlock"],                                                  danger: false },
                    { icon: "󰍃", label: "Déconnexion",  desc: "Ferme la session",     cmd: ["hyprctl", "dispatch", "exit"],                               danger: false },
                    { icon: "󰑓", label: "Redémarrer",   desc: "Redémarre le système", cmd: ["systemctl", "reboot"],                                       danger: false },
                    { icon: "󰐥", label: "Éteindre",     desc: "Arrêt du système",     cmd: ["systemctl", "poweroff"],                                     danger: true  }
                ]

                delegate: Rectangle {
                    required property var modelData
                    property bool pwHov: false

                    width: parent.width; height: 42; radius: 6
                    color: pwHov
                           ? (modelData.danger ? Qt.rgba(0xF9/255, 0x65/255, 0x65/255, 0.12) : Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.07))
                           : Qt.rgba(1, 1, 1, 0.04)
                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 12

                        Text {
                            text: modelData.icon
                            color: modelData.danger ? Theme.danger : Theme.text
                            font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize + 2
                        }
                        Column {
                            Layout.fillWidth: true; spacing: 1
                            Text {
                                text: modelData.label
                                color: modelData.danger ? Theme.danger : Theme.text
                                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight
                            }
                            Text {
                                text: modelData.desc
                                color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 10
                            }
                        }
                        Text {
                            text: "›"
                            color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 14
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onEntered: parent.pwHov = true
                        onExited: parent.pwHov = false
                        onClicked: Quickshell.execDetached(modelData.cmd)
                    }
                }
            }
        }
    }
}
