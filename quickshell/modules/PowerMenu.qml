import Quickshell
import Quickshell.Io
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

    implicitWidth:  175
    implicitHeight: menuCol.implicitHeight + 16

    anchor.rect.x: bar.width - implicitWidth
    anchor.rect.y: Theme.barHeight + Theme.marginTop + 4

    Rectangle {
        id:           contentRect
        anchors.fill: parent
        color:        Theme.bgSolid
        radius:       8
        opacity:      0
        transform:    Translate { id: slideTranslate; y: 0 }

        Column {
            id: menuCol
            anchors {
                top:        parent.top
                left:       parent.left
                right:      parent.right
                topMargin:  8
                leftMargin: 8
                rightMargin: 8
            }
            spacing: 0

            Repeater {
                model: [
                    { icon: "󰒲", label: "Veille",       cmd: ["bash", "-c", "hyprlock & sleep 0.5 && systemctl suspend"], danger: false },
                    { icon: "󰍃", label: "Déconnexion",  cmd: ["hyprctl", "dispatch", "exit"],                            danger: false  },
                    { icon: "󰑓", label: "Redémarrer",   cmd: ["systemctl", "reboot"],                                    danger: false  },
                    { icon: "󰐥", label: "Éteindre",     cmd: ["systemctl", "poweroff"],                                  danger: true  }
                ]

                delegate: Rectangle {
                    required property var modelData

                    width:  parent.width
                    height: 36
                    color:  hovered ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.07) : "transparent"
                    radius: 6

                    property bool hovered: false

                    RowLayout {
                        anchors {
                            fill:            parent
                            leftMargin:      10
                            rightMargin:     10
                        }
                        spacing: 8

                        Text {
                            text:           modelData.icon
                            color:          modelData.danger ? Theme.danger : Theme.text
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.iconSize
                        }

                        Text {
                            text:           modelData.label
                            color:          modelData.danger ? Theme.danger : Theme.text
                            font.family:    Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight:    Theme.fontWeight
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered:    parent.hovered = true
                        onExited:     parent.hovered = false
                        onClicked: {
                            root.closeRequested()
                            Quickshell.execDetached(modelData.cmd)
                        }
                    }
                }
            }
        }
    }
}
