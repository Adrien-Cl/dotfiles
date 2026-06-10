import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../"

PopupWindow {
    id: root

    required property PanelWindow bar

    signal closeRequested()
    signal backRequested()

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

    function deviceIcon(iconHint) {
        if (!iconHint) return "󰂯"
        if (iconHint.indexOf("headset")   >= 0 || iconHint.indexOf("headphone") >= 0) return "󰋋"
        if (iconHint.indexOf("mouse")     >= 0) return "󰍽"
        if (iconHint.indexOf("keyboard")  >= 0) return "󰌌"
        if (iconHint.indexOf("gaming")    >= 0 || iconHint.indexOf("gamepad")  >= 0) return "󰖺"
        if (iconHint.indexOf("phone")     >= 0) return "󰄜"
        if (iconHint.indexOf("audio")     >= 0 || iconHint.indexOf("speaker")  >= 0) return "󰓃"
        return "󰂯"
    }

    property bool cleaningForScan: false

    Process {
        id: procCleanDevices
        command: ["bash", "-c",
            "paired=$(bluetoothctl devices Paired | awk '{print $2}'); " +
            "bluetoothctl devices | awk '{print $2}' | while read a; do " +
            "echo \"$paired\" | grep -qx \"$a\" || bluetoothctl remove \"$a\"; " +
            "done"]
        running: false
        onRunningChanged: {
            if (!running && root.cleaningForScan) {
                root.cleaningForScan = false
                if (Bluetooth.defaultAdapter)
                    Bluetooth.defaultAdapter.discovering = true
            }
        }
    }

    Process {
        id: procTrust
        property string mac: ""
        command: ["bluetoothctl", "trust", mac]
        running: false
    }

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

            // — Header : retour + titre + toggle power —
            RowLayout {
                width:   parent.width
                spacing: 8

                Text {
                    text:           "󰁍"
                    color:          Theme.textDim
                    font.family:    Theme.fontFamily
                    font.pixelSize: Theme.iconSize

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.backRequested()
                    }
                }

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

                Rectangle {
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

            // — Label section + bouton scan —
            RowLayout {
                width:   parent.width
                spacing: 8

                Text {
                    text:             "Appareils"
                    color:            Theme.textDim
                    font.family:      Theme.fontFamily
                    font.pixelSize:   10
                    font.weight:      Theme.fontWeight
                    Layout.fillWidth: true
                }

                Rectangle {
                    width:  scanLbl.implicitWidth + 14
                    height: 20
                    radius: 4
                    color:  Qt.rgba(1, 1, 1, 0.07)

                    Text {
                        id:             scanLbl
                        anchors.centerIn: parent
                        text:           Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering ? "■  Stop" : "⟳  Scan"
                        color:          Theme.textDim
                        font.family:    Theme.fontFamily
                        font.pixelSize: 10
                        font.weight:    Theme.fontWeight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            if (!Bluetooth.defaultAdapter) return
                            if (Bluetooth.defaultAdapter.discovering ?? false) {
                                Bluetooth.defaultAdapter.discovering = false
                            } else {
                                root.cleaningForScan = true
                                procCleanDevices.running = true
                            }
                        }
                    }
                }
            }

            // — Liste des appareils (scrollable) —
            Item {
                id:     deviceScroll
                width:  parent.width
                height: Math.min(deviceListCol.implicitHeight, 260)
                clip:   true

                Flickable {
                    id:            deviceFlick
                    anchors.fill:  parent
                    contentHeight: deviceListCol.implicitHeight
                    clip:          true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id:      deviceListCol
                        width:   deviceFlick.width - (deviceFlick.contentHeight > deviceFlick.height ? 8 : 0)
                        spacing: 6

                    Text {
                        visible:           !(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)
                                           || deviceRepeater.count === 0
                        width:             parent.width
                        text:              Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                                           ? "Aucun appareil trouvé" : "Bluetooth désactivé"
                        color:             Theme.textDim
                        font.family:       Theme.fontFamily
                        font.pixelSize:    Theme.fontSize
                        horizontalAlignment: Text.AlignHCenter
                        topPadding:        4
                        bottomPadding:     4
                    }

                    Repeater {
                        model: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.devices : []
                        delegate: Rectangle {
                            required property var modelData
                            visible: modelData.connected
                            width:  visible ? parent.width : 0
                            height: visible ? 38 : 0
                            radius: 6
                            color:  Qt.rgba(1, 1, 1, 0.04)
                            RowLayout {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                spacing: 8
                                Text {
                                    text: root.deviceIcon(modelData.icon ?? "")
                                    color: "#4CAF50"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.iconSize
                                }
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: modelData.deviceName || modelData.name
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize
                                        font.weight: Theme.fontWeight
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    Text {
                                        text: "• Connecté"
                                        color: "#4CAF50"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                    }
                                }
                                Rectangle {
                                    width: disconnectLbl.implicitWidth + 14
                                    height: 22; radius: 4
                                    color: Qt.rgba(1, 0.3, 0.3, 0.15)
                                    Text {
                                        id: disconnectLbl
                                        anchors.centerIn: parent
                                        text: "✕"
                                        color: Theme.danger
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Theme.fontWeight
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.disconnect()
                                    }
                                }
                            }
                        }
                    }

                    Repeater {
                        id:    deviceRepeater
                        model: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.devices : []

                        delegate: Rectangle {
                            required property var modelData

                            visible: {
                                if (modelData.connected) return false
                                if (modelData.paired) return true
                                var n = modelData.deviceName || modelData.name || ""
                                if (n === "") return false
                                if (/^([0-9A-Fa-f]{2}[-:]){5}[0-9A-Fa-f]{2}$/.test(n)) return false
                                if (/([0-9A-Fa-f]{2}[:-]){2}[0-9A-Fa-f]{2}$/.test(n)) return false
                                return true
                            }
                            width:  visible ? parent.width : 0
                            height: visible ? 38 : 0
                            radius: 6
                            color:  Qt.rgba(1, 1, 1, 0.04)

                            RowLayout {
                                anchors {
                                    fill:        parent
                                    leftMargin:  10
                                    rightMargin: 10
                                }
                                spacing: 8

                                Text {
                                    text:           root.deviceIcon(modelData.icon ?? "")
                                    color:          modelData.connected ? "#4CAF50" : Theme.textDim
                                    font.family:    Theme.fontFamily
                                    font.pixelSize: Theme.iconSize
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text:           modelData.deviceName || modelData.name
                                        color:          Theme.text
                                        font.family:    Theme.fontFamily
                                        font.pixelSize: Theme.fontSize
                                        font.weight:    Theme.fontWeight
                                        elide:          Text.ElideRight
                                        width:          parent.width
                                    }

                                    Text {
                                        visible:        modelData.connected
                                        text:           "• Connecté"
                                        color:          "#4CAF50"
                                        font.family:    Theme.fontFamily
                                        font.pixelSize: 9
                                    }
                                }

                                Rectangle {
                                    width:  actionLbl.implicitWidth + 14
                                    height: 22
                                    radius: 4
                                    color:  modelData.connected
                                            ? Qt.rgba(1, 0.3, 0.3, 0.15)
                                            : Qt.rgba(0.3, 0.75, 0.3, 0.15)

                                    Text {
                                        id:             actionLbl
                                        anchors.centerIn: parent
                                        text:           modelData.connected ? "✕" : "Connecter"
                                        color:          modelData.connected ? Theme.danger : "#4CAF50"
                                        font.family:    Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight:    Theme.fontWeight
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape:  Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.connected) {
                                                modelData.disconnect()
                                            } else {
                                                modelData.connect()
                                                procTrust.mac = modelData.address
                                                procTrust.running = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    }
                }

                // Scrollbar custom
                Rectangle {
                    visible:       deviceFlick.contentHeight > deviceFlick.height
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    width:         4
                    radius:        2
                    color:         Qt.rgba(1, 1, 1, 0.2)
                    y:             deviceFlick.visibleArea.yPosition * deviceFlick.height
                    height:        Math.max(20, deviceFlick.visibleArea.heightRatio * deviceFlick.height)
                }
            }

            Item { width: 1; height: 2 }
        }
    }
}
