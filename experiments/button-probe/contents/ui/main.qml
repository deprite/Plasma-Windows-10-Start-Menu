import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    Plasmoid.icon: Plasmoid.configuration.icon || "dialog-ok"
    Plasmoid.title: i18n("Plasma Button Probe")
    toolTipMainText: Plasmoid.title
    toolTipSubText: i18n("Independent desktop button test")
    activationTogglesExpanded: true
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
        ? fullRepresentation
        : null
    property int clickCount: 0
    property string resultText: i18n("Waiting for a click…")

    compactRepresentation: PlasmaComponents3.ToolButton {
        icon.name: Plasmoid.icon
        Accessible.name: i18n("Open button probe")
        onClicked: {
            root.clickCount += 1
            root.resultText = i18np("Success — panel button clicked once.",
                "Success — panel button clicked %1 times.", root.clickCount)
            root.expanded = !root.expanded
        }
    }

    fullRepresentation: Rectangle {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        Layout.minimumHeight: Kirigami.Units.gridUnit * 9
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        Layout.preferredHeight: Kirigami.Units.gridUnit * 12

        color: Kirigami.Theme.backgroundColor
        border.color: Kirigami.Theme.textColor
        border.width: 1
        radius: Kirigami.Units.smallSpacing

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Independent widget test")
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
            }

            QQC2.Button {
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Test button")
                icon.name: Plasmoid.icon
                onClicked: {
                    root.clickCount += 1
                    root.resultText = i18np("Success — the button clicked once.",
                        "Success — the button clicked %1 times.", root.clickCount)
                }
            }

            QQC2.Label {
                id: resultLabel
                Layout.fillWidth: true
                text: root.resultText
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillHeight: true }
        }
    }
}
