import Quickshell
import Quickshell.Services.Mpris
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
    property bool popupHovered: false

    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property real currentPosition: 0

    onShownChanged: {
        if (shown) {
            animOut.stop()
            contentRect.opacity = 0
            slideTranslate.y    = -10
            root.visible        = true
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

    implicitWidth:  300
    implicitHeight: mainCol.implicitHeight + 24

    anchor.rect.x: Theme.marginSide
    anchor.rect.y: Theme.barHeight + Theme.marginTop + 8

    function formatTime(secs) {
        if (!secs || isNaN(secs) || secs <= 0) return "—"
        var s = Math.floor(secs)
        var m = Math.floor(s / 60)
        var r = s % 60
        return m + ":" + (r < 10 ? "0" + r : r)
    }

    Timer {
        interval: 1000
        repeat:   true
        running:  root.player !== null
        onTriggered: root.currentPosition = root.player ? root.player.position : 0
    }

    Rectangle {
        id:           contentRect
        anchors.fill: parent
        color:        Theme.bgSolid
        radius:       8
        opacity:      0
        transform:    Translate { id: slideTranslate; y: 0 }

        HoverHandler {
            onHoveredChanged: root.popupHovered = hovered
        }

        Column {
            id: mainCol
            anchors {
                top:         parent.top
                left:        parent.left
                right:       parent.right
                topMargin:   16
                leftMargin:  16
                rightMargin: 16
            }
            spacing: 12

            // Cover art + infos + contrôles
            RowLayout {
                width:   parent.width
                spacing: 14

                // Cover art
                Rectangle {
                    width:  90
                    height: 90
                    radius: 6
                    color:  Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.06)
                    clip:   true

                    Image {
                        anchors.fill: parent
                        source:       root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                        fillMode:     Image.PreserveAspectCrop
                        visible:      root.player && root.player.trackArtUrl !== ""
                    }

                    // Fallback icône si pas de cover
                    Text {
                        anchors.centerIn: parent
                        text:             "󰎵"
                        color:            Theme.textDim
                        font.family:      Theme.fontFamily
                        font.pixelSize:   32
                        visible:          !root.player || !root.player.trackArtUrl
                    }
                }

                // Infos + contrôles
                ColumnLayout {
                    Layout.fillWidth:    true
                    Layout.fillHeight:   true
                    spacing:             4

                    // Titre
                    Text {
                        Layout.fillWidth: true
                        text:             root.player ? (root.player.trackTitle || "—") : "—"
                        color:            Theme.text
                        font.family:      Theme.fontFamily
                        font.pixelSize:   Theme.fontSize
                        font.weight:      Font.Bold
                        elide:            Text.ElideRight
                    }

                    // Artiste
                    Text {
                        Layout.fillWidth: true
                        text:             root.player ? (root.player.trackArtist || "") : ""
                        color:            Theme.textDim
                        font.family:      Theme.fontFamily
                        font.pixelSize:   Theme.fontSize - 1
                        font.weight:      Theme.fontWeight
                        elide:            Text.ElideRight
                        visible:          text !== ""
                    }

                    // Album
                    Text {
                        Layout.fillWidth: true
                        text:             root.player ? (root.player.trackAlbum || "") : ""
                        color:            Theme.textDim
                        font.family:      Theme.fontFamily
                        font.pixelSize:   Theme.fontSize - 1
                        elide:            Text.ElideRight
                        visible:          text !== ""
                        opacity:          0.7
                    }

                    Item { Layout.fillHeight: true }

                    // Contrôles prev / play|pause / next
                    RowLayout {
                        spacing: 16

                        Text {
                            text:           ""
                            color:          Theme.text
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.iconSize
                            opacity:        root.player && root.player.canGoPrevious ? 1.0 : 0.4
                            MouseArea {
                                anchors.fill: parent
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    if (root.player) root.player.previous()
                            }
                        }

                        Text {
                            property bool playing: root.player
                                ? root.player.playbackState === MprisPlaybackState.Playing
                                : false
                            text:           playing ? "" : ""
                            color:          Theme.text
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.iconSize + 4
                            MouseArea {
                                anchors.fill: parent
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    if (root.player) root.player.togglePlaying()
                            }
                        }

                        Text {
                            text:           ""
                            color:          Theme.text
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.iconSize
                            opacity:        root.player && root.player.canGoNext ? 1.0 : 0.4
                            MouseArea {
                                anchors.fill: parent
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    if (root.player) root.player.next()
                            }
                        }
                    }
                }
            }

            // Barre de progression + temps
            Column {
                width:   parent.width
                spacing: 5

                // Piste de progression
                Item {
                    width:  parent.width
                    height: 4

                    Rectangle {
                        anchors.fill: parent
                        radius:       2
                        color:        Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.15)
                    }

                    Rectangle {
                        width: {
                            if (!root.player || !root.player.length || root.player.length <= 0) return 0
                            return Math.min(1.0, root.currentPosition / root.player.length) * parent.width
                        }
                        height: parent.height
                        radius: 2
                        color:  Theme.text
                    }
                }

                // Temps écoulé / durée totale
                RowLayout {
                    width: parent.width

                    Text {
                        text:           root.formatTime(root.currentPosition)
                        color:          Theme.textDim
                        font.family:    Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text:           root.player ? root.formatTime(root.player.length) : "0:00"
                        color:          Theme.textDim
                        font.family:    Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }
        }
    }
}
