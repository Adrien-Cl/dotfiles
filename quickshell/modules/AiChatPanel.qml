import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../"

PanelWindow {
    id: root

    required property PanelWindow bar
    signal closeRequested()

    screen: bar.screen

    color:         "transparent"
    exclusiveZone: 0
    WlrLayershell.namespace:     "quickshell-ai"
    WlrLayershell.layer:         WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrLayershell.OnDemand

    anchors { top: true; left: true }
    margins.top:  Theme.marginTop
    margins.left: Theme.marginSide

    implicitWidth:  380
    implicitHeight: 560

    visible: false

    property bool shown:     false
    property bool isLoading: false

    onShownChanged: {
        if (shown) {
            animOut.stop()
            contentRect.opacity = 0
            slideTranslate.y = -10
            root.visible = true
            animIn.start()
            inputField.forceActiveFocus()
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

    ListModel { id: messagesModel }

    function sendMessage(text) {
        if (text.trim() === "" || isLoading) return
        messagesModel.append({ role: "user", text: text.trim(), tools: "" })
        isLoading = true
        Qt.callLater(() => listView.positionViewAtEnd())

        var xhr = new XMLHttpRequest()
        xhr.open("POST", "http://127.0.0.1:7878/chat")
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== 4) return
            isLoading = false
            if (xhr.status === 200) {
                var data = JSON.parse(xhr.responseText)
                var toolsStr = data.tools_used.length > 0 ? data.tools_used.join("\n") : ""
                messagesModel.append({ role: "ai", text: data.response, tools: toolsStr })
            } else if (xhr.status === 0) {
                messagesModel.append({ role: "ai", text: "Le backend IA ne répond pas. Il démarre peut-être encore…", tools: "" })
            } else {
                messagesModel.append({ role: "ai", text: "Erreur " + xhr.status, tools: "" })
            }
            Qt.callLater(() => listView.positionViewAtEnd())
        }
        xhr.send(JSON.stringify({ message: text.trim() }))
    }

    function clearHistory() {
        messagesModel.clear()
        var xhr = new XMLHttpRequest()
        xhr.open("DELETE", "http://127.0.0.1:7878/history")
        xhr.send()
    }

    Rectangle {
        id: contentRect
        anchors.fill: parent
        radius:       8
        color:        Theme.bgSolid

        transform: Translate { id: slideTranslate }

        ColumnLayout {
            anchors { fill: parent; margins: 0 }
            spacing: 0

            // Header
            Item {
                Layout.fillWidth: true
                height: 40

                RowLayout {
                    anchors { fill: parent; leftMargin: 14; rightMargin: 10 }

                    Text {
                        text:  "IA ArchLinux"
                        color: Theme.text
                        font.family:    Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight:    Font.DemiBold
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        text:  "󰆴"
                        color: Theme.textDim
                        font.family:    Theme.fontFamily
                        font.pixelSize: Theme.iconSize
                        verticalAlignment: Text.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    root.clearHistory()
                        }
                        HoverHandler { onHoveredChanged: parent.color = hovered ? Theme.danger : Theme.textDim }
                    }

                    Item { width: 4 }

                    Text {
                        text:  ""
                        color: Theme.textDim
                        font.family:    Theme.fontFamily
                        font.pixelSize: Theme.iconSize
                        verticalAlignment: Text.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    root.closeRequested()
                        }
                        HoverHandler { onHoveredChanged: parent.color = hovered ? Theme.danger : Theme.textDim }
                    }
                }

                Rectangle {
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12 }
                    height: 1
                    color:  Theme.separator
                }
            }

            // Messages list
            ListView {
                id: listView
                Layout.fillWidth:  true
                Layout.fillHeight: true
                clip:              true
                model:             messagesModel
                spacing:           8
                topMargin:         10
                bottomMargin:      10
                leftMargin:        10
                rightMargin:       10

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: Theme.separator
                    }
                }

                delegate: Column {
                    id: delegateCol
                    property int msgIndex: index
                    width: listView.width - 20
                    spacing: 2

                    Repeater {
                        model: (role === "ai" && tools !== "") ? tools.split("\n") : []
                        delegate: Rectangle {
                            width:  toolLabel.implicitWidth + 16
                            height: toolLabel.implicitHeight + 6
                            radius: 4
                            color:  Qt.rgba(1, 1, 1, 0.05)
                            border.color: Theme.separator
                            border.width: 1
                            Text {
                                id: toolLabel
                                anchors.centerIn: parent
                                text:  "⚙ " + modelData
                                color: Theme.textDim
                                font.family:    Theme.fontFamily
                                font.pixelSize: 10
                                elide:          Text.ElideRight
                                maximumLineCount: 1
                            }
                        }
                    }

                    Item {
                        width:  parent.width
                        height: bubble.height + copyRow.height + 2

                        Row {
                            id: copyRow
                            anchors.top:   bubble.bottom
                            anchors.topMargin: 3
                            anchors.right: role === "user" ? bubble.right : undefined
                            anchors.left:  role === "ai"   ? bubble.left  : undefined

                            Text {
                                text:  "󰆏"
                                color: copyMa.containsMouse ? Theme.text : Theme.textDim
                                font.family:    Theme.fontFamily
                                font.pixelSize: 14
                                MouseArea {
                                    id: copyMa
                                    anchors.fill: parent
                                    cursorShape:  Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked:    Quickshell.execDetached(["wl-copy", model.text])
                                }
                            }
                        }

                        Rectangle {
                            id: bubble
                            width:  parent.width * 0.82
                            height: msgText.implicitHeight + 16
                            radius: 8
                            anchors.right: role === "user" ? parent.right : undefined
                            anchors.left:  role === "ai"   ? parent.left  : undefined
                            color: role === "user"
                                ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)
                                : Qt.rgba(Theme.bgSolid.r, Theme.bgSolid.g, Theme.bgSolid.b, 0.8)
                            border.color: Theme.separator
                            border.width: 1

                            TextEdit {
                                id: msgText
                                anchors { fill: parent; margins: 10 }
                                text:           model.text
                                color:          Theme.text
                                font.family:    Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                wrapMode:       TextEdit.Wrap
                                readOnly:       true
                                selectByMouse:  true
                                textFormat:     TextEdit.MarkdownText
                            }
                        }
                    }

                }

                Text {
                    anchors.centerIn: parent
                    visible: messagesModel.count === 0 && !isLoading
                    text:  "Comment puis-je vous aider ?"
                    color: Theme.textDim
                    font.family:    Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }

            // Loading dots
            Item {
                Layout.fillWidth: true
                height:  isLoading ? 28 : 0
                visible: isLoading
                clip:    true

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: 3
                        Rectangle {
                            property int dotIndex: index
                            width: 6; height: 6; radius: 3
                            color: Theme.textDim

                            SequentialAnimation on opacity {
                                loops:   Animation.Infinite
                                running: isLoading
                                NumberAnimation { to: 0.2; duration: 400 + dotIndex * 150; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 400 + dotIndex * 150; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                }
            }

            // Input area
            Item {
                Layout.fillWidth: true
                height: 48

                Rectangle {
                    anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12 }
                    height: 1
                    color:  Theme.separator
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 10; topMargin: 8; bottomMargin: 8 }
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth:  true
                        Layout.fillHeight: true
                        radius:       6
                        color:        Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                        border.color: inputField.activeFocus
                            ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                            : Theme.separator
                        border.width: 1

                        TextInput {
                            id: inputField
                            anchors { fill: parent; leftMargin: 10; rightMargin: 8; topMargin: 4; bottomMargin: 4 }
                            color:             Theme.text
                            font.family:       Theme.fontFamily
                            font.pixelSize:    Theme.fontSize
                            verticalAlignment: TextInput.AlignVCenter
                            enabled: !isLoading
                            clip:    true

                            Text {
                                anchors.fill: parent
                                text:    "Écrivez un message…"
                                color:   Theme.textDim
                                font:    parent.font
                                visible: inputField.text === ""
                                verticalAlignment: Text.AlignVCenter
                            }

                            Keys.onReturnPressed: {
                                root.sendMessage(text)
                                text = ""
                            }
                        }
                    }

                    Text {
                        text:  isLoading ? "" : ""
                        color: inputField.text.trim() !== "" && !isLoading ? Theme.text : Theme.textDim
                        font.family:    Theme.fontFamily
                        font.pixelSize: Theme.iconSize
                        font.weight:    Font.DemiBold
                        verticalAlignment: Text.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            enabled:      !isLoading
                            onClicked: {
                                root.sendMessage(inputField.text)
                                inputField.text = ""
                            }
                        }
                    }
                }
            }

            Item { height: 4 }
        }
    }
}
