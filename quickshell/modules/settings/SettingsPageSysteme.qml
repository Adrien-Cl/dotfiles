import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root

    property string osName:    ""
    property string kernelVer: ""
    property string hostName:  ""
    property string uptime:    ""

    property real   cpuUsage:    0
    property int    cpuPrevBusy:  0
    property int    cpuPrevTotal: 0
    property bool   cpuFirstRead: true

    property real   ramUsedGb:   0
    property real   ramTotalGb:  0

    property string diskUsed:  ""
    property string diskTotal: ""
    property int    diskPct:   0

    property real   tempC:     0

    property int    updateCount: 0

    Process {
        id: procOsInfo
        command: ["bash", "-c",
            "echo \"OS:$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '\"')\"; " +
            "echo \"KERNEL:$(uname -r)\"; " +
            "echo \"HOST:$(hostname)\"; " +
            "echo \"UPTIME:$(uptime -p 2>/dev/null | sed 's/up //')\""]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.startsWith("OS:"))     root.osName    = data.slice(3).trim()
                if (data.startsWith("KERNEL:")) root.kernelVer = data.slice(7).trim()
                if (data.startsWith("HOST:"))   root.hostName  = data.slice(5).trim()
                if (data.startsWith("UPTIME:")) root.uptime    = data.slice(7).trim()
            }
        }
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
                if (root.cpuFirstRead) { root.cpuFirstRead = false }
                else {
                    var db = busy - root.cpuPrevBusy, dt = total - root.cpuPrevTotal
                    if (dt > 0) root.cpuUsage = Math.round(db / dt * 100)
                }
                root.cpuPrevBusy = busy; root.cpuPrevTotal = total
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: procCpu.running = true }

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
    Timer { interval: 3000; running: true; repeat: true; onTriggered: procRam.running = true }

    Process {
        id: procDisk
        command: ["bash", "-c", "df -h / | awk 'NR==2{print $3, $2, $5}'"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var p = data.trim().split(/\s+/)
                if (p.length < 3) return
                root.diskUsed = p[0]; root.diskTotal = p[1]; root.diskPct = parseInt(p[2]) || 0
            }
        }
    }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: procDisk.running = true }

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
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: procTemp.running = true }

    Process {
        id: procUpdates
        command: ["bash", "-c", "pacman -Qu 2>/dev/null | wc -l"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => { root.updateCount = parseInt(data.trim()) || 0 }
        }
    }

    Component.onCompleted: {
        procOsInfo.running = true
        procUpdates.running = true
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

            // — Infos système —
            Text {
                text: "INFORMATIONS SYSTÈME"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            Column {
                width: parent.width; spacing: 4

                Repeater {
                    model: [
                        { icon: "󰣇", label: "Système",  value: root.osName    !== "" ? root.osName    : "…" },
                        { icon: "󰣐", label: "Kernel",   value: root.kernelVer !== "" ? root.kernelVer : "…" },
                        { icon: "󰇹", label: "Machine",  value: root.hostName  !== "" ? root.hostName  : "…" },
                        { icon: "󰔚", label: "Uptime",   value: root.uptime    !== "" ? root.uptime    : "…" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width; height: 34; radius: 6
                        color: Qt.rgba(1, 1, 1, 0.04)
                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 10
                            Text {
                                text: modelData.icon; color: Theme.textDim
                                font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                            }
                            Text {
                                text: modelData.label; color: Theme.textDim
                                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: modelData.value; color: Theme.text
                                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
                                font.weight: Theme.fontWeight; elide: Text.ElideRight
                                Layout.maximumWidth: 340
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.separator }

            // — Ressources —
            Text {
                text: "UTILISATION DES RESSOURCES"
                color: Theme.textDim; font.family: Theme.fontFamily
                font.pixelSize: 9; font.weight: Font.Bold; opacity: 0.7
            }

            Row {
                width: parent.width; spacing: 8

                Repeater {
                    model: 4

                    delegate: Rectangle {
                        required property int index

                        property string cardIcon: {
                            if (index === 0) return String.fromCodePoint(0xF4BC)
                            if (index === 1) return String.fromCodePoint(0xF061A)
                            if (index === 2) return "󰋊"
                            return "󰔄"
                        }
                        property string cardLabel: ["CPU", "RAM", "DISK", "TEMP"][index]
                        property string cardValue: {
                            if (index === 0) return root.cpuUsage + "%"
                            if (index === 1) return root.ramTotalGb > 0 ? Math.round(root.ramUsedGb / root.ramTotalGb * 100) + "%" : "—"
                            if (index === 2) return root.diskPct + "%"
                            return root.tempC + "°C"
                        }
                        property color cardColor: {
                            if (index === 0) return root.cpuUsage >= 80 ? Theme.danger : root.cpuUsage >= 60 ? "#FFA500" : Theme.text
                            if (index === 2) return root.diskPct >= 90 ? Theme.danger : root.diskPct >= 75 ? "#FFA500" : Theme.text
                            if (index === 3) return root.tempC >= 80 ? Theme.danger : root.tempC >= 60 ? "#FFA500" : "#4CAF50"
                            return Theme.text
                        }

                        width: (parent.width - 24) / 4; height: 64; radius: 8
                        color: Qt.rgba(1, 1, 1, 0.05)

                        Column {
                            anchors.centerIn: parent; spacing: 3

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: cardIcon; color: cardColor
                                font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: cardValue; color: Theme.textDim
                                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: cardLabel
                                color: Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.3)
                                font.family: Theme.fontFamily; font.pixelSize: 9; font.weight: Theme.fontWeight
                            }
                        }
                    }
                }
            }

            // RAM detail
            Text {
                text: root.ramTotalGb > 0 ? root.ramUsedGb + " Go / " + root.ramTotalGb + " Go utilisés" : ""
                color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 10
                opacity: 0.7
            }

            // Disk detail
            Text {
                text: root.diskUsed !== "" ? "Disque : " + root.diskUsed + " / " + root.diskTotal + " utilisés" : ""
                color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 10
                opacity: 0.7
            }

            Rectangle { width: parent.width; height: 1; color: Theme.separator }

            // — Mises à jour —
            RowLayout {
                width: parent.width; spacing: 10

                Text {
                    text: "󰚰"
                    color: root.updateCount > 0 ? "#FFA500" : "#4CAF50"
                    font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                }
                Text {
                    text: root.updateCount > 0
                          ? root.updateCount + " paquet" + (root.updateCount > 1 ? "s" : "") + " à mettre à jour"
                          : "Système à jour"
                    color: Theme.text; font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight; Layout.fillWidth: true
                }
                Rectangle {
                    visible: root.updateCount > 0
                    width: updLbl2.implicitWidth + 14; height: 24; radius: 4
                    color: Qt.rgba(0xFF/255, 0xA5/255, 0, 0.15)
                    Text {
                        id: updLbl2; anchors.centerIn: parent; text: "Mettre à jour"
                        color: "#FFA500"; font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Theme.fontWeight
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["kitty", "-e", "bash", "-c", "yay -Syu; read -p 'Terminé — Appuyer sur Entrée...'"])
                    }
                }
                Rectangle {
                    width: rfrLbl.implicitWidth + 14; height: 24; radius: 4
                    color: Qt.rgba(1, 1, 1, 0.07)
                    Text {
                        id: rfrLbl; anchors.centerIn: parent; text: "⟳ Vérifier"
                        color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Theme.fontWeight
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (!procUpdates.running) procUpdates.running = true }
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
