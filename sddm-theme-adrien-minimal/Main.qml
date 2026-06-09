import QtQuick 2.15

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#01010F"

    property int currentSessionIdx: sessionModel.lastIndex
    property int currentUserIdx: userModel.lastIndex

    // ── Fond wallpaper ────────────────────────────────────────────────────────
    Image {
        anchors.fill: parent
        source: "file:///usr/share/sddm/themes/adrien-minimal/background.jpg"
        fillMode: Image.PreserveAspectCrop

        Rectangle {
            anchors.fill: parent
            color: "#80000000"
        }
    }

    // ── Horloge ───────────────────────────────────────────────────────────────
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.text = Qt.formatTime(new Date(), "hh:mm")
    }

    // ── Centre : heure + date + password ─────────────────────────────────────
    Column {
        anchors.centerIn: parent
        spacing: 16

        Text {
            id: clock
            text: Qt.formatTime(new Date(), "hh:mm")
            color: "#FFFFFF"
            font.family: "JetBrains Mono"
            font.weight: Font.DemiBold
            font.pixelSize: 80
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: Qt.formatDate(new Date(), "dddd, dd MMMM")
            color: "#99C8D1E9"
            font.family: "JetBrains Mono"
            font.weight: Font.DemiBold
            font.pixelSize: 18
            anchors.horizontalCenter: parent.horizontalCenter
            bottomPadding: 24
        }

        Rectangle {
            width: 280
            height: 44
            color: "#1AFFFFFF"
            radius: 8
            anchors.horizontalCenter: parent.horizontalCenter
            border.width: 2
            border.color: passwordField.activeFocus ? "#FFFFFF" : "#80C8D1E9"

            Behavior on border.color { ColorAnimation { duration: 200 } }

            TextInput {
                id: passwordField
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                verticalAlignment: TextInput.AlignVCenter
                color: "#FFFFFF"
                font.family: "JetBrains Mono"
                font.weight: Font.DemiBold
                font.pixelSize: 14
                echoMode: TextInput.Password
                passwordCharacter: "•"
                focus: true

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: "mot de passe"
                    color: "#60C8D1E9"
                    font.family: "JetBrains Mono"
                    font.weight: Font.DemiBold
                    font.pixelSize: 14
                    font.italic: true
                    visible: passwordField.text.length === 0
                }

                Keys.onReturnPressed: root.doLogin()
                Keys.onEnterPressed: root.doLogin()
            }
        }

        Text {
            id: errorMsg
            text: ""
            color: "#F96565"
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            anchors.horizontalCenter: parent.horizontalCenter
            visible: text.length > 0
        }
    }

    // ── Bas : session · utilisateur ───────────────────────────────────────────
    Row {
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 32
        }
        spacing: 40

        // Session
        Row {
            spacing: 12
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: "‹"
                color: maSessionL.containsMouse ? "#FFFFFF" : "#80C8D1E9"
                font.family: "JetBrains Mono"
                font.pixelSize: 15
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea {
                    id: maSessionL
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentSessionIdx =
                        (root.currentSessionIdx - 1 + sessionModel.rowCount()) % sessionModel.rowCount()
                }
            }

            Text {
                text: sessionModel.data(sessionModel.index(root.currentSessionIdx, 0), Qt.UserRole + 4)
                color: "#C8D1E9"
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                width: 110
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: "›"
                color: maSessionR.containsMouse ? "#FFFFFF" : "#80C8D1E9"
                font.family: "JetBrains Mono"
                font.pixelSize: 15
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea {
                    id: maSessionR
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentSessionIdx =
                        (root.currentSessionIdx + 1) % sessionModel.rowCount()
                }
            }
        }

        Text {
            text: "·"
            color: "#25C8D1E9"
            font.family: "JetBrains Mono"
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
        }

        // Utilisateur
        Row {
            spacing: 12
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: "‹"
                color: maUserL.containsMouse ? "#FFFFFF" : "#80C8D1E9"
                font.family: "JetBrains Mono"
                font.pixelSize: 15
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea {
                    id: maUserL
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentUserIdx =
                        (root.currentUserIdx - 1 + userModel.rowCount()) % userModel.rowCount()
                }
            }

            Text {
                text: userModel.data(userModel.index(root.currentUserIdx, 0), Qt.UserRole + 1)
                color: "#C8D1E9"
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                width: 110
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: "›"
                color: maUserR.containsMouse ? "#FFFFFF" : "#80C8D1E9"
                font.family: "JetBrains Mono"
                font.pixelSize: 15
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea {
                    id: maUserR
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentUserIdx =
                        (root.currentUserIdx + 1) % userModel.rowCount()
                }
            }
        }
    }

    function doLogin() {
        errorMsg.text = ""
        sddm.login(
            userModel.data(userModel.index(root.currentUserIdx, 0), Qt.UserRole + 1),
            passwordField.text,
            root.currentSessionIdx
        )
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorMsg.text = "Mot de passe incorrect"
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }
}
