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

    function closeAll() {
        notifVisible = false; controlVisible = false; powerVisible = false
        btPanelVisible = false; phoneVisible = false; settingsVisible = false
        batteryVisible = false
    }

    IpcHandler {
        target: "bar"

        function toggleSettings(): void {
            var opening = !barWindow.settingsVisible
            barWindow.closeAll()
            barWindow.settingsVisible = opening
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
                    var opening = !barWindow.settingsVisible
                    barWindow.closeAll()
                    barWindow.settingsVisible = opening
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
                    var opening = !barWindow.notifVisible
                    barWindow.closeAll()
                    barWindow.notifVisible = opening
                }
                onControlClicked: {
                    var opening = !barWindow.controlVisible
                    barWindow.closeAll()
                    barWindow.controlVisible = opening
                }
                onPowerClicked: {
                    var opening = !barWindow.powerVisible
                    barWindow.closeAll()
                    barWindow.powerVisible = opening
                }
                onPhoneClicked: {
                    var opening = !barWindow.phoneVisible
                    barWindow.closeAll()
                    barWindow.phoneVisible = opening
                }
                onBatteryClicked: {
                    var opening = !barWindow.batteryVisible
                    barWindow.closeAll()
                    barWindow.batteryVisible = opening
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
            onClicked: barWindow.closeAll()
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
