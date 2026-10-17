import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.AbstractButton {
    id: root

    required property string appName
    required property var appIcon
    required property color accentColor
    required property string appId
    required property int groupIndex
    required property int appIndex
    signal activated()
    signal contextRequested(real x, real y)
    signal dragStarted()
    signal dragFinished(real sceneX, real sceneY)

    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: appName
    Accessible.role: Accessible.Button
    onClicked: activated()

    property real dragStartX: 0
    property real dragStartY: 0

    DragHandler {
        id: dragHandler
        target: root
        onActiveChanged: {
            if (active) {
                root.dragStartX = root.x
                root.dragStartY = root.y
                root.dragStarted()
            } else {
                const scenePoint = root.mapToItem(null, root.width / 2, root.height / 2)
                root.dragFinished(scenePoint.x, scenePoint.y)
                root.x = root.dragStartX
                root.y = root.dragStartY
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: eventPoint => root.contextRequested(eventPoint.position.x, eventPoint.position.y)
    }

    scale: down ? 0.975 : dragHandler.active ? 1.04 : 1
    opacity: dragHandler.active ? 0.72 : 1
    Behavior on scale { NumberAnimation { duration: 80 } }

    background: Rectangle {
        color: root.accentColor
        border.color: root.activeFocus ? "white" : root.hovered ? Qt.rgba(1, 1, 1, 0.72) : Qt.rgba(1, 1, 1, 0.13)
        border.width: root.activeFocus ? 2 : 1
        radius: 3
    }

    contentItem: Item {
        Kirigami.Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -9
            width: Math.min(64, parent.width * 0.42)
            height: width
            source: root.appIcon
        }

        QQC2.Label {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            text: root.appName
            color: "white"
            font.pixelSize: 14
            elide: Text.ElideRight
        }
    }
}
