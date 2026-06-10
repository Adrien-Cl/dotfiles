import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root

    property real brightnessMax:     19200
    property real brightnessCurrent: 0
    property string monitorName:     ""
    property string monitorRes:      ""
    property real   monitorScale:    1.2
    property real   monitorHz:       60

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
        running: true
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
        id: procMonitorInfo
        command: ["bash", "-c",
            "hyprctl monitors | head -5 | awk '" +
            "/^Monitor / {name=$2} " +
            "/[0-9]+x[0-9]+@/ {res=$1} " +
            "/scale/ {sc=$NF}' && " +
            "echo \"$name|$res|$sc\""]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var p = data.trim().split("|")
                if (p.length >= 1 && p[0] !== "") root.monitorName = p[0]
                if (p.length >= 2 && p[1] !== "") {
                    root.monitorRes = p[1].split("@")[0]
                    var hz = p[1].split("@")[1]
                    if (hz) root.monitorHz = Math.round(parseFloat(hz))
                }
                if (p.length >= 3 && p[2] !== "") root.monitorScale = parseFloat(p[2]) || 1.2
            }
        }
    }

    Process {
        id: procSetScale
        running: false
    }

    Process {
        id: procWriteMonitor
        running: false
    }

    Component.onCompleted: {
        procMonitorInfo.running = true
    }

    property real bright: root.brightnessMax > 0 ? root.brightnessCurrent / root.brightnessMax : 0

    Column {
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 16; leftMargin: 16; rightMargin: 16 }
        spacing: 14

        // — Infos moniteur —
        Text {
            text: "MONITEUR"
            color: Theme.textDim; font.family: Theme.fontFamily
            font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
        }

        Rectangle {
            width: parent.width; height: 54; radius: 8
            color: Qt.rgba(1, 1, 1, 0.04)

            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 14

                Text {
                    text: "󰍹"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 24
                }

                Column {
                    spacing: 3
                    Text {
                        text: root.monitorName !== "" ? root.monitorName : "eDP-1"
                        color: Theme.text; font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight
                    }
                    Text {
                        text: {
                            var res = root.monitorRes !== "" ? root.monitorRes : "1920x1080"
                            var hz = root.monitorHz > 0 ? "@" + root.monitorHz + "Hz" : ""
                            return res + hz + "  ×" + root.monitorScale
                        }
                        color: Theme.textDim
                        font.family: Theme.fontFamily; font.pixelSize: 10
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.separator }

        // — Luminosité —
        RowLayout {
            width: parent.width; spacing: 8
            Text {
                text: { var b = root.bright; if (b < 0.34) return "󰃞"; if (b < 0.67) return "󰃝"; return "󰃠" }
                color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
            }
            Text {
                text: "Luminosité"
                color: Theme.text; font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight; Layout.fillWidth: true
            }
            Text {
                text: Math.round(root.bright * 100) + "%"
                color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
            }
        }

        Item {
            width: parent.width; height: 20
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 4; radius: 2; color: Theme.textDim
                Rectangle {
                    width: parent.width * root.bright; height: parent.height
                    radius: parent.radius; color: Theme.text
                }
            }
            Rectangle {
                width: 12; height: 12; radius: 6; color: "white"
                anchors.verticalCenter: parent.verticalCenter
                x: root.bright * (parent.width - width)
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.SizeHorCursor
                function apply(mx) {
                    var v = Math.max(0.04, Math.min(1.0, mx / width))
                    root.brightnessCurrent = Math.round(v * root.brightnessMax)
                    procBrightnessSet.command = ["brightnessctl", "s", Math.round(v * 100) + "%"]
                    procBrightnessSet.running = true
                }
                onPressed: (e) => apply(e.x)
                onPositionChanged: (e) => apply(e.x)
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.separator }

        // — Scale / DPI —
        RowLayout {
            width: parent.width; spacing: 8
            Text {
                text: "󰹖"
                color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
            }
            Text {
                text: "Échelle d'affichage"
                color: Theme.text; font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight; Layout.fillWidth: true
            }
            Text {
                text: "×" + root.monitorScale
                color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
            }
        }

        Row {
            width: parent.width; spacing: 8

            Repeater {
                model: [1.0, 1.25, 1.5, 2.0]

                delegate: Rectangle {
                    required property real modelData
                    required property int  index

                    property bool btnHovered: false
                    property bool isActive: Math.abs(root.monitorScale - modelData) < 0.01

                    width: (parent.width - 24) / 4; height: 36; radius: 6
                    color: isActive
                           ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.15)
                           : btnHovered
                             ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.07)
                             : Qt.rgba(1, 1, 1, 0.04)
                    border.color: isActive ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.4) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "×" + modelData
                        color: isActive ? Theme.text : Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: isActive ? Font.Bold : Theme.fontWeight
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onEntered: parent.btnHovered = true
                        onExited: parent.btnHovered = false
                        onClicked: {
                            root.monitorScale = parent.modelData
                            var monitor = root.monitorName !== "" ? root.monitorName : "eDP-1"
                            var res = root.monitorRes !== "" ? root.monitorRes : "1920x1080"
                            var hz = root.monitorHz > 0 ? "@" + root.monitorHz : "@60"
                            procSetScale.command = ["hyprctl", "keyword", "monitor",
                                monitor + "," + res + hz + ",auto," + parent.modelData]
                            procSetScale.running = true
                        }
                    }
                }
            }
        }

        Text {
            text: "L'échelle s'applique immédiatement. Pour rendre permanent, utilisez un outil comme nwg-displays."
            color: Theme.textDim; font.family: Theme.fontFamily
            font.pixelSize: 9; opacity: 0.6; wrapMode: Text.WordWrap; width: parent.width
        }
    }
}
