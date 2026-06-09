import Quickshell
import QtQuick
import QtQuick.Layouts
import "../"

RowLayout {
    id: root
    spacing: Theme.spacing

    signal aiChatRequested()
    signal mediaHoverStarted()
    signal mediaHoverStopped()

    // AI star icon
    Text {
        text:           ""
        color:          Theme.aiIcon
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.iconSize
        font.weight:    Font.Bold
        Layout.alignment: Qt.AlignVCenter
        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    root.aiChatRequested()
        }
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

    // Arch Linux icon
    Text {
        text:           ""
        color:          Theme.text
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.iconSize
        Layout.alignment: Qt.AlignVCenter
    }

    // Separator (hidden when no media player)
    Text {
        text:           "|"
        color:          Theme.text
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight:    Font.DemiBold
        Layout.alignment: Qt.AlignVCenter
        visible:        mediaPlayer.visible
    }

    // Media player
    MediaPlayer {
        id: mediaPlayer
        Layout.alignment: Qt.AlignVCenter
        onIsHoveredChanged: isHovered ? root.mediaHoverStarted() : root.mediaHoverStopped()
    }
}
