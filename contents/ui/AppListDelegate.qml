import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.ItemDelegate {
    id: root

    required property string appName
    required property var appIcon
    signal activated()
    signal contextRequested(real x, real y)

    hoverEnabled: true
    leftPadding: 8
    rightPadding: 8
    onClicked: activated()

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: eventPoint => root.contextRequested(eventPoint.position.x, eventPoint.position.y)
    }

    contentItem: Row {
        spacing: 12

        Kirigami.Icon {
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
            source: root.appIcon
        }

        QQC2.Label {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 42
            text: root.appName
            color: "white"
            font.pixelSize: 14
            elide: Text.ElideRight
        }
    }

    background: Rectangle {
        color: root.down ? Qt.rgba(1, 1, 1, 0.18) : root.hovered ? Qt.rgba(1, 1, 1, 0.09) : "transparent"
        radius: 2
    }
}
