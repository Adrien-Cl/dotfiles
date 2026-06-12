import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import "."
import "modules/"
import "modules/settings/"

PanelWindow {
    id: barWindow

    required property ShellScreen screen
    required property NotificationServer notificationServer

    anchors { top: true; left: true; right: true }
    margins { top: Theme.marginTop; left: Theme.marginSide; right: Theme.marginSide }

    implicitHeight: Theme.barHeight
    exclusiveZone:  Theme.barHeight + Theme.marginTop

    color: "transparent"
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayershell.Top
    WlrLayershell.keyboardFocus: WlrLayershell.None

    property bool notifVisible:    false
    property bool controlVisible:  false
    property bool powerVisible:    false
    property bool btPanelVisible:  false
    property bool phoneVisible:    false
    property bool mediaVisible:    false
    property bool settingsVisible: false
    property bool batteryVisible:  false

    IpcHandler {
        target: "bar"

        function toggleSettings(): void {
            barWindow.settingsVisible = !barWindow.settingsVisible
            barWindow.notifVisible    = false
            barWindow.controlVisible  = false
            barWindow.powerVisible    = false
            barWindow.btPanelVisible  = false
            barWindow.phoneVisible    = false
            barWindow.batteryVisible  = false
        }
    }

    Timer {
        id: mediaHideTimer
        interval: 250
        onTriggered: barWindow.mediaVisible = false
    }

    Item {
        anchors.fill: parent

        Rectangle {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            height: Theme.barHeight
            radius: 8
            color:  Theme.bgOpaque
            width:  leftModule.implicitWidth + 32

            Left {
                id: leftModule
                anchors.centerIn: parent
                onAiChatRequested:  console.log("AI chat requested")
                onMediaHoverStarted: {
                    mediaHideTimer.stop()
                    barWindow.mediaVisible = true
                }
                onMediaHoverStopped: {
                    mediaHideTimer.restart()
                }
                onSettingsRequested: {
                    barWindow.settingsVisible  = !barWindow.settingsVisible
                    barWindow.notifVisible     = false
                    barWindow.controlVisible   = false
                    barWindow.powerVisible     = false
                    barWindow.btPanelVisible   = false
                    barWindow.phoneVisible     = false
                }
            }
        }

        Rectangle {
            anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
            height: Theme.barHeight
            radius: 8
            color:  Theme.bgOpaque
            width:  centerModule.implicitWidth + 16

            Center {
                id: centerModule
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            }
        }

        Rectangle {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            height: Theme.barHeight
            radius: 8
            color:  Theme.bgOpaque
            width:  rightModule.implicitWidth + 32

            Right {
                id: rightModule
                anchors.centerIn: parent
                notifCount: barWindow.notificationServer.trackedNotifications.values.length
                onNotifClicked: {
                    barWindow.notifVisible    = !barWindow.notifVisible
                    barWindow.controlVisible  = false
                    barWindow.powerVisible    = false
                    barWindow.batteryVisible  = false
                    barWindow.settingsVisible = false
                }
                onControlClicked: {
                    barWindow.controlVisible  = !barWindow.controlVisible
                    barWindow.notifVisible    = false
                    barWindow.powerVisible    = false
                    barWindow.batteryVisible  = false
                    barWindow.settingsVisible = false
                }
                onPowerClicked: {
                    barWindow.powerVisible    = !barWindow.powerVisible
                    barWindow.notifVisible    = false
                    barWindow.controlVisible  = false
                    barWindow.batteryVisible  = false
                    barWindow.settingsVisible = false
                }
                onPhoneClicked: {
                    barWindow.phoneVisible    = !barWindow.phoneVisible
                    barWindow.notifVisible    = false
                    barWindow.controlVisible  = false
                    barWindow.powerVisible    = false
                    barWindow.batteryVisible  = false
                    barWindow.settingsVisible = false
                }
                onBatteryClicked: {
                    barWindow.batteryVisible  = !barWindow.batteryVisible
                    barWindow.notifVisible    = false
                    barWindow.controlVisible  = false
                    barWindow.powerVisible    = false
                    barWindow.phoneVisible    = false
                    barWindow.settingsVisible = false
                }
                onFileManagerClicked: Quickshell.execDetached(["thunar"])
            }
        }
    }

    // Backdrop plein écran qui ferme les popups au clic extérieur
    PanelWindow {
        id: backdrop
        screen: barWindow.screen
        visible: barWindow.notifVisible || barWindow.controlVisible || barWindow.powerVisible || barWindow.btPanelVisible || barWindow.phoneVisible || barWindow.settingsVisible || barWindow.batteryVisible

        anchors { top: true; bottom: true; left: true; right: true }

        color: "transparent"
        WlrLayershell.namespace: "quickshell-backdrop"
        WlrLayershell.layer: WlrLayershell.Top
        WlrLayershell.keyboardFocus: WlrLayershell.None

        MouseArea {
            anchors.fill: parent
            onClicked: {
                barWindow.notifVisible    = false
                barWindow.controlVisible  = false
                barWindow.powerVisible    = false
                barWindow.btPanelVisible  = false
                barWindow.phoneVisible    = false
                barWindow.settingsVisible = false
                barWindow.batteryVisible  = false
            }
        }
    }

    MediaPopup {
        shown: barWindow.mediaVisible
        bar:   barWindow
        onPopupHoveredChanged: {
            if (popupHovered) mediaHideTimer.stop()
            else mediaHideTimer.restart()
        }
        onCloseRequested: barWindow.mediaVisible = false
    }

    Notifications {
        shown:  barWindow.notifVisible
        server: barWindow.notificationServer
        bar:    barWindow
        onCloseRequested: barWindow.notifVisible = false
    }

    ControlPanel {
        shown: barWindow.controlVisible
        bar:   barWindow
        onCloseRequested:      barWindow.controlVisible = false
        onBtSettingsRequested: {
            barWindow.controlVisible = false
            barWindow.btPanelVisible = true
        }
    }

    BluetoothPanel {
        shown: barWindow.btPanelVisible
        bar:   barWindow
        onCloseRequested: barWindow.btPanelVisible = false
        onBackRequested: {
            barWindow.btPanelVisible = false
            barWindow.controlVisible = true
        }
    }

    KdeConnectPanel {
        shown: barWindow.phoneVisible
        bar:   barWindow
        onCloseRequested: barWindow.phoneVisible = false
    }

    PowerMenu {
        shown: barWindow.powerVisible
        bar:   barWindow
        onCloseRequested: barWindow.powerVisible = false
    }

    BatteryPopup {
        shown: barWindow.batteryVisible
        bar:   barWindow
        onCloseRequested: barWindow.batteryVisible = false
    }

    SettingsPanel {
        shown: barWindow.settingsVisible
        bar:   barWindow
        onCloseRequested: barWindow.settingsVisible = false
    }

    OSD {
        bar: barWindow
    }

    NotificationToasts {
        bar: barWindow
    }

}
