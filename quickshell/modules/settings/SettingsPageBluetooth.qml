import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root

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

    function deviceIcon(iconHint) {
        if (!iconHint) return "󰂯"
        if (iconHint.indexOf("headset") >= 0 || iconHint.indexOf("headphone") >= 0) return "󰋋"
        if (iconHint.indexOf("mouse") >= 0) return "󰍽"
        if (iconHint.indexOf("keyboard") >= 0) return "󰌌"
        if (iconHint.indexOf("gaming") >= 0 || iconHint.indexOf("gamepad") >= 0) return "󰖺"
        if (iconHint.indexOf("phone") >= 0) return "󰄜"
        if (iconHint.indexOf("audio") >= 0 || iconHint.indexOf("speaker") >= 0) return "󰓃"
        return "󰂯"
    }

    Column {
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 16; leftMargin: 16; rightMargin: 16 }
        spacing: 14

        // — Toggle Bluetooth —
        RowLayout {
            width: parent.width
            spacing: 8

            Text {
                text: "󰂯"
                color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? Theme.text : Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.iconSize
            }
            Text {
                text: "Bluetooth"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
                Layout.fillWidth: true
            }
            Text {
                text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "Activé" : "Désactivé"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
            Rectangle {
                width: 36; height: 18; radius: 9
                color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "#4CAF50" : Theme.textDim
                Rectangle {
                    width: 14; height: 14; radius: 7
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                    x: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? parent.width - width - 2 : 2
                    Behavior on x { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Bluetooth.defaultAdapter)
                            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.separator }

        // — Section appareils + scan —
        RowLayout {
            width: parent.width
            spacing: 8

            Text {
                text: "APPAREILS"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: 9
                font.weight: Font.Bold
                opacity: 0.7
                Layout.fillWidth: true
            }

            Rectangle {
                width: scanLbl.implicitWidth + 14; height: 22; radius: 4
                color: Qt.rgba(1, 1, 1, 0.07)
                Text {
                    id: scanLbl
                    anchors.centerIn: parent
                    text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering ? "■  Stop" : "⟳  Scan"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Theme.fontWeight
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
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

        // — Liste appareils (scrollable) —
        Item {
            id: deviceScroll
            width: parent.width
            height: Math.min(deviceListCol.implicitHeight, 360)
            clip: true

            Flickable {
                id: deviceFlick
                anchors.fill: parent
                contentHeight: deviceListCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: deviceListCol
                    width: deviceFlick.width - (deviceFlick.contentHeight > deviceFlick.height ? 8 : 0)
                    spacing: 6

                    Text {
                        visible: !(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)
                                 || deviceRepeater.count === 0
                        width: parent.width
                        text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                              ? "Aucun appareil trouvé" : "Bluetooth désactivé"
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 8; bottomPadding: 8
                    }

                    Repeater {
                        model: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.devices : []
                        delegate: Rectangle {
                            required property var modelData
                            visible: modelData.connected
                            width: visible ? parent.width : 0
                            height: visible ? 42 : 0
                            radius: 6
                            color: Qt.rgba(1, 1, 1, 0.04)
                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 10
                                Text {
                                    text: root.deviceIcon(modelData.icon ?? "")
                                    color: "#4CAF50"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.iconSize + 2
                                }
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        text: modelData.deviceName || modelData.name || "Inconnu"
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
                                    width: disconnectLbl2.implicitWidth + 14
                                    height: 24; radius: 4
                                    color: Qt.rgba(1, 0.3, 0.3, 0.15)
                                    Text {
                                        id: disconnectLbl2
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
                        id: deviceRepeater
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
                            width: visible ? parent.width : 0
                            height: visible ? 42 : 0
                            radius: 6
                            color: Qt.rgba(1, 1, 1, 0.04)

                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 10

                                Text {
                                    text: root.deviceIcon(modelData.icon ?? "")
                                    color: modelData.connected ? "#4CAF50" : Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.iconSize + 2
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: modelData.deviceName || modelData.name || "Inconnu"
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize
                                        font.weight: Theme.fontWeight
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    Text {
                                        visible: modelData.connected || modelData.paired
                                        text: modelData.connected ? "• Connecté" : "Jumelé"
                                        color: modelData.connected ? "#4CAF50" : Theme.textDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                    }
                                }

                                Rectangle {
                                    width: actLbl.implicitWidth + 14; height: 24; radius: 4
                                    color: modelData.connected
                                           ? Qt.rgba(1, 0.3, 0.3, 0.15)
                                           : Qt.rgba(0.3, 0.75, 0.3, 0.15)
                                    Text {
                                        id: actLbl
                                        anchors.centerIn: parent
                                        text: modelData.connected ? "✕" : "Connecter"
                                        color: modelData.connected ? Theme.danger : "#4CAF50"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Theme.fontWeight
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
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

            Rectangle {
                visible: deviceFlick.contentHeight > deviceFlick.height
                anchors { right: parent.right; rightMargin: 1 }
                width: 3; radius: 2
                color: Qt.rgba(1, 1, 1, 0.2)
                y: deviceFlick.visibleArea.yPosition * deviceFlick.height
                height: Math.max(20, deviceFlick.visibleArea.heightRatio * deviceFlick.height)
            }
        }
    }
}
