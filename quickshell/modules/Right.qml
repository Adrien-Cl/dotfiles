import Quickshell
import QtQuick
import QtQuick.Layouts
import "../"

RowLayout {
    id: root
    spacing: Theme.spacing

    property int notifCount: 0

    signal notifClicked()
    signal controlClicked()
    signal powerClicked()
    signal phoneClicked()
    signal fileManagerClicked()

    function batteryIcon(level, chg) {
        if (chg) return "󰂈"
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
        if (level <= 30) return "#FFA500"
        return "#4CAF50"
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
            text:           "\u{F1942}"
            color:          Theme.text
            font.family:    Theme.fontFamily
            font.pixelSize: Theme.iconSize
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