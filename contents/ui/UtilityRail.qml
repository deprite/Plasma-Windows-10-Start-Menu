import QtQuick
import QtCore
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.sessions as Sessions

Rectangle {
    id: root

    required property color backgroundColor
    required property color menuColor
    required property color accentColor
    required property bool appListVisible
    required property bool launcherSettingsVisible
    required property bool showDocumentsShortcut
    required property string homeShortcutLabel
    required property string homeShortcutUrl
    required property bool showPicturesShortcut
    required property string picturesShortcutLabel
    required property string picturesShortcutUrl
    required property bool showSystemSettingsShortcut
    signal closeRequested()
    signal launcherSettingsRequested()
    signal appListToggleRequested()

    color: backgroundColor

    Sessions.SessionManagement {
        id: sessionManagement
    }

    function closeThen(action) {
        root.closeRequested()
        action()
    }

    function closeTransientMenus() {
        userMenu.close()
        powerMenu.close()
    }

    QQC2.Menu {
        id: userMenu
        parent: userButton
        x: userButton.width
        y: userButton.height - height
        width: 236
        topPadding: 6
        bottomPadding: 6
        leftPadding: 6
        rightPadding: 6
        background: Rectangle {
            color: Qt.rgba(root.menuColor.r, root.menuColor.g, root.menuColor.b, 0.98)
            border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.55)
            border.width: 1
            radius: 5
        }

        SessionMenuItem {
            text: i18n("Lock")
            iconName: "system-lock-screen"
            accentColor: root.accentColor
            visible: sessionManagement.canLock
            onTriggered: root.closeThen(() => sessionManagement.lock())
        }

        SessionMenuItem {
            text: i18n("Switch User")
            iconName: "system-switch-user"
            accentColor: root.accentColor
            visible: sessionManagement.canSwitchUser
            onTriggered: root.closeThen(() => sessionManagement.switchUser())
        }

        SessionMenuItem {
            text: i18n("Log Out")
            iconName: "system-log-out"
            accentColor: root.accentColor
            destructive: true
            visible: sessionManagement.canLogout
            onTriggered: root.closeThen(() => sessionManagement.requestLogout(Sessions.SessionManagement.ForcePrompt))
        }
    }

    QQC2.Menu {
        id: powerMenu
        parent: powerButton
        x: powerButton.width
        y: powerButton.height - height
        width: 236
        topPadding: 6
        bottomPadding: 6
        leftPadding: 6
        rightPadding: 6
        background: Rectangle {
            color: Qt.rgba(root.menuColor.r, root.menuColor.g, root.menuColor.b, 0.98)
            border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.55)
            border.width: 1
            radius: 5
        }

        SessionMenuItem {
            text: i18n("Sleep")
            iconName: "system-suspend"
            accentColor: root.accentColor
            visible: sessionManagement.canSuspend
            onTriggered: root.closeThen(() => sessionManagement.suspend())
        }

        SessionMenuItem {
            text: i18n("Restart")
            iconName: "system-reboot"
            accentColor: root.accentColor
            destructive: true
            visible: sessionManagement.canReboot
            onTriggered: root.closeThen(() => sessionManagement.requestReboot(Sessions.SessionManagement.ForcePrompt))
        }

        SessionMenuItem {
            text: i18n("Shut Down")
            iconName: "system-shutdown"
            accentColor: root.accentColor
            destructive: true
            visible: sessionManagement.canShutdown
            onTriggered: root.closeThen(() => sessionManagement.requestShutdown(Sessions.SessionManagement.ForcePrompt))
        }
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.topMargin: 28
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            source: "start-here-kde"
        }

        Item { Layout.preferredHeight: 14 }

        RailButton {
            visible: root.showDocumentsShortcut
            iconName: "user-home"
            label: root.homeShortcutLabel || i18n("Home")
            onClicked: Qt.openUrlExternally(root.homeShortcutUrl
                                             || StandardPaths.writableLocation(StandardPaths.HomeLocation))
        }
        RailButton {
            visible: root.showPicturesShortcut
            iconName: "folder-pictures"
            label: root.picturesShortcutLabel || i18n("Pictures")
            onClicked: Qt.openUrlExternally(root.picturesShortcutUrl
                                             || StandardPaths.writableLocation(StandardPaths.PicturesLocation))
        }
        RailButton {
            visible: root.showSystemSettingsShortcut
            iconName: "settings-configure"
            label: i18n("System")
            onClicked: { Qt.openUrlExternally("systemsettings:"); root.closeRequested() }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 44
            Layout.preferredHeight: 1
            color: Qt.rgba(1, 1, 1, 0.16)
        }

        RailButton {
            iconName: "view-list-text"
            label: i18n("Apps")
            active: root.appListVisible
            onClicked: root.appListToggleRequested()
        }

        RailButton {
            id: launcherSettingsButton
            iconName: "settings-configure"
            label: i18n("Launcher")
            active: root.launcherSettingsVisible
            onClicked: root.launcherSettingsRequested()
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 44
            Layout.preferredHeight: 1
            color: Qt.rgba(1, 1, 1, 0.16)
        }
    }

    ColumnLayout {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        RailButton {
            id: userButton
            iconName: "user-identity"
            label: i18n("User")
            enabled: sessionManagement.canLock || sessionManagement.canSwitchUser || sessionManagement.canLogout
            onClicked: userMenu.open()
        }
        RailButton {
            id: powerButton
            iconName: "system-shutdown"
            label: i18n("Power")
            enabled: sessionManagement.canSuspend || sessionManagement.canReboot || sessionManagement.canShutdown
            onClicked: powerMenu.open()
        }
    }
}
