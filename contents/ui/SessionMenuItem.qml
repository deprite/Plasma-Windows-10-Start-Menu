import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.MenuItem {
    id: root

    required property string iconName
    required property color accentColor
    property bool destructive: false

    implicitWidth: 224
    implicitHeight: 52
    leftPadding: 14
    rightPadding: 14
    hoverEnabled: true

    contentItem: RowLayout {
        spacing: 12

        Kirigami.Icon {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            source: root.iconName
            color: "white"
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: root.text
            color: "white"
            font.pixelSize: 15
            font.weight: Font.Medium
            verticalAlignment: Text.AlignVCenter
        }
    }

    background: Rectangle {
        color: root.down
            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.92)
            : root.highlighted
                ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.68)
                : root.destructive
                    ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16)
                    : "transparent"
        radius: 4
    }
}
