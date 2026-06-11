import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../"

RowLayout {
    id: root
    spacing: Theme.spacing

    property int  notifCount:      0
    property int  batteryLevel:    0
    property bool batteryCharging: false
    property bool hasBattery:      false

    signal notifClicked()
    signal controlClicked()
    signal powerClicked()
    signal phoneClicked()
    signal fileManagerClicked()

    function batteryIcon(level, chg) {
        if (chg) return ""
        if (level < 10)  return ""
        if (level < 30)  return ""
        if (level < 60)  return ""
        if (level < 80)  return ""
        return ""
    }

    function batteryColor(level) {
        if (level <= 15) return Theme.danger
        if (level <= 30) return "#FFA500"
        return "#4CAF50"
    }

    Process {
        id: procBattery
        command: ["bash", "-c",
            "for b in /sys/class/power_supply/BAT*; do " +
            "  [ -f \"$b/capacity\" ] && echo \"has:$(cat $b/capacity):$(cat $b/status)\" && break; " +
            "done"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!data.startsWith("has:")) { root.hasBattery = false; return }
                root.hasBattery = true
                var parts = data.split(":")
                root.batteryLevel    = parseInt(parts[1])
                root.batteryCharging = parts[2].trim() === "Charging"
            }
        }
    }

    Timer {
        interval:    60000
        running:     true
        repeat:      true
        onTriggered: procBattery.running = true
    }

    // Clock + Date
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Text {
        text:           Qt.formatTime(clock.date, "HH:mm")
        color:          Theme.text
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight:    Theme.fontWeight
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        text:           "|"
        color:          Theme.text
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight:    Font.DemiBold
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        text:           Qt.formatDate(clock.date, "dd/MM/yyyy")
        color:          Theme.text
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight:    Theme.fontWeight
        Layout.alignment: Qt.AlignVCenter
    }

    // Separator
    Text {
        visible:        root.hasBattery || KdeConnectState.connected
        text:           "|"
        color:          Theme.text
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight:    Font.DemiBold
        Layout.alignment: Qt.AlignVCenter
    }

    // Battery indicator
    RowLayout {
        visible:          root.hasBattery
        spacing:          4
        Layout.alignment: Qt.AlignVCenter

        Text {
            text:             root.batteryIcon(root.batteryLevel, root.batteryCharging)
            color:            root.batteryColor(root.batteryLevel)
            font.family:      Theme.fontFamily
            font.pixelSize:   Theme.iconSize
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            text:             root.batteryLevel + "%"
            color:            root.batteryColor(root.batteryLevel)
            font.family:      Theme.fontFamily
            font.pixelSize:   Theme.fontSize
            font.weight:      Theme.fontWeight
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Separator between battery and KDE Connect
    Text {
        visible:        root.hasBattery && KdeConnectState.connected
        text:           "|"
        color:          Theme.text
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight:    Font.DemiBold
        Layout.alignment: Qt.AlignVCenter
    }

    // KDE Connect indicator
    Text {
        visible:        KdeConnectState.connected
        text:           "󰄜"
        color:          Theme.text
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.iconSize
        Layout.alignment: Qt.AlignVCenter
        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    root.phoneClicked()
        }
    }

    Text {
        visible:        KdeConnectState.connected
        text:           "|"
        color:          Theme.text
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight:    Font.DemiBold
        Layout.alignment: Qt.AlignVCenter
    }

    // Notifications icon + badge
    Item {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth:  bellIcon.implicitWidth
        implicitHeight: bellIcon.implicitHeight

        Text {
            id:             bellIcon
            text:           NotificationState.dnd ? "󱙝" : "\u{F1942}"
            color:          NotificationState.dnd ? Theme.danger : Theme.text
            font.family:    Theme.fontFamily
            font.pixelSize: Theme.iconSize

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Rectangle {
            visible: root.notifCount > 0
            width:  badgeText.implicitWidth + 5
            height: 14
            radius: 7
            color:  Theme.danger
            anchors { top: bellIcon.top; right: bellIcon.right; rightMargin: -5; topMargin: -2 }
            z: 2

            Text {
                id: badgeText
                anchors.centerIn: parent
                text:  root.notifCount > 9 ? "9+" : root.notifCount + ""
                color: "white"
                font { family: Theme.fontFamily; pixelSize: 8; weight: Font.Bold }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    root.notifClicked()
        }
    }

    // File manager icon
    Text {
        text:           ""
        color:          Theme.text
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.iconSize
        Layout.alignment: Qt.AlignVCenter
        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    root.fileManagerClicked()
        }
    }

    // Settings icon
    Text {
        text:           ""
        color:          Theme.text
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.iconSize
        Layout.alignment: Qt.AlignVCenter
        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    root.controlClicked()
        }
    }

    // Power icon
    Text {
        text:           ""
        color:          Theme.danger
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.iconSize
        Layout.alignment: Qt.AlignVCenter
        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    root.powerClicked()
        }
    }
}