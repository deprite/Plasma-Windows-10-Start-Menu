import QtQuick
import QtCore
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

FocusScope {
    id: root

    required property bool sharedLayoutEnabled
    required property bool appListOpenOnLaunch
    required property bool showDocumentsShortcut
    required property string homeShortcutLabel
    required property string homeShortcutUrl
    required property bool showPicturesShortcut
    required property string picturesShortcutLabel
    required property string picturesShortcutUrl
    required property bool showSystemSettingsShortcut
    required property color backgroundColor
    required property real backgroundOpacity
    required property color railColor
    required property color tileColor
    required property color accentColor
    readonly property bool folderDialogVisible: homeFolderDialog.visible || picturesFolderDialog.visible
                                               || backgroundColorDialog.visible || railColorDialog.visible
                                               || tileColorDialog.visible || accentColorDialog.visible
    signal backRequested()
    signal publishSharedLayoutRequested()
    signal appListOpenOnLaunchRequested(bool enabled)
    signal documentsShortcutRequested(bool enabled)
    signal homeShortcutLabelRequested(string label)
    signal homeShortcutUrlRequested(string url)
    signal picturesShortcutRequested(bool enabled)
    signal picturesShortcutLabelRequested(string label)
    signal picturesShortcutUrlRequested(string url)
    signal systemSettingsShortcutRequested(bool enabled)
    signal backgroundColorRequested(string colorValue)
    signal backgroundOpacityRequested(real opacity)
    signal railColorRequested(string colorValue)
    signal tileColorRequested(string colorValue)
    signal accentColorRequested(string colorValue)

    onVisibleChanged: {
        if (visible) Qt.callLater(() => backButton.forceActiveFocus())
    }

    function closeTransientDialogs() {
        homeFolderDialog.close()
        picturesFolderDialog.close()
        backgroundColorDialog.close()
        railColorDialog.close()
        tileColorDialog.close()
        accentColorDialog.close()
    }

    FolderDialog {
        id: homeFolderDialog
        title: i18n("Choose Home shortcut folder")
        currentFolder: root.homeShortcutUrl || StandardPaths.writableLocation(StandardPaths.HomeLocation)
        onAccepted: root.homeShortcutUrlRequested(selectedFolder.toString())
    }

    ColorDialog {
        id: backgroundColorDialog
        title: i18n("Choose background color")
        selectedColor: root.backgroundColor
        onAccepted: root.backgroundColorRequested(selectedColor.toString())
    }

    ColorDialog {
        id: railColorDialog
        title: i18n("Choose utility rail color")
        selectedColor: root.railColor
        onAccepted: root.railColorRequested(selectedColor.toString())
    }

    ColorDialog {
        id: tileColorDialog
        title: i18n("Choose tile color")
        selectedColor: root.tileColor
        onAccepted: root.tileColorRequested(selectedColor.toString())
    }

    ColorDialog {
        id: accentColorDialog
        title: i18n("Choose accent color")
        selectedColor: root.accentColor
        onAccepted: root.accentColorRequested(selectedColor.toString())
    }

    FolderDialog {
        id: picturesFolderDialog
        title: i18n("Choose Pictures shortcut folder")
        currentFolder: root.picturesShortcutUrl || StandardPaths.writableLocation(StandardPaths.PicturesLocation)
        onAccepted: root.picturesShortcutUrlRequested(selectedFolder.toString())
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 42
        anchors.rightMargin: 48
        anchors.topMargin: 30
        anchors.bottomMargin: 30
        spacing: 24

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            QQC2.ToolButton {
                id: backButton
                implicitWidth: 48
                implicitHeight: 48
                icon.name: "go-previous"
                Accessible.name: i18n("Back to launcher")
                onClicked: root.backRequested()
            }

            QQC2.Label {
                text: i18n("Launcher settings")
                color: "white"
                font.pixelSize: 31
                font.weight: Font.Medium
            }

            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 28

            Rectangle {
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                color: Qt.rgba(0.045, 0.075, 0.15, 0.72)
                radius: 6

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    QQC2.ItemDelegate {
                        Layout.fillWidth: true
                        implicitHeight: 52
                        text: i18n("General")
                        icon.name: "settings-configure"
                        highlighted: true
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            Flickable {
                id: settingsFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: settingsColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                QQC2.ScrollBar.vertical: QQC2.ScrollBar { }

                ColumnLayout {
                    id: settingsColumn
                    width: settingsFlick.width - 16
                    spacing: 18

                    QQC2.Label {
                        text: i18n("General")
                        color: "white"
                        font.pixelSize: 25
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: appearanceContent.implicitHeight + 48
                        color: Qt.rgba(0.06, 0.09, 0.18, 0.82)
                        border.color: Qt.rgba(1, 1, 1, 0.16)
                        border.width: 1
                        radius: 7

                        ColumnLayout {
                            id: appearanceContent
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 12

                            QQC2.Label {
                                text: i18n("Appearance")
                                color: "white"
                                font.pixelSize: 20
                                font.weight: Font.Medium
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: i18n("Tune the glass tint, transparency, tiles, and highlights.")
                                color: Qt.rgba(1, 1, 1, 0.74)
                                font.pixelSize: 15
                                wrapMode: Text.WordWrap
                            }

                            GridLayout {
                                columns: 2
                                columnSpacing: 12
                                rowSpacing: 10

                                QQC2.Button { text: i18n("Background"); icon.name: "color-picker"; onClicked: backgroundColorDialog.open() }
                                QQC2.Button { text: i18n("Utility rail"); icon.name: "color-picker"; onClicked: railColorDialog.open() }
                                QQC2.Button { text: i18n("Tiles"); icon.name: "color-picker"; onClicked: tileColorDialog.open() }
                                QQC2.Button { text: i18n("Accent"); icon.name: "color-picker"; onClicked: accentColorDialog.open() }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                QQC2.Label { text: i18n("Background opacity") ; color: "white" }
                                QQC2.Slider {
                                    Layout.fillWidth: true
                                    from: 0.35
                                    to: 0.95
                                    stepSize: 0.01
                                    value: root.backgroundOpacity
                                    onMoved: root.backgroundOpacityRequested(value)
                                }
                                QQC2.Label {
                                    text: Math.round(root.backgroundOpacity * 100) + "%"
                                    color: "white"
                                    Layout.preferredWidth: 48
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            QQC2.Button {
                                text: i18n("Restore concept colors")
                                icon.name: "edit-undo"
                                onClicked: {
                                    root.backgroundColorRequested("#08152f")
                                    root.backgroundOpacityRequested(0.72)
                                    root.railColorRequested("#061126")
                                    root.tileColorRequested("#202e4c")
                                    root.accentColorRequested("#2e86de")
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: syncContent.implicitHeight + 48
                        color: Qt.rgba(0.06, 0.09, 0.18, 0.82)
                        border.color: Qt.rgba(1, 1, 1, 0.16)
                        border.width: 1
                        radius: 7

                        ColumnLayout {
                            id: syncContent
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 14

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 14

                                Kirigami.Icon {
                                    Layout.preferredWidth: 30
                                    Layout.preferredHeight: 30
                                    source: "emblem-synchronized"
                                    color: "white"
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: i18n("Layout synchronization")
                                    color: "white"
                                    font.pixelSize: 20
                                    font.weight: Font.Medium
                                }
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: root.sharedLayoutEnabled
                                      ? i18n("Groups, applications, columns, order, and launcher sidebar settings are shared across all launcher instances.")
                                      : i18n("This launcher currently keeps its own layout and sidebar settings.")
                                color: Qt.rgba(1, 1, 1, 0.74)
                                font.pixelSize: 15
                                wrapMode: Text.WordWrap
                            }

                            QQC2.Button {
                                Layout.preferredHeight: 46
                                text: root.sharedLayoutEnabled
                                      ? i18n("Publish layout and settings again")
                                      : i18n("Use this layout and settings on all screens")
                                icon.name: "emblem-synchronized"
                                onClicked: root.publishSharedLayoutRequested()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: railContent.implicitHeight + 48
                        color: Qt.rgba(0.06, 0.09, 0.18, 0.82)
                        border.color: Qt.rgba(1, 1, 1, 0.16)
                        border.width: 1
                        radius: 7

                        ColumnLayout {
                            id: railContent
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 10

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: i18n("Launcher sidebar")
                                color: "white"
                                font.pixelSize: 20
                                font.weight: Font.Medium
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: i18n("Choose the default app-list state and which optional shortcuts appear in the utility rail.")
                                color: Qt.rgba(1, 1, 1, 0.74)
                                font.pixelSize: 15
                                wrapMode: Text.WordWrap
                            }

                            QQC2.CheckBox {
                                text: i18n("Keep the app list open when the launcher opens")
                                checked: root.appListOpenOnLaunch
                                onToggled: root.appListOpenOnLaunchRequested(checked)
                            }

                            QQC2.CheckBox {
                                text: i18n("Show Home folder shortcut")
                                checked: root.showDocumentsShortcut
                                onToggled: root.documentsShortcutRequested(checked)
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                enabled: root.showDocumentsShortcut

                                QQC2.TextField {
                                    id: homeLabelField
                                    Layout.preferredWidth: 190
                                    text: root.homeShortcutLabel
                                    placeholderText: i18n("Home")
                                    onEditingFinished: root.homeShortcutLabelRequested(text.trim() || i18n("Home"))
                                }

                                QQC2.Button {
                                    text: i18n("Choose folder…")
                                    icon.name: "folder-open"
                                    onClicked: homeFolderDialog.open()
                                }

                                QQC2.Button {
                                    text: i18n("Reset")
                                    icon.name: "edit-undo"
                                    onClicked: {
                                        homeLabelField.text = "Home"
                                        root.homeShortcutLabelRequested("Home")
                                        root.homeShortcutUrlRequested("")
                                    }
                                }
                            }

                            QQC2.CheckBox {
                                text: i18n("Show Pictures shortcut")
                                checked: root.showPicturesShortcut
                                onToggled: root.picturesShortcutRequested(checked)
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                enabled: root.showPicturesShortcut

                                QQC2.TextField {
                                    id: picturesLabelField
                                    Layout.preferredWidth: 190
                                    text: root.picturesShortcutLabel
                                    placeholderText: i18n("Pictures")
                                    onEditingFinished: root.picturesShortcutLabelRequested(text.trim() || i18n("Pictures"))
                                }

                                QQC2.Button {
                                    text: i18n("Choose folder…")
                                    icon.name: "folder-open"
                                    onClicked: picturesFolderDialog.open()
                                }

                                QQC2.Button {
                                    text: i18n("Reset")
                                    icon.name: "edit-undo"
                                    onClicked: {
                                        picturesLabelField.text = "Pictures"
                                        root.picturesShortcutLabelRequested("Pictures")
                                        root.picturesShortcutUrlRequested("")
                                    }
                                }
                            }

                            QQC2.CheckBox {
                                text: i18n("Show System Settings shortcut")
                                checked: root.showSystemSettingsShortcut
                                onToggled: root.systemSettingsShortcutRequested(checked)
                            }
                        }
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: i18n("More appearance, layout, and behavior options can be added here without crowding the launcher.")
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
