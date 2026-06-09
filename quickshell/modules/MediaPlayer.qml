import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import "../"

Item {
    id: root

    implicitWidth:  mediaRow.implicitWidth
    implicitHeight: mediaRow.implicitHeight

    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    visible: player !== null

    property bool isHovered: false

    RowLayout {
        id:      mediaRow
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text:           "󰝚"
            color:          Theme.text
            font.family:    Theme.fontFamily
            font.pixelSize: Theme.iconSize
        }

        Text {
            property string raw: root.player
                ? ((root.player.trackArtist || "") + " — " + (root.player.trackTitle || ""))
                : ""
            text:           raw.length > 25 ? raw.slice(0, 25) + "…" : raw
            color:          Theme.text
            font.family:    Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight:    Theme.fontWeight
        }
    }

    HoverHandler {
        onHoveredChanged: root.isHovered = hovered
    }
}
