import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.iconthemes as KIconThemes
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: root

    property string cfg_icon: Plasmoid.configuration.icon

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
            Kirigami.FormData.label: i18n("Panel icon:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("Choose…")
                icon.name: root.cfg_icon || "dialog-ok"
                onClicked: iconDialog.open()
            }

            QQC2.Button {
                text: i18n("Reset")
                icon.name: "edit-undo"
                onClicked: root.cfg_icon = "dialog-ok"
            }
        }
    }
}
