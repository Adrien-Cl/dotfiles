import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../"

PanelWindow {
    id: root

    required property PanelWindow bar

    screen: bar.screen

    anchors { top: true; right: true }
    margins {
        top:   Theme.marginTop
        right: Theme.marginSide
    }

    implicitWidth:  240
    implicitHeight: 44

    color:   "transparent"
    visible: false

    WlrLayershell.namespace:     "quickshell-osd"
    WlrLayershell.layer:         WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrLayershell.None

    // ── état affiché ─────────────────────────────────────────────────────
    property string osdType:  "volume"
    property real   osdValue: 0
    property bool   osdMuted: false

    // ── suivi volume (polling wpctl) ─────────────────────────────────────
    property real volLast:  -1
    property bool muteLast: false

    Process {
        id: procVolumeGet
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var isMuted = data.indexOf("[MUTED]") >= 0
                var m = data.match(/Volume:\s+([0-9.]+)/)
                if (!m) return
                var v = parseFloat(m[1])
                if (isNaN(v)) return
                var valueChanged = root.volLast >= 0 && Math.abs(v - root.volLast) > 0.005
                var muteChanged  = root.volLast >= 0 && isMuted !== root.muteLast
                if (valueChanged || muteChanged) {
                    root.osdType  = "volume"
                    root.osdValue = Math.min(1.0, v)
                    root.osdMuted = isMuted
                    root.showOSD()
                }
                root.volLast  = v
                root.muteLast = isMuted
            }
        }
    }

    Timer {
        id: volumePoller
        interval: 150
        repeat:   true
        running:  true
        onTriggered: {
            if (!procVolumeGet.running)
                procVolumeGet.running = true
        }
    }

    // ── suivi luminosité (polling brightnessctl) ──────────────────────────
    property real brightMax:  255
    property real brightCur:  0
    property real brightLast: -1

    Process {
        id: procBrightnessMax
        command: ["brightnessctl", "m"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var v = parseInt(data.trim())
                if (!isNaN(v) && v > 0) root.brightMax = v
            }
        }
    }

    Process {
        id: procBrightnessGet
        command: ["brightnessctl", "g"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var v = parseInt(data.trim())
                if (isNaN(v)) return
                if (root.brightLast >= 0 && v !== root.brightLast) {
                    root.brightCur = v
                    root.osdType   = "brightness"
                    root.osdValue  = v / root.brightMax
                    root.osdMuted  = false
                    root.showOSD()
                }
                root.brightLast = v
                root.brightCur  = v
            }
        }
    }

    Timer {
        id: brightnessPoller
        interval: 300
        repeat:   true
        running:  true
        onTriggered: {
            if (!procBrightnessGet.running)
                procBrightnessGet.running = true
        }
    }

    // ── dismiss ──────────────────────────────────────────────────────────
    Timer {
        id: dismissTimer
        interval: 2000
        onTriggered: animOut.start()
    }

    ParallelAnimation {
        id: animIn
        NumberAnimation { target: osdRect; property: "opacity"; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: osdSlide; property: "y"; to: 0; duration: 200; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: animOut
        NumberAnimation { target: osdRect; property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
        NumberAnimation { target: osdSlide; property: "y"; to: -10; duration: 150; easing.type: Easing.InCubic }
        onFinished: root.visible = false
    }

    function showOSD() {
        if (animOut.running) {
            animOut.stop()
            animIn.start()
        } else if (!visible) {
            osdRect.opacity = 0
            osdSlide.y = -10
            visible = true
            animIn.start()
        }
        dismissTimer.restart()
    }

    // ── visuel ────────────────────────────────────────────────────────────
    Rectangle {
        id:           osdRect
        anchors.fill: parent
        color:        Theme.bgSolid
        radius:       8
        opacity:      0
        transform:    Translate { id: osdSlide; y: 0 }

        RowLayout {
            anchors {
                fill:        parent
                leftMargin:  14
                rightMargin: 14
            }
            spacing: 10

            Text {
                text: {
                    if (root.osdType === "brightness") {
                        if (root.osdValue < 0.34) return "󰃞"
                        if (root.osdValue < 0.67) return "󰃝"
                        return "󰃠"
                    }
                    if (root.osdMuted || root.osdValue <= 0) return "󰝟"
                    if (root.osdValue < 0.34) return "󰕿"
                    if (root.osdValue < 0.67) return "󰖀"
                    return "󰕾"
                }
                color:          (root.osdType === "volume" && root.osdMuted) ? Theme.danger : Theme.text
                font.family:    Theme.fontFamily
                font.pixelSize: Theme.iconSize
            }

            Item {
                Layout.fillWidth: true
                height: 4

                Rectangle {
                    anchors.fill: parent
                    radius:       2
                    color:        Theme.textDim

                    Rectangle {
                        width:  parent.width * root.osdValue
                        height: parent.height
                        radius: parent.radius
                        color:  (root.osdType === "volume" && root.osdMuted) ? Theme.danger : Theme.text
                        Behavior on width { NumberAnimation { duration: 100 } }
                    }
                }
            }

            Text {
                text:                  root.osdMuted ? "muet" : Math.round(root.osdValue * 100) + "%"
                color:                 Theme.textDim
                font.family:           Theme.fontFamily
                font.pixelSize:        Theme.fontSize
                font.weight:           Theme.fontWeight
                Layout.preferredWidth: 36
                horizontalAlignment:   Text.AlignRight
            }
        }
    }
}
