import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.ToolButton {
    id: root

    required property string iconName
    required property string label
    property bool active: false

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: 72
    Layout.preferredHeight: 60
    hoverEnabled: true
    Accessible.name: label

    contentItem: Item {
        Column {
            anchors.centerIn: parent
            spacing: 4

            Kirigami.Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 25
                height: 25
                source: root.iconName
                color: "white"
            }

            QQC2.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.label
                color: "white"
                font.pixelSize: 11
            }
        }
    }

    background: Rectangle {
        color: root.down
               ? Qt.rgba(1, 1, 1, 0.2)
               : root.active ? Qt.rgba(1, 1, 1, 0.14)
               : root.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
        radius: 3
    }
}
