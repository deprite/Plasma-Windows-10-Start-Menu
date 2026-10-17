import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.iconthemes as KIconThemes
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: root

    property string cfg_icon
    property string cfg_iconDefault
    property string cfg_tileLayout
    property string cfg_tileLayoutDefault
    property bool cfg_appListOpenOnLaunch
    property bool cfg_appListOpenOnLaunchDefault
    property bool cfg_showDocumentsShortcut
    property bool cfg_showDocumentsShortcutDefault
    property string cfg_homeShortcutLabel
    property string cfg_homeShortcutLabelDefault
    property string cfg_homeShortcutUrl
    property string cfg_homeShortcutUrlDefault
    property bool cfg_showPicturesShortcut
    property bool cfg_showPicturesShortcutDefault
    property string cfg_picturesShortcutLabel
    property string cfg_picturesShortcutLabelDefault
    property string cfg_picturesShortcutUrl
    property string cfg_picturesShortcutUrlDefault
    property bool cfg_showSystemSettingsShortcut
    property bool cfg_showSystemSettingsShortcutDefault
    property string cfg_backgroundColor
    property string cfg_backgroundColorDefault
    property real cfg_backgroundOpacity
    property real cfg_backgroundOpacityDefault
    property string cfg_railColor
    property string cfg_railColorDefault
    property string cfg_tileColor
    property string cfg_tileColorDefault
    property string cfg_accentColor
    property string cfg_accentColorDefault

    KIconThemes.IconDialog {
        id: iconDialog
        onIconNameChanged: iconName => {
            if (iconName) {
                root.cfg_icon = iconName
            }
        }
    }

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Launcher icon:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("Choose…")
                icon.name: root.cfg_icon || "start-here-kde"
                onClicked: iconDialog.open()
            }

            QQC2.Button {
                text: i18n("Reset")
                icon.name: "edit-undo"
                onClicked: root.cfg_icon = "start-here-kde"
            }
        }
    }
}
