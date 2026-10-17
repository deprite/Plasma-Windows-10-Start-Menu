import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

Item {
    id: root

    required property int groupIndex
    required property int groupCount
    required property var groupData
    required property var appsById
    required property int unit
    required property int gap
    required property color accent
    required property color tileColor
    property bool dragActive: false
    property bool groupDropActive: false
    signal launchRequested(var entry)
    signal tileContextRequested(int appIndex, var item, real x, real y)
    signal tileMoveRequested(int sourceGroup, int sourceIndex, int targetGroup, int targetIndex)
    signal tileDragStarted()
    signal tileDragFinished(int sourceGroup, int sourceIndex, real sceneX, real sceneY)
    signal renameRequested()
    signal columnCountRequested(int columns)
    signal groupMoveRequested(int offset)
    signal groupDragStarted()
    signal groupDragFinished(int sourceIndex, real sceneX, real sceneY)
    signal deleteRequested()

    readonly property var appIds: groupData && groupData.apps ? groupData.apps : []
    readonly property int columnCount: groupData
                                       ? Math.max(2, Math.min(6, Number(groupData.columns) || 2))
                                       : 2
    readonly property int rowCount: Math.max(1, Math.ceil(appIds.length / columnCount))
    property real groupDragStartX: 0
    property real groupDragStartY: 0
    property bool groupDragging: false

    width: unit * columnCount + gap * (columnCount - 1)
    height: implicitHeight
    implicitWidth: width
    implicitHeight: headerRow.height + 14 + rowCount * unit
                    + Math.max(0, rowCount - 1) * gap + gap + unit / 2

    function dropIndexAt(localX, localY) {
        const gridY = Math.max(0, localY - tileGrid.y)
        const column = Math.max(0, Math.min(root.columnCount - 1,
                                           Math.floor(localX / (root.unit + root.gap))))
        const row = Math.max(0, Math.floor(gridY / (root.unit + root.gap)))
        return Math.min(root.appIds.length, row * root.columnCount + column)
    }

    function closeTransientMenus() {
        groupMenu.close()
    }

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: root.dragActive || root.groupDropActive ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
        border.color: root.dragActive || root.groupDropActive ? root.accent : "transparent"
        border.width: 2
    }

    RowLayout {
        id: headerRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 34
        spacing: 6

        QQC2.Label {
            Layout.fillWidth: true
            text: root.groupData ? root.groupData.title : ""
            color: "white"
            font.pixelSize: 25
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        QQC2.ToolButton {
            id: groupDragHandle
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            text: "☰"
            font.pixelSize: 17
            Accessible.name: i18n("Move group")

            DragHandler {
                target: root
                onActiveChanged: {
                    root.groupDragging = active
                    if (active) {
                        root.groupDragStartX = root.x
                        root.groupDragStartY = root.y
                        root.groupDragStarted()
                    } else {
                        const scenePoint = root.mapToItem(null, root.width / 2, root.height / 2)
                        root.groupDragFinished(root.groupIndex, scenePoint.x, scenePoint.y)
                        root.x = root.groupDragStartX
                        root.y = root.groupDragStartY
                    }
                }
            }
        }

        QQC2.ToolButton {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            text: "⋯"
            font.pixelSize: 21
            Accessible.name: i18n("Edit group")
            onClicked: groupMenu.open()

            QQC2.Menu {
                id: groupMenu
                y: parent.height

                QQC2.MenuItem {
                    text: i18n("Rename group")
                    icon.name: "edit-rename"
                    onTriggered: root.renameRequested()
                }

                QQC2.Menu {
                    title: i18n("Columns")
                    icon.name: "view-grid"

                    Repeater {
                        model: 5

                        QQC2.MenuItem {
                            required property int index
                            readonly property int columnValue: index + 2
                            text: i18n("%1 columns", columnValue)
                            checkable: true
                            checked: root.columnCount === columnValue
                            onTriggered: root.columnCountRequested(columnValue)
                        }
                    }
                }

                QQC2.MenuSeparator { }

                QQC2.MenuItem {
                    text: i18n("Move earlier")
                    icon.name: "go-previous"
                    enabled: root.groupIndex > 0
                    onTriggered: root.groupMoveRequested(-1)
                }

                QQC2.MenuItem {
                    text: i18n("Move later")
                    icon.name: "go-next"
                    enabled: root.groupIndex < root.groupCount - 1
                    onTriggered: root.groupMoveRequested(2)
                }

                QQC2.MenuSeparator { }

                QQC2.MenuItem {
                    text: i18n("Delete group")
                    icon.name: "edit-delete"
                    onTriggered: root.deleteRequested()
                }
            }
        }
    }

    Grid {
        id: tileGrid
        anchors.left: parent.left
        anchors.top: headerRow.bottom
        anchors.topMargin: 14
        columns: root.columnCount
        spacing: root.gap

        Repeater {
            model: root.appIds

            AppTile {
                id: appTile
                required property int index
                required property string modelData
                property var entry: root.appsById[modelData] || null

                width: root.unit
                height: root.unit
                visible: entry !== null
                appId: modelData
                groupIndex: root.groupIndex
                appIndex: index
                appName: entry ? entry.name : i18n("Unavailable application")
                appIcon: entry ? entry.icon : "application-x-executable"
                accentColor: index === 0 ? root.accent : root.tileColor
                onActivated: root.launchRequested(entry)
                onContextRequested: (x, y) => root.tileContextRequested(index, appTile, x, y)
                onDragStarted: root.tileDragStarted()
                onDragFinished: (sceneX, sceneY) => root.tileDragFinished(root.groupIndex, index, sceneX, sceneY)
            }
        }
    }

    scale: groupDragging ? 1.02 : 1
    opacity: groupDragging ? 0.78 : 1
    z: groupDragging ? 10 : 0
    Behavior on scale { NumberAnimation { duration: 80 } }
}
