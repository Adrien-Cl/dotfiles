import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../"

RowLayout {
    spacing: 0

    // Workspaces 1–9
    Repeater {
        model: 9
        delegate: Item {
            property int wsId:    modelData + 1
            property bool active: Hyprland.focusedWorkspace
                                  ? Hyprland.focusedWorkspace.id === wsId
                                  : false

            implicitWidth:  Theme.barHeight
            implicitHeight: Theme.barHeight

            // Background + bottom border en un seul rectangle
            Rectangle {
                anchors.fill:      parent
                visible:           active
                topLeftRadius:     wsId === 1 ? 8 : 0
                bottomLeftRadius:  wsId === 1 ? 8 : 0
                topRightRadius:    0
                bottomRightRadius: 0

                gradient: Gradient {
                    GradientStop { position: 0.0;                                              color: Theme.bgSolid }
                    GradientStop { position: (Theme.barHeight - 2) / Theme.barHeight - 0.001;  color: Theme.bgSolid }
                    GradientStop { position: (Theme.barHeight - 2) / Theme.barHeight;          color: Theme.text    }
                    GradientStop { position: 1.0;                                              color: Theme.text    }
                }
            }

            Text {
                anchors.centerIn: parent
                text:            wsId
                color:           active ? Theme.text : Theme.textDim
                font.family:     Theme.fontFamily
                font.pixelSize:  Theme.fontSize
                font.weight:     active ? Font.Bold : Font.Normal
            }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    Hyprland.dispatch("hl.dsp.focus({workspace=" + wsId + "})")
            }
        }
    }

    // Separator
    Text {
        text:           "|"
        color:          Theme.text
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight:    Font.DemiBold
    }

    // Active window title
    Text {
        property string raw: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
        text:           raw.length > 15 ? raw.slice(0, 15) + "…" : raw
        color:          Theme.text
        font.family:    Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight:    Theme.fontWeight
        Layout.maximumWidth: 120
        Layout.leftMargin:   Theme.spacing
        elide: Text.ElideRight
    }
}
