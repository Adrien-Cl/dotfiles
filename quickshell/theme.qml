pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property color bg:          "#01010F"
    readonly property color bgOpaque:    Qt.rgba(0x01/255, 0x01/255, 0x0F/255, 0.9)
    readonly property color bgSolid:     Qt.rgba(0x01/255, 0x01/255, 0x0F/255, 1.0)
    readonly property color text:        "#C8D1E9"
    readonly property color textDim:     Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.5)
    readonly property color aiIcon:      "#DDAC26"
    readonly property color danger:      "#F96565"
    readonly property color separator:   Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.25)

    readonly property int barHeight:     32
    readonly property int marginTop:     8
    readonly property int marginSide:    8
    readonly property int fontSize:      12
    readonly property int iconSize:      16
    readonly property int spacing:       12

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontWeight:    Font.DemiBold
}
