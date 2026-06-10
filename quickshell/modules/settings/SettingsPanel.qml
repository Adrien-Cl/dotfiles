import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../../"

PanelWindow {
    id: root

    required property PanelWindow bar
    signal closeRequested()

    screen: bar.screen

    color:        "transparent"
    exclusiveZone: 0
    WlrLayershell.namespace:    "quickshell"
    WlrLayershell.layer:        WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrLayershell.None

    anchors { top: true; left: true }
    margins.top:  Theme.marginTop * 2 + Theme.barHeight + 8
    margins.left: Theme.marginSide + Math.max(0, Math.round((bar.width - 880) / 2))

    visible: false

    property bool shown: false
    property int currentPage: 0

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

    implicitWidth:  880
    implicitHeight: 580

    Rectangle {
        id: contentRect
        anchors.fill: parent
        color: Theme.bgBlur
        radius: 8
        opacity: 0
        clip: true
        transform: Translate { id: slideTranslate; y: 0 }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // === SIDEBAR ===
            Rectangle {
                Layout.preferredWidth: 180
                Layout.fillHeight: true
                color: Qt.rgba(1, 1, 1, 0.03)

                Column {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        topMargin: 16
                    }
                    spacing: 2

                    Text {
                        text: "PARAMÈTRES"
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        leftPadding: 16
                        bottomPadding: 8
                        opacity: 0.7
                    }

                    Repeater {
                        model: [
                            { icon: "󰤨", label: "Réseau"       },
                            { icon: "󰂯", label: "Bluetooth"    },
                            { icon: "󰕾", label: "Son"          },
                            { icon: "󰍹", label: "Affichage"    },
                            { icon: "󰏘", label: "Apparence"    },
                            { icon: "󰏖", label: "Applications" },
                            { icon: "󰂄", label: "Alimentation" },
                            { icon: "󰋊", label: "Système"      }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            property bool navHovered: false

                            width: parent.width
                            height: 36
                            radius: 6
                            color: root.currentPage === index
                                   ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.10)
                                   : navHovered
                                     ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.05)
                                     : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Rectangle {
                                visible: root.currentPage === index
                                width: 3; height: 18; radius: 2
                                color: Theme.text
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 14; rightMargin: 8 }
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    color: root.currentPage === index ? Theme.text : Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.iconSize
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                                Text {
                                    text: modelData.label
                                    color: root.currentPage === index ? Theme.text : Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.weight: Theme.fontWeight
                                    Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.navHovered = true
                                onExited: parent.navHovered = false
                                onClicked: root.currentPage = index
                            }
                        }
                    }
                }

                // Close button at bottom
                Rectangle {
                    anchors {
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                        bottomMargin: 14
                    }
                    width: 68; height: 24; radius: 4
                    color: closeArea.containsMouse
                           ? Qt.rgba(0xF9/255, 0x65/255, 0x65/255, 0.15)
                           : Qt.rgba(1, 1, 1, 0.05)
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕  Fermer"
                        color: closeArea.containsMouse ? Theme.danger : Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Theme.fontWeight
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.closeRequested()
                    }
                }
            }

            // === SEPARATOR ===
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Theme.separator
            }

            // === CONTENT AREA ===
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    source: {
                        var pages = [
                            Qt.resolvedUrl("SettingsPageReseau.qml"),
                            Qt.resolvedUrl("SettingsPageBluetooth.qml"),
                            Qt.resolvedUrl("SettingsPageSon.qml"),
                            Qt.resolvedUrl("SettingsPageAffichage.qml"),
                            Qt.resolvedUrl("SettingsPageApparence.qml"),
                            Qt.resolvedUrl("SettingsPageApplications.qml"),
                            Qt.resolvedUrl("SettingsPageAlimentation.qml"),
                            Qt.resolvedUrl("SettingsPageSysteme.qml")
                        ]
                        return pages[root.currentPage] || ""
                    }
                }
            }
        }
    }
}
