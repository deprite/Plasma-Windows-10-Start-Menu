import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.ItemDelegate {
    id: root

    required property string resultName
    required property var resultIcon
    property string resultDescription: ""
    signal activated()
    signal contextRequested(real x, real y)

    implicitHeight: 68
    hoverEnabled: true
    Accessible.name: resultName
    onClicked: root.activated()

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: eventPoint => root.contextRequested(eventPoint.position.x, eventPoint.position.y)
    }

    contentItem: RowLayout {
        spacing: 16

        Kirigami.Icon {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 38
            source: root.resultIcon
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            QQC2.Label {
                Layout.fillWidth: true
                text: root.resultName
                color: "white"
                font.pixelSize: 17
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            QQC2.Label {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.resultDescription
                color: Qt.rgba(1, 1, 1, 0.68)
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }
    }

    background: Rectangle {
        color: root.down
            ? Qt.rgba(1, 1, 1, 0.22)
            : root.highlighted
                ? Qt.rgba(1, 1, 1, 0.18)
                : root.hovered
                    ? Qt.rgba(1, 1, 1, 0.12)
                    : "transparent"
        radius: 4
    }
}
