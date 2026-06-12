import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../"

PopupWindow {
    id: root

    required property NotificationServer server
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

    implicitWidth:  340
    implicitHeight: {
        var count = root.server.trackedNotifications.values.length
        if (count === 0) return panelHeader.implicitHeight + 14 + (NotificationState.dnd ? 110 : 90)
        return Math.min(panelHeader.implicitHeight + 18 + notifList.contentHeight + 28, 520)
    }

    anchor.rect.x: bar.width - implicitWidth
    anchor.rect.y: Theme.barHeight + Theme.marginTop + 4

    function _accentColor(appName, urgency) {
        var n = (appName || "").toLowerCase()
        if (n.indexOf("kdeconnect") >= 0) return "#A78BFA"
        if (["spotify","vlc","rhythmbox","elisa","clementine","audacious","mpd"].indexOf(n) >= 0) return Theme.success
        if ((urgency || 1) >= 2) return "#F96565"
        return Theme.separator
    }

    function _invokeDefault(notif) {
        if (!notif) return false
        var acts = notif.actions
        if (!acts || acts.length === 0) return false
        for (var i = 0; i < acts.length; i++) {
            if (acts[i].identifier === "default") { acts[i].invoke(); return true }
        }
        acts[0].invoke()
        return true
    }

    function _openApp(appIcon, appName) {
        var id = appIcon || ""
        if (id !== "") { Quickshell.execDetached(["gtk-launch", id]); return }
        var name = (appName || "").toLowerCase().replace(/ /g, "-")
        if (name !== "") Quickshell.execDetached(["gtk-launch", name])
    }

    function _visibleActions(notif) {
        if (!notif || !notif.actions) return []
        return notif.actions.filter(function(a) {
            return a.text && a.text.length > 0 && a.identifier !== "default"
        })
    }

    Rectangle {
        id:           contentRect
        anchors.fill: parent
        color:        Theme.bgSolid
        radius:       8
        opacity:      0
        transform:    Translate { id: slideTranslate; y: 0 }

        // ── En-tête (fixe) ────────────────────────────────────────────────
        Column {
            id: panelHeader
            anchors {
                top:         parent.top
                left:        parent.left
                right:       parent.right
                topMargin:   14
                leftMargin:  14
                rightMargin: 14
            }
            spacing: 10

            RowLayout {
                width:  parent.width
                height: 20

                Text {
                    text:  "Notifications"
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: Theme.fontSize; weight: Font.DemiBold }
                }

                // Badge compteur
                Rectangle {
                    visible: root.server.trackedNotifications.values.length > 0
                    width:   countText.implicitWidth + 8
                    height:  16
                    radius:  8
                    color:   Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.15)

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text:  root.server.trackedNotifications.values.length + ""
                        color: Theme.textDim
                        font { family: Theme.fontFamily; pixelSize: Theme.fontSize - 3; weight: Font.Medium }
                    }
                }

                Item { Layout.fillWidth: true }

                // Bouton DND
                Text {
                    id:    dndBtn
                    text:  NotificationState.dnd ? "󱙜" : "󱙝"
                    color: NotificationState.dnd ? "#A78BFA" : Theme.textDim
                    font { family: Theme.fontFamily; pixelSize: Theme.fontSize + 1 }
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered:    if (!NotificationState.dnd) dndBtn.color = Theme.text
                        onExited:     dndBtn.color = NotificationState.dnd ? "#A78BFA" : Theme.textDim
                        onClicked:    NotificationState.dnd = !NotificationState.dnd
                    }
                }

                Text {
                    id:      clearAllBtn
                    visible: root.server.trackedNotifications.values.length > 0
                    text:    "Tout effacer"
                    color:   Theme.textDim
                    font { family: Theme.fontFamily; pixelSize: Theme.fontSize - 1 }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered:    clearAllBtn.color = Theme.text
                        onExited:     clearAllBtn.color = Theme.textDim
                        onClicked: {
                            var all = root.server.trackedNotifications.values.slice()
                            all.forEach(function(n) { n.dismiss() })
                        }
                    }
                }
            }

            Rectangle {
                width:   parent.width
                height:  1
                color:   Theme.separator
                visible: root.server.trackedNotifications.values.length > 0
            }
        }

        // ── État vide ─────────────────────────────────────────────────────
        Item {
            anchors {
                top:    panelHeader.bottom
                left:   parent.left
                right:  parent.right
                bottom: parent.bottom
            }
            visible: root.server.trackedNotifications.values.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:  NotificationState.dnd ? "󱙝" : "\u{F1942}"
                    color: NotificationState.dnd ? "#A78BFA" : Theme.textDim
                    font { family: Theme.fontFamily; pixelSize: 28 }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:  "Aucune notification"
                    color: Theme.textDim
                    font { family: Theme.fontFamily; pixelSize: Theme.fontSize }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: NotificationState.dnd
                    text:    "Mode silencieux actif"
                    color:   Qt.rgba(0xA7/255, 0x8B/255, 0xFA/255, 0.7)
                    font { family: Theme.fontFamily; pixelSize: Theme.fontSize - 2 }
                }
            }
        }

        // ── Liste scrollable ──────────────────────────────────────────────
        ScrollView {
            id: scrollArea
            anchors {
                top:         panelHeader.bottom
                left:        parent.left
                right:       parent.right
                bottom:      parent.bottom
                topMargin:   4
                leftMargin:  14
                rightMargin: 14
                bottomMargin: 14
            }
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            visible: root.server.trackedNotifications.values.length > 0

            ListView {
                id:      notifList
                width:   scrollArea.width
                spacing: 8
                model:   root.server.trackedNotifications

                delegate: Rectangle {
                    id: notifCard
                    required property var modelData

                    property color accentColor: root._accentColor(modelData.appName, modelData.urgency)
                    property var   visActions:  root._visibleActions(modelData)

                    width:  notifList.width
                    height: notifRow.implicitHeight + 20 + (visActions.length > 0 ? actionRowNotif.implicitHeight + 8 : 0)
                    radius: 8
                    color:  cardHover.containsMouse
                            ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.08)
                            : Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.04)

                    Behavior on color { ColorAnimation { duration: 120 } }

                    // Bordure
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border { color: Theme.separator; width: 1 }
                        z: 2
                    }

                    // Bande d'accent à gauche
                    Rectangle {
                        anchors {
                            top: parent.top; bottom: parent.bottom; left: parent.left
                            topMargin: 1; bottomMargin: 1; leftMargin: 1
                        }
                        width: 3; radius: 7
                        color: notifCard.accentColor
                        z: 3
                    }

                    // Hover détection (ne consomme pas les clics)
                    MouseArea {
                        id: cardHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }

                    // Clic corps → action par défaut ou ouverture de l'app
                    MouseArea {
                        anchors { fill: parent; rightMargin: 36 }
                        cursorShape: Qt.PointingHandCursor
                        z: 1
                        onClicked: {
                            var invoked = root._invokeDefault(notifCard.modelData)
                            if (!invoked)
                                root._openApp(notifCard.modelData.appIcon, notifCard.modelData.appName)
                        }
                    }

                    Column {
                        anchors {
                            top: parent.top; left: parent.left; right: parent.right
                            topMargin: 10; leftMargin: 16; rightMargin: 10; bottomMargin: 10
                        }
                        spacing: 0

                        RowLayout {
                            id: notifRow
                            width: parent.width
                            spacing: 14

                            // Icône app
                            Item {
                                width:  notifAppNameText.implicitHeight + 2 + notifSummaryText.implicitHeight
                                height: notifAppNameText.implicitHeight + 2 + notifSummaryText.implicitHeight
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    id: iconRect
                                    anchors.fill: parent
                                    radius: 6
                                    color:  Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.06)

                                    Text {
                                        anchors.centerIn: parent
                                        text:    (notifCard.modelData.appName || "?").charAt(0).toUpperCase()
                                        color:   Theme.text
                                        font { family: Theme.fontFamily; pixelSize: Math.round(iconRect.height * 0.45); weight: Font.Bold }
                                        visible: notifIconImg.status !== Image.Ready && notifIconImgFb.status !== Image.Ready
                                    }

                                    Image {
                                        id: notifIconImg
                                        anchors {
                                            fill: parent
                                            margins: notifCard.modelData.image ? 0 : Math.round(iconRect.height * 0.18)
                                        }
                                        source: notifCard.modelData.image
                                                    ? notifCard.modelData.image
                                                    : (notifCard.modelData.appIcon ? "image://icon/" + notifCard.modelData.appIcon : "")
                                        fillMode: notifCard.modelData.image ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                                        smooth: true
                                        visible: status === Image.Ready
                                    }

                                    Image {
                                        id: notifIconImgFb
                                        anchors { fill: parent; margins: Math.round(iconRect.height * 0.18) }
                                        source: notifIconImg.status !== Image.Ready && notifCard.modelData.appIcon
                                                    ? "image://icon/" + notifCard.modelData.appIcon.toLowerCase()
                                                    : ""
                                        fillMode: Image.PreserveAspectFit
                                        smooth:   true
                                        visible:  status === Image.Ready
                                    }
                                }

                                // Badge téléphone
                                Rectangle {
                                    visible: (notifCard.modelData.appName || "").toLowerCase().indexOf("kdeconnect") >= 0
                                    anchors { bottom: parent.bottom; right: parent.right; bottomMargin: -2; rightMargin: -2 }
                                    width: 14; height: 14; radius: 7
                                    color: "#A78BFA"
                                    z: 4

                                    Text {
                                        anchors.centerIn: parent
                                        text:  "󰄜"
                                        color: "white"
                                        font { family: Theme.fontFamily; pixelSize: 8 }
                                    }
                                }
                            }

                            // Textes
                            Column {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    width:   parent.width
                                    spacing: 4
                                    visible: (notifCard.modelData.appName || "").length > 0

                                    Text {
                                        id: notifAppNameText
                                        Layout.fillWidth: true
                                        text:  notifCard.modelData.appName || ""
                                        color: Theme.textDim
                                        font { family: Theme.fontFamily; pixelSize: Theme.fontSize - 2; weight: Font.Medium }
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text:  NotificationState.getRelativeTime(notifCard.modelData.id)
                                        color: Theme.textDim
                                        font { family: Theme.fontFamily; pixelSize: Theme.fontSize - 3 }
                                        Layout.alignment: Qt.AlignVCenter
                                        opacity: 0.7
                                    }
                                }

                                Text {
                                    id: notifSummaryText
                                    width:  parent.width
                                    text:   notifCard.modelData.summary || ""
                                    color:  Theme.text
                                    font { family: Theme.fontFamily; pixelSize: Theme.fontSize; weight: Font.DemiBold }
                                    elide:  Text.ElideRight
                                }

                                Text {
                                    visible:          (notifCard.modelData.body || "").length > 0
                                    width:            parent.width
                                    text:             notifCard.modelData.body || ""
                                    color:            Theme.textDim
                                    font { family: Theme.fontFamily; pixelSize: Theme.fontSize - 1 }
                                    elide:            Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode:         Text.WordWrap
                                }
                            }

                            // Bouton dismiss
                            Text {
                                id: dismissBtn
                                text:  "✕"
                                color: Theme.danger
                                font { family: Theme.fontFamily; pixelSize: 16 }
                                Layout.alignment: Qt.AlignVCenter
                                opacity: 0.7

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape:  Qt.PointingHandCursor
                                    hoverEnabled: true
                                    z: 5
                                    onEntered: dismissBtn.opacity = 1.0
                                    onExited:  dismissBtn.opacity = 0.7
                                    onClicked: notifCard.modelData.dismiss()
                                }
                            }
                        }

                        // ── Boutons d'actions ─────────────────────────────
                        Item {
                            visible: notifCard.visActions.length > 0
                            width:   parent.width
                            height:  visible ? actionRowNotif.implicitHeight + 8 : 0

                            Row {
                                id: actionRowNotif
                                anchors { top: parent.top; left: parent.left; topMargin: 8; leftMargin: 42 }
                                spacing: 6

                                Repeater {
                                    model: notifCard.visActions

                                    delegate: Rectangle {
                                        required property var modelData
                                        required property int index

                                        height: 24
                                        width:  actLabel.implicitWidth + 16
                                        radius: 4
                                        color:  actMa.containsMouse
                                                ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.18)
                                                : Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.08)

                                        Behavior on color { ColorAnimation { duration: 100 } }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: parent.radius
                                            color: "transparent"
                                            border { color: Theme.separator; width: 1 }
                                        }

                                        Text {
                                            id: actLabel
                                            anchors.centerIn: parent
                                            text:  modelData.text
                                            color: Theme.text
                                            font { family: Theme.fontFamily; pixelSize: Theme.fontSize - 2; weight: Font.Medium }
                                        }

                                        MouseArea {
                                            id: actMa
                                            anchors.fill: parent
                                            cursorShape:  Qt.PointingHandCursor
                                            hoverEnabled: true
                                            z: 5
                                            onClicked: {
                                                modelData.invoke()
                                                notifCard.modelData.dismiss()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
