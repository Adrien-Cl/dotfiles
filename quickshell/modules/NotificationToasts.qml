import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../"

PanelWindow {
    id: root
    required property PanelWindow bar

    screen: bar.screen

    WlrLayershell.layer:         WlrLayershell.Overlay
    WlrLayershell.namespace:     "quickshell-notif-toasts"
    WlrLayershell.keyboardFocus: WlrLayershell.None

    anchors { top: true; right: true }
    margins {
        top:   Theme.marginTop
        right: Theme.marginSide
    }

    implicitWidth:  360
    implicitHeight: toastList.contentHeight > 0 ? toastList.contentHeight : 1

    color:   "transparent"
    visible: NotificationState.toasts.count > 0

    function _invokeDefault(obj) {
        if (!obj) return false
        var acts = obj.actions
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

    function _visibleActions(obj) {
        if (!obj || !obj.actions) return []
        return obj.actions.filter(function(a) {
            return a.text && a.text.length > 0 && a.identifier !== "default"
        })
    }

    ListView {
        id:      toastList
        width:   parent.width
        height:  contentHeight
        spacing: 10
        model:   NotificationState.toasts

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1;   duration: 320; easing.type: Easing.OutCubic }
                NumberAnimation { property: "x";       from: 80; to: 0;  duration: 320; easing.type: Easing.OutCubic }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0;  duration: 240; easing.type: Easing.InCubic }
                NumberAnimation { property: "x";       to: 80; duration: 240; easing.type: Easing.InCubic }
            }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic }
        }

        delegate: Item {
            id: toastItem

            required property int    notifId
            required property string notifAppName
            required property string notifAppIcon
            required property string notifImage
            required property string notifSummary
            required property string notifBody
            required property var    notifUrgency
            required property var    notifObject
            required property string notifCategory
            required property real   notifTime

            property color accentColor: {
                if (notifCategory === "phone")   return "#A78BFA"
                if (notifCategory === "media")   return Theme.success
                if (notifCategory === "critical") return "#F96565"
                return Theme.separator
            }

            property var visibleActions: root._visibleActions(notifObject)

            width:  toastList.width
            height: card.height

            // ── Hover global — pause du timer ─────────────────────────────
            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            // ── Card ─────────────────────────────────────────────────────
            Rectangle {
                id:     card
                width:  parent.width
                height: cardContent.implicitHeight + 28
                radius: 8
                color:  hoverArea.containsMouse
                        ? Qt.rgba(0xD0/255, 0xD9/255, 0xF0/255, 0.12)
                        : Theme.bgOpaque

                Behavior on color { ColorAnimation { duration: 120 } }

                // Bordure uniforme
                Rectangle {
                    anchors.fill: parent
                    radius:       parent.radius
                    color:        "transparent"
                    z:            2
                    border { color: Theme.separator; width: 1 }
                }

                // Bande d'accent à gauche
                Rectangle {
                    anchors {
                        top:        parent.top
                        bottom:     parent.bottom
                        left:       parent.left
                        topMargin:  1
                        bottomMargin: 1
                        leftMargin: 1
                    }
                    width:  3
                    radius: 7
                    color:  toastItem.accentColor
                    z:      3
                }

                // ── Clic sur le corps (action par défaut → ouvre l'app) ──
                MouseArea {
                    anchors { fill: parent; rightMargin: 40 }
                    cursorShape: Qt.PointingHandCursor
                    z: 1
                    onClicked: {
                        var invoked = root._invokeDefault(toastItem.notifObject)
                        if (!invoked)
                            root._openApp(toastItem.notifAppIcon, toastItem.notifAppName)
                        NotificationState.removeById(toastItem.notifId)
                    }
                }

                // ── Contenu ───────────────────────────────────────────────
                Column {
                    id: cardContent
                    anchors {
                        top:         parent.top
                        left:        parent.left
                        right:       parent.right
                        topMargin:   12
                        leftMargin:  20
                        rightMargin: 12
                        bottomMargin: 12
                    }
                    spacing: 0

                    RowLayout {
                        width:   parent.width
                        spacing: 10

                        // Icône app
                        Item {
                            id:     iconWrapper
                            width:  36
                            height: 36
                            Layout.alignment: Qt.AlignTop

                            Rectangle {
                                id:     iconBg
                                anchors.fill: parent
                                radius: 8
                                color:  Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.08)

                                // Lettre de secours (si aucune image ne charge)
                                Text {
                                    anchors.centerIn: parent
                                    text:    toastItem.notifAppName.charAt(0).toUpperCase() || "?"
                                    color:   Theme.text
                                    font { family: Theme.fontFamily; pixelSize: 15; weight: Font.Bold }
                                    visible: iconImg.status !== Image.Ready && iconImgFallback.status !== Image.Ready
                                }

                                // Icône — essaie le nom original
                                Image {
                                    id: iconImg
                                    anchors {
                                        fill:    parent
                                        margins: toastItem.notifImage !== "" ? 0 : 6
                                    }
                                    source: toastItem.notifImage !== ""
                                                ? toastItem.notifImage
                                                : (toastItem.notifAppIcon !== ""
                                                   ? "image://icon/" + toastItem.notifAppIcon
                                                   : "")
                                    fillMode: toastItem.notifImage !== ""
                                                  ? Image.PreserveAspectCrop
                                                  : Image.PreserveAspectFit
                                    smooth:  true
                                    visible: status === Image.Ready
                                }

                                // Fallback — nom en minuscules (ex: "Spotify" → "spotify")
                                Image {
                                    id: iconImgFallback
                                    anchors { fill: parent; margins: 6 }
                                    source: iconImg.status !== Image.Ready && toastItem.notifAppIcon !== ""
                                                ? "image://icon/" + toastItem.notifAppIcon.toLowerCase()
                                                : ""
                                    fillMode: Image.PreserveAspectFit
                                    smooth:   true
                                    visible:  status === Image.Ready
                                }
                            }

                            // Badge téléphone (catégorie phone)
                            Rectangle {
                                visible: toastItem.notifCategory === "phone"
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

                            Text {
                                visible: toastItem.notifAppName.length > 0
                                width:   parent.width
                                text:    toastItem.notifAppName
                                color:   Theme.textDim
                                font { family: Theme.fontFamily; pixelSize: Theme.fontSize - 2; weight: Font.Medium }
                                elide:   Text.ElideRight
                            }

                            Text {
                                width:  parent.width
                                text:   toastItem.notifSummary
                                color:  Theme.text
                                font { family: Theme.fontFamily; pixelSize: Theme.fontSize; weight: Font.DemiBold }
                                elide:  Text.ElideRight
                            }

                            Text {
                                visible:          toastItem.notifBody.length > 0
                                width:            parent.width
                                text:             toastItem.notifBody
                                color:            Theme.textDim
                                font { family: Theme.fontFamily; pixelSize: Theme.fontSize - 1 }
                                elide:            Text.ElideRight
                                maximumLineCount: 2
                                wrapMode:         Text.WordWrap
                            }
                        }

                        // Bouton fermer
                        Text {
                            id: closeBtn
                            text:    "✕"
                            color:   Theme.danger
                            opacity: 0.7
                            font { family: Theme.fontFamily; pixelSize: 16 }
                            Layout.alignment: Qt.AlignTop

                            MouseArea {
                                anchors.fill: parent
                                cursorShape:  Qt.PointingHandCursor
                                hoverEnabled: true
                                z: 5
                                onEntered:    closeBtn.opacity = 1.0
                                onExited:     closeBtn.opacity = 0.7
                                onClicked:    NotificationState.removeById(toastItem.notifId)
                            }
                        }
                    }

                    // ── Boutons d'actions ─────────────────────────────────
                    Item {
                        visible: toastItem.visibleActions.length > 0
                        width:   parent.width
                        height:  visible ? actionRow.implicitHeight + 8 : 0

                        Row {
                            id: actionRow
                            anchors { top: parent.top; left: parent.left; topMargin: 8; leftMargin: 46 }
                            spacing: 6

                            Repeater {
                                model: toastItem.visibleActions.slice(0, 2)

                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index

                                    height: 24
                                    width:  actionLabel.implicitWidth + 16
                                    radius: 4
                                    color:  actionMa.containsMouse
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
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        text:  modelData.text
                                        color: Theme.text
                                        font { family: Theme.fontFamily; pixelSize: Theme.fontSize - 2; weight: Font.Medium }
                                    }

                                    MouseArea {
                                        id: actionMa
                                        anchors.fill: parent
                                        cursorShape:  Qt.PointingHandCursor
                                        hoverEnabled: true
                                        z: 5
                                        onClicked: {
                                            modelData.invoke()
                                            NotificationState.removeById(toastItem.notifId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Barre de progression du timer ─────────────────────────
                Rectangle {
                    id: timerBar
                    anchors {
                        bottom:       parent.bottom
                        left:         parent.left
                        leftMargin:   5
                        bottomMargin: 3
                    }
                    height: 2
                    radius: 1
                    color:  Qt.rgba(toastItem.accentColor.r, toastItem.accentColor.g,
                                    toastItem.accentColor.b, 0.5)
                    z: 4

                    NumberAnimation on width {
                        id:       timerBarAnim
                        from:     card.width - 10
                        to:       0
                        duration: 5000
                        running:  true
                    }

                    // Sync avec le timer : le timer repart de 0 au survol, la barre aussi
                    Connections {
                        target: hoverArea
                        function onContainsMouseChanged() {
                            if (!hoverArea.containsMouse) timerBarAnim.restart()
                        }
                    }
                }
            }

            // ── Timer auto-dismiss (pause au survol) ─────────────────────
            Timer {
                interval:    5000
                running:     !hoverArea.containsMouse
                onTriggered: NotificationState.removeById(toastItem.notifId)
            }
        }
    }
}
