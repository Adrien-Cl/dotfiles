pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool   connected:    false
    property string deviceId:     ""
    property string deviceName:   ""
    property int    batteryLevel: 0
    property bool   charging:     false

    property bool _foundDevice:        false
    property bool _initialPoll:        true
    property bool _batteryLowNotified: false

    // — Poll toutes les 10s —
    Timer {
        interval: 10000
        running:  true
        repeat:   true
        triggeredOnStart: true
        onTriggered: if (!procList.running) procList.running = true
    }

    Process {
        id: procList
        command: ["kdeconnect-cli", "-l"]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                // Format: "- Name: deviceId on IP via LAN (associé et joignable)"
                // Accepts French and English locale, ignores extra network info
                var m = data.match(/^-\s+(.+):\s+([a-f0-9]{8,})/)
                var reachable = data.indexOf("joignable") >= 0 || data.indexOf("reachable") >= 0
                if (m && reachable) {
                    root._foundDevice = true
                    root.deviceName   = m[1].trim()
                    root.deviceId     = m[2].trim()
                }
            }
        }

        onRunningChanged: {
            if (running) {
                root._foundDevice = false
                return
            }
            var wasConn    = root.connected
            root.connected = root._foundDevice

            if (!root._initialPoll) {
                if (root.connected && !wasConn)
                    procNotifyConnect.running = true
                else if (!root.connected && wasConn)
                    procNotifyDisconnect.running = true
            }
            root._initialPoll = false

            if (root.connected) {
                procBattery.running = true
            } else {
                root.deviceId    = ""
                root.deviceName  = ""
                root.batteryLevel = 0
                root.charging    = false
            }
        }
    }

    Process {
        id: procBattery
        command: ["bash", "-c",
            "gdbus call --session --dest org.kde.kdeconnect" +
            " --object-path /modules/kdeconnect/devices/" + root.deviceId + "/battery" +
            " --method org.freedesktop.DBus.Properties.GetAll org.kde.kdeconnect.device.battery 2>/dev/null"]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var mCharge = data.match(/'charge':\s*<(\d+)>/)
                if (!mCharge) return
                var level = parseInt(mCharge[1])
                if (isNaN(level)) return
                root.batteryLevel = level
                root.charging = data.indexOf("'isCharging': <true>") >= 0

                if (level <= 15 && !root.charging && !root._batteryLowNotified) {
                    root._batteryLowNotified = true
                    procNotifyLowBatt.command = [
                        "notify-send", "-u", "critical", "-i", "battery-caution",
                        "KDE Connect", "Batterie faible (" + level + "%)"
                    ]
                    procNotifyLowBatt.running = true
                } else if (level > 20) {
                    root._batteryLowNotified = false
                }
            }
        }
    }

    Process {
        id: procNotifyConnect
        command: ["notify-send", "-i", "phone", "KDE Connect", "Téléphone connecté"]
        running: false
    }

    Process {
        id: procNotifyDisconnect
        command: ["notify-send", "-i", "phone", "KDE Connect", "Téléphone déconnecté"]
        running: false
    }

    Process {
        id: procNotifyLowBatt
        running: false
    }
}
