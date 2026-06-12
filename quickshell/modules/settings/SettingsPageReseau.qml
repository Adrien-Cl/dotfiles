import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root

    property var    wifiList:      []
    property bool   scanning:      false
    property string currentSsid:   ""
    property string currentIp:     ""

    Process {
        id: procWifiScan
        command: ["bash", "-c",
            "nmcli device wifi rescan 2>/dev/null; sleep 2; " +
            "nmcli -t --escape no -f SSID,SIGNAL,SECURITY,ACTIVE device wifi list 2>/dev/null"]
        running: false
        onRunningChanged: if (!running) root.scanning = false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var line = data.trim()
                if (line === "") return
                var parts = line.split(":")
                if (parts.length < 4) return
                var active   = parts[parts.length - 1].trim()
                var sec      = parts[parts.length - 2].trim()
                var sig      = parseInt(parts[parts.length - 3]) || 0
                var ssid     = parts.slice(0, parts.length - 3).join(":").trim()
                if (ssid === "" || ssid === "--") return
                var idx = root.wifiList.findIndex(n => n.ssid === ssid)
                if (idx >= 0) {
                    if (sig > root.wifiList[idx].signal) {
                        var updated = root.wifiList.slice()
                        updated[idx] = { ssid: ssid, signal: sig, security: sec, active: active === "oui" || active === "yes" }
                        root.wifiList = updated
                    }
                } else {
                    root.wifiList = root.wifiList.concat([{ ssid: ssid, signal: sig, security: sec, active: active === "oui" || active === "yes" }])
                }
            }
        }
    }

    Process {
        id: procCurrentConn
        command: ["bash", "-c",
            "nmcli -t -f GENERAL.CONNECTION,IP4.ADDRESS device show wlan0 2>/dev/null | " +
            "grep -E '^GENERAL\\.CONNECTION|^IP4\\.ADDRESS'"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.startsWith("GENERAL.CONNECTION:")) {
                    var v = data.split(":").slice(1).join(":").trim()
                    root.currentSsid = (v === "--" || v === "") ? "" : v
                } else if (data.startsWith("IP4.ADDRESS[1]:")) {
                    root.currentIp = data.split(":").slice(1).join(":").trim().split("/")[0]
                }
            }
        }
    }

    Process {
        id: procConnect
        running: false
    }

    function scanNetworks() {
        root.scanning = true
        root.wifiList = []
        if (!procWifiScan.running) procWifiScan.running = true
    }

    function signalIcon(sig) {
        if (sig >= 80) return "󰤨"
        if (sig >= 60) return "󰤥"
        if (sig >= 40) return "󰤢"
        if (sig >= 20) return "󰤟"
        return "󰤯"
    }

    Component.onCompleted: {
        procCurrentConn.running = true
        scanNetworks()
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

            // — Header WiFi toggle —
            RowLayout {
                width: parent.width
                spacing: 8

                Text {
                    text: "󰤨"
                    color: Networking.wifiEnabled ? Theme.text : Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.iconSize
                }
                Text {
                    text: "WiFi"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.fontWeight
                    Layout.fillWidth: true
                }
                Text {
                    text: Networking.wifiEnabled ? "Activé" : "Désactivé"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
                Rectangle {
                    width: 36; height: 18; radius: 9
                    color: Networking.wifiEnabled ? Theme.success : Theme.textDim
                    Rectangle {
                        width: 14; height: 14; radius: 7
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                        x: Networking.wifiEnabled ? parent.width - width - 2 : 2
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }
            }

            // — Connexion actuelle —
            Rectangle {
                width: parent.width
                height: root.currentSsid !== "" ? 54 : 0
                visible: root.currentSsid !== ""
                radius: 8
                color: Qt.rgba(0x4C/255, 0xAF/255, 0x50/255, 0.08)

                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 10

                    Text {
                        text: "󰤨"
                        color: Theme.success
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.iconSize + 4
                    }
                    Column {
                        spacing: 2
                        Text {
                            text: root.currentSsid
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight: Theme.fontWeight
                        }
                        Text {
                            text: root.currentIp !== "" ? root.currentIp : "Connecté"
                            color: Theme.success
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: discLbl.implicitWidth + 14; height: 22; radius: 4
                        color: Qt.rgba(1, 0.3, 0.3, 0.12)
                        Text {
                            id: discLbl
                            anchors.centerIn: parent
                            text: "Déconnecter"
                            color: Theme.danger
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Theme.fontWeight
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                procConnect.command = ["nmcli", "device", "disconnect", "wlan0"]
                                procConnect.running = true
                                root.currentSsid = ""
                                root.currentIp = ""
                            }
                        }
                    }
                }
            }

            // — Section réseaux —
            Rectangle {
                width: parent.width; height: 1
                color: Theme.separator
            }

            RowLayout {
                width: parent.width
                spacing: 8

                Text {
                    text: "RÉSEAUX DISPONIBLES"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    opacity: 0.7
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: scanBtnLbl.implicitWidth + 14; height: 22; radius: 4
                    color: Qt.rgba(1, 1, 1, 0.07)
                    Text {
                        id: scanBtnLbl
                        anchors.centerIn: parent
                        text: root.scanning ? "⏳ Scan…" : "⟳  Scanner"
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Theme.fontWeight
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.scanning
                        onClicked: root.scanNetworks()
                    }
                }
            }

            // Loading state
            Text {
                visible: root.scanning && root.wifiList.length === 0
                width: parent.width
                text: "Scan en cours…"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                horizontalAlignment: Text.AlignHCenter
                topPadding: 8
            }

            Text {
                visible: !root.scanning && root.wifiList.length === 0
                width: parent.width
                text: Networking.wifiEnabled ? "Aucun réseau trouvé" : "WiFi désactivé"
                color: Theme.textDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                horizontalAlignment: Text.AlignHCenter
                topPadding: 8
            }

            // — Liste des réseaux —
            Column {
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.wifiList

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        property bool itemHovered: false

                        width: parent.width; height: 38; radius: 6
                        color: modelData.active
                               ? Qt.rgba(0x4C/255, 0xAF/255, 0x50/255, 0.07)
                               : itemHovered
                                 ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.05)
                                 : Qt.rgba(1, 1, 1, 0.03)
                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            spacing: 8

                            Text {
                                text: root.signalIcon(modelData.signal)
                                color: modelData.active ? Theme.success : Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.iconSize
                            }
                            Text {
                                text: modelData.ssid
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.weight: Theme.fontWeight
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                visible: modelData.security !== "--" && modelData.security !== ""
                                text: "󰌾"
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                            Rectangle {
                                visible: !modelData.active
                                width: connLbl.implicitWidth + 12; height: 22; radius: 4
                                color: Qt.rgba(0.3, 0.75, 0.3, 0.12)
                                Text {
                                    id: connLbl
                                    anchors.centerIn: parent
                                    text: "Connecter"
                                    color: Theme.success
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Theme.fontWeight
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.security === "--" || modelData.security === "") {
                                            procConnect.command = ["nmcli", "device", "wifi", "connect", modelData.ssid]
                                            procConnect.running = true
                                        } else {
                                            Quickshell.execDetached(["kitty", "-e", "bash", "-c",
                                                "nmcli device wifi connect '" + modelData.ssid + "' && echo 'Connecté!' || echo 'Échec'; read -p 'Appuyer sur Entrée...'"])
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onEntered: parent.itemHovered = true
                            onExited: parent.itemHovered = false
                        }
                    }
                }
            }
        }
    }

    // Scrollbar
    Rectangle {
        visible: flick.contentHeight > flick.height
        anchors { right: parent.right; rightMargin: 2 }
        width: 3; radius: 2
        color: Qt.rgba(1, 1, 1, 0.15)
        y: flick.visibleArea.yPosition * flick.height
        height: Math.max(20, flick.visibleArea.heightRatio * flick.height)
    }
}
