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

    // — Fonctions utilitaires —

    function batteryIcon(level, chg) {
        if (chg) {
            if (level < 10)  return "󰢟"
            if (level < 20)  return "󰢜"
            if (level < 30)  return "󰂆"
            if (level < 40)  return "󰂇"
            if (level < 60)  return "󰂈"
            if (level < 80)  return "󰂉"
            if (level < 90)  return "󰂊"
            if (level < 100) return "󰂋"
            return "󰂅"
        }
        if (level < 10)  return "󰁺"
        if (level < 20)  return "󰁻"
        if (level < 30)  return "󰁼"
        if (level < 40)  return "󰁽"
        if (level < 50)  return "󰁾"
        if (level < 60)  return "󰁿"
        if (level < 70)  return "󰂀"
        if (level < 80)  return "󰂁"
        if (level < 90)  return "󰂂"
        return "󰁹"
    }

    function batteryColor(level) {
        if (level <= 15) return Theme.danger
        if (level <= 30) return Theme.warning
        return Theme.success
    }

    // — Processus actions —

    Process {
        id: procRing
        command: ["kdeconnect-cli", "-d", KdeConnectState.deviceId, "--ring"]
        running: false
    }

    Process {
        id: procClipboard
        command: ["kdeconnect-cli", "-d", KdeConnectState.deviceId, "--send-clipboard"]
        running: false
    }

    Process {
        id: procFile
        command: ["bash", "-c",
            "f=$(kdialog --getopenfilename \"$HOME\" 2>/dev/null || zenity --file-selection 2>/dev/null)" +
            " && [ -n \"$f\" ] && kdeconnect-cli -d '" + KdeConnectState.deviceId + "' --share \"$f\""]
        running: false
    }

    Process {
        id: procPing
        command: ["kdeconnect-cli", "-d", KdeConnectState.deviceId, "--ping"]
        running: false
    }

    Process {
        id: procOpenApp
        command: ["kdeconnect-app"]
        running: false
    }

    // — UI —

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

            // — Header (cliquable → ouvre kdeconnect-app) —
            Rectangle {
                width:  parent.width
                height: headerRow.implicitHeight + 10
                radius: 6
                color:  headerArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    id:      headerRow
                    anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                    spacing: 8

                    Text {
                        text:           "󰄜"
                        color:          KdeConnectState.connected ? Theme.success : Theme.textDim
                        font.family:    Theme.fontFamily
                        font.pixelSize: Theme.iconSize
                    }

                    Text {
                        text:             "KDE Connect"
                        color:            Theme.text
                        font.family:      Theme.fontFamily
                        font.pixelSize:   Theme.fontSize
                        font.weight:      Theme.fontWeight
                        Layout.fillWidth: true
                    }

                    Text {
                        text:           "󰏌"
                        color:          Theme.textDim
                        font.family:    Theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    id:           headerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    procOpenApp.running = true
                }
            }

            // — Séparateur —
            Rectangle {
                width:  parent.width
                height: 1
                color:  Theme.separator
            }

            // — Contenu connecté / déconnecté —
            Column {
                width:   parent.width
                spacing: 12
                visible: KdeConnectState.connected

                // Nom du device
                Text {
                    text:           KdeConnectState.deviceName
                    color:          Theme.text
                    font.family:    Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight:    Theme.fontWeight
                    elide:          Text.ElideRight
                    width:          parent.width
                }

                // Batterie
                Column {
                    width:   parent.width
                    spacing: 8

                    RowLayout {
                        width:   parent.width
                        spacing: 8

                        Text {
                            text:           root.batteryIcon(KdeConnectState.batteryLevel, KdeConnectState.charging)
                            color:          root.batteryColor(KdeConnectState.batteryLevel)
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.iconSize
                        }
                        Text {
                            text:             "Batterie"
                            color:            Theme.text
                            font.family:      Theme.fontFamily
                            font.pixelSize:   Theme.fontSize
                            font.weight:      Theme.fontWeight
                            Layout.fillWidth: true
                        }
                        Text {
                            text:           KdeConnectState.batteryLevel + "%"
                                            + (KdeConnectState.charging ? "  󰚥" : "")
                            color:          root.batteryColor(KdeConnectState.batteryLevel)
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight:    Theme.fontWeight
                        }
                    }

                    // Barre de batterie (passive)
                    Item {
                        width:  parent.width
                        height: 8

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width:  parent.width
                            height: 4
                            radius: 2
                            color:  Qt.rgba(1, 1, 1, 0.1)

                            Rectangle {
                                width:  parent.width * (KdeConnectState.batteryLevel / 100)
                                height: parent.height
                                radius: parent.radius
                                color:  root.batteryColor(KdeConnectState.batteryLevel)

                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }
            }

            // Message si déconnecté
            Text {
                visible:            !KdeConnectState.connected
                width:              parent.width
                text:               "Aucun appareil connecté\nOuvrez KDE Connect sur votre téléphone"
                color:              Theme.textDim
                font.family:        Theme.fontFamily
                font.pixelSize:     Theme.fontSize
                horizontalAlignment: Text.AlignHCenter
                wrapMode:           Text.WordWrap
                topPadding:         4
                bottomPadding:      4
            }

            // — Séparateur —
            Rectangle {
                width:  parent.width
                height: 1
                color:  Theme.separator
                visible: KdeConnectState.connected
            }

            // — Actions rapides —
            Column {
                width:   parent.width
                spacing: 8
                visible: KdeConnectState.connected

                Text {
                    text:           "Actions rapides"
                    color:          Theme.textDim
                    font.family:    Theme.fontFamily
                    font.pixelSize: 10
                    font.weight:    Theme.fontWeight
                }

                Row {
                    width:   parent.width
                    spacing: 8

                    Repeater {
                        model: [
                            { icon: "󰜎", label: "Sonner",    action: function() { procRing.running = true } },
                            { icon: "󰆏", label: "Clipboard", action: function() { procClipboard.running = true } },
                            { icon: "󰈔", label: "Fichier",   action: function() { procFile.running = true } },
                            { icon: "󰐺", label: "Ping",      action: function() { procPing.running = true } }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width:  (parent.width - 24) / 4
                            height: 52
                            radius: 6
                            color:  actionArea.containsMouse
                                    ? Qt.rgba(1, 1, 1, 0.12)
                                    : Qt.rgba(1, 1, 1, 0.06)

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text:           modelData.icon
                                    color:          Theme.text
                                    font.family:    Theme.fontFamily
                                    font.pixelSize: Theme.iconSize
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text:           modelData.label
                                    color:          Theme.textDim
                                    font.family:    Theme.fontFamily
                                    font.pixelSize: 9
                                    font.weight:    Theme.fontWeight
                                }
                            }

                            MouseArea {
                                id:           actionArea
                                anchors.fill: parent
                                cursorShape:  Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked:    modelData.action()
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 2 }
        }
    }
}
