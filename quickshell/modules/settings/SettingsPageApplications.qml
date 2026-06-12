import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root

    property var  allPackages:  []
    property var  _tempPkgs:    []
    property bool loading:      true
    property int  updateCount:  0
    property bool checkingUpd:  false

    Process {
        id: procPkgList
        command: ["bash", "-c", "pacman -Q 2>/dev/null | sort"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var p = data.trim().split(" ")
                if (p.length >= 2 && p[0] !== "")
                    root._tempPkgs.push({ name: p[0], version: p.slice(1).join(" ") })
            }
        }
        onRunningChanged: {
            if (!running) {
                root.allPackages = root._tempPkgs.slice()
                root._tempPkgs = []
                root.loading = false
            }
        }
    }

    Process {
        id: procCheckUpdates
        command: ["bash", "-c", "pacman -Qu 2>/dev/null | wc -l"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                root.updateCount = parseInt(data.trim()) || 0
                root.checkingUpd = false
            }
        }
    }

    Process { id: procRemove; running: false }

    Component.onCompleted: {
        procPkgList.running = true
        procCheckUpdates.running = true
    }

    property string searchText: ""

    Column {
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 16; leftMargin: 16; rightMargin: 16 }
        spacing: 10
        id: topSection

        // — Mise à jour —
        Rectangle {
            width: parent.width; height: 42; radius: 8
            color: root.updateCount > 0
                   ? Qt.rgba(0xFF/255, 0xA5/255, 0, 0.08)
                   : Qt.rgba(0x4C/255, 0xAF/255, 0x50/255, 0.07)

            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 10
                Text {
                    text: root.updateCount > 0 ? "󰚰" : "󰄬"
                    color: root.updateCount > 0 ? Theme.warning : Theme.success
                    font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                }
                Text {
                    text: root.updateCount > 0
                          ? root.updateCount + " mise" + (root.updateCount > 1 ? "s" : "") + " à jour disponible" + (root.updateCount > 1 ? "s" : "")
                          : "Système à jour"
                    color: Theme.text; font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight; Layout.fillWidth: true
                }
                Rectangle {
                    visible: root.updateCount > 0
                    width: updLbl.implicitWidth + 14; height: 24; radius: 4
                    color: Qt.rgba(0xFF/255, 0xA5/255, 0, 0.15)
                    Text {
                        id: updLbl; anchors.centerIn: parent; text: "Mettre à jour"
                        color: Theme.warning; font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Theme.fontWeight
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["kitty", "-e", "bash", "-c", "yay -Syu; read -p 'Terminé — Appuyer sur Entrée...'"])
                    }
                }
            }
        }

        // — Recherche —
        Rectangle {
            width: parent.width; height: 34; radius: 6
            color: Qt.rgba(1, 1, 1, 0.06)
            border.color: searchInput.activeFocus ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.35) : "transparent"
            border.width: 1

            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                spacing: 8
                Text {
                    text: "󰍉"
                    color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.iconSize
                }
                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Theme.text
                    font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight
                    selectionColor: Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.3)
                    onTextChanged: root.searchText = text.toLowerCase()

                    Text {
                        anchors.fill: parent
                        text: "Rechercher un paquet…"
                        color: Theme.textDim; font: parent.font
                        verticalAlignment: Text.AlignVCenter
                        visible: !parent.text && !parent.activeFocus
                    }
                }
                Text {
                    visible: root.searchText !== ""
                    text: "✕"; color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 12
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { searchInput.text = ""; root.searchText = "" }
                    }
                }
            }
        }

        // — Stats —
        RowLayout {
            width: parent.width; spacing: 8
            Text {
                text: root.loading ? "Chargement…" : filteredModel.count + " paquet" + (filteredModel.count > 1 ? "s" : "") + (root.searchText !== "" ? " trouvé" + (filteredModel.count > 1 ? "s" : "") : " installé" + (filteredModel.count > 1 ? "s" : ""))
                color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 10
                Layout.fillWidth: true
            }
            Rectangle {
                width: instLbl.implicitWidth + 14; height: 22; radius: 4; color: Qt.rgba(1, 1, 1, 0.07)
                Text {
                    id: instLbl; anchors.centerIn: parent; text: "󰐕  Installer"
                    color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Theme.fontWeight
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["kitty", "-e", "bash", "-c",
                        "echo 'Entrer le nom du paquet à installer:'; read pkg; " +
                        "[ -n \"$pkg\" ] && yay -S \"$pkg\"; read -p 'Terminé — Appuyer sur Entrée...'"])
                }
            }
        }
    }

    // Filtered model using DelegateModel
    ListModel {
        id: filteredModel
        // Rebuilt whenever allPackages or searchText changes
    }

    Connections {
        target: root
        function onAllPackagesChanged() { rebuildModel() }
        function onSearchTextChanged()  { rebuildModel() }
    }

    function rebuildModel() {
        filteredModel.clear()
        var search = root.searchText
        var pkgs = root.allPackages
        var limit = 200
        var count = 0
        for (var i = 0; i < pkgs.length && count < limit; i++) {
            if (search === "" || pkgs[i].name.indexOf(search) >= 0) {
                filteredModel.append({ name: pkgs[i].name, version: pkgs[i].version })
                count++
            }
        }
    }

    // Package list
    Item {
        anchors {
            top: topSection.bottom; topMargin: 8
            left: parent.left; leftMargin: 16
            right: parent.right; rightMargin: 16
            bottom: parent.bottom; bottomMargin: 8
        }
        clip: true

        Text {
            visible: root.loading
            anchors.centerIn: parent
            text: "Chargement des paquets…"
            color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
        }

        ListView {
            id: pkgList
            anchors.fill: parent
            visible: !root.loading
            model: filteredModel
            clip: true
            spacing: 3
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                required property string name
                required property string version
                required property int    index

                property bool pkgHov: false

                width: pkgList.width - 8; height: 32; radius: 6
                color: pkgHov ? Qt.rgba(0xC8/255, 0xD1/255, 0xE9/255, 0.05) : Qt.rgba(1, 1, 1, 0.03)
                Behavior on color { ColorAnimation { duration: 80 } }

                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 8

                    Text {
                        text: "󰏖"
                        color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 11
                    }
                    Text {
                        text: name
                        color: Theme.text; font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize; font.weight: Theme.fontWeight
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: version
                        color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: 10
                    }
                    Rectangle {
                        width: 22; height: 22; radius: 4
                        color: rmHov.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.20) : Qt.rgba(1, 0.3, 0.3, 0.10)
                        Behavior on color { ColorAnimation { duration: 80 } }
                        Text {
                            anchors.centerIn: parent; text: "✕"
                            color: Theme.danger; font.family: Theme.fontFamily; font.pixelSize: 10
                        }
                        MouseArea {
                            id: rmHov; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: Quickshell.execDetached(["kitty", "-e", "bash", "-c",
                                "echo \"Supprimer '" + name + "' ?\"; read -p 'Confirmer (o/N): ' c; " +
                                "[ \"$c\" = 'o' ] && yay -Rs '" + name + "'; read -p 'Terminé — Appuyer sur Entrée...'"])
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true
                    onEntered: parent.pkgHov = true; onExited: parent.pkgHov = false
                }
            }

        }

        // Custom scrollbar overlay
        Rectangle {
            visible: pkgList.contentHeight > pkgList.height
            anchors { right: parent.right; rightMargin: 2 }
            width: 3; radius: 2
            color: Qt.rgba(1, 1, 1, 0.2)
            y: pkgList.visibleArea.yPosition * pkgList.height
            height: Math.max(20, pkgList.visibleArea.heightRatio * pkgList.height)
        }
    }
}
