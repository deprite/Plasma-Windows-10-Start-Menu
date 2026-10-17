import QtQuick
import QtCore
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.kicker as Kicker

FocusScope {
    id: root

    signal closeRequested()
    onCloseRequested: resetSearch()
    Layout.minimumWidth: 900
    Layout.minimumHeight: 620
    Layout.preferredWidth: 1400
    Layout.preferredHeight: 820
    property color baseBackgroundColor: plasmoid.configuration.backgroundColor || "#08152f"
    property real backgroundOpacity: Math.max(0.35, Math.min(0.95, Number(plasmoid.configuration.backgroundOpacity)))
    property color panelColor: Qt.rgba(baseBackgroundColor.r, baseBackgroundColor.g,
                                       baseBackgroundColor.b, backgroundOpacity)
    property color baseRailColor: plasmoid.configuration.railColor || "#061126"
    property color railColor: Qt.rgba(baseRailColor.r, baseRailColor.g, baseRailColor.b,
                                      Math.min(0.96, backgroundOpacity + 0.12))
    property color tileColor: plasmoid.configuration.tileColor || "#202e4c"
    property color accentColor: plasmoid.configuration.accentColor || "#2e86de"
    property int tileUnit: Math.max(132, Math.min(176, Math.round(width / 11)))
    property int gap: 10
    property var flatApps: []
    property var appsById: ({})
    property var tileGroups: []
    property var contextApp: null
    property int contextGroupIndex: -1
    property int contextAppIndex: -1
    property int editedGroupIndex: -1
    property int colorGroupIndex: -1
    property string colorGroupProperty: ""
    property bool renameGroupMode: false
    property bool tileDragActive: false
    property bool groupDragActive: false
    property bool sharedLayoutEnabled: false
    property int sharedLayoutRevision: -1
    property bool settingsPageVisible: false
    property bool appListVisible: plasmoid.configuration.appListOpenOnLaunch
    readonly property Item keyEventTarget: groupEditorDialog.visible
                                            ? groupNameField
                                            : settingsPageVisible ? null : root
    readonly property bool transientDialogOpen: (groupColorDialogLoader.item
                                                 && groupColorDialogLoader.item.visible)
                                                || (settingsPageVisible && settingsPage.folderDialogVisible)
    readonly property bool searchActive: searchField.text.trim().length > 0
    readonly property var searchResultsModel: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null

    Settings {
        id: sharedLayoutSettings
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation)
                  + "/plasma-start-screen-layout.ini"
        category: "Layout"
    }

    focus: true
    Keys.onEscapePressed: root.handleEscape()
    Keys.onPressed: event => {
        if (groupEditorDialog.visible) {
            event.accepted = false
            return
        }
        if (settingsPageVisible) {
            event.accepted = false
            return
        }
        if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z
                && !searchField.activeFocus) {
            searchField.forceActiveFocus()
        }
    }

    Kicker.AppsModel {
        id: appsModel
        appletInterface: plasmoid
        autoPopulate: true
        flat: false
        sorted: true
        showSeparators: false
        showTopLevelItems: false
    }

    Kicker.RunnerModel {
        id: runnerModel
        appletInterface: plasmoid
        runners: ["krunner_services"]
        mergeResults: true
        query: root.searchActive ? searchField.text.trim() : ""
    }

    Connections {
        target: appsModel
        function onCountChanged() { rebuildTimer.restart() }
        function onModelReset() { rebuildTimer.restart() }
    }

    Timer {
        id: rebuildTimer
        interval: 250
        onTriggered: root.rebuildApps()
    }

    function rebuildApps() {
        let entries = []
        let byId = {}
        for (let categoryRow = 0; categoryRow < appsModel.count; ++categoryRow) {
            const categoryModel = appsModel.modelForRow(categoryRow)
            if (!categoryModel) continue
            for (let appRow = 0; appRow < categoryModel.count; ++appRow) {
                const appIndex = categoryModel.index(appRow, 0)
                const name = categoryModel.data(appIndex, Qt.DisplayRole)
                const favoriteId = categoryModel.data(appIndex, Qt.UserRole + 3)
                if (name && favoriteId) {
                    const stableId = String(favoriteId)
                    if (byId[stableId]) continue
                    const entry = {
                        id: stableId,
                        name: String(name),
                        icon: categoryModel.data(appIndex, Qt.DecorationRole),
                        sourceModel: categoryModel,
                        sourceRow: appRow
                    }
                    entries.push(entry)
                    byId[entry.id] = entry
                }
            }
        }
        entries.sort((a, b) => a.name.localeCompare(b.name))
        flatApps = entries
        appsById = byId
        ensureTileLayout()
    }

    function appSection(name) {
        const trimmedName = String(name || "").trim()
        if (trimmedName.length === 0) return "#"
        const firstCharacter = trimmedName.charAt(0)
        return firstCharacter.toLocaleUpperCase() !== firstCharacter.toLocaleLowerCase()
            ? firstCharacter.toLocaleUpperCase()
            : "#"
    }

    function normalizedGroups(groups) {
        let clean = []
        if (!Array.isArray(groups)) return clean
        for (let i = 0; i < groups.length; ++i) {
            const group = groups[i]
            if (!group || !Array.isArray(group.apps)) continue
            clean.push({
                id: String(group.id || ("group-" + i)),
                title: String(group.title || i18n("Group %1", i + 1)),
                columns: Math.max(2, Math.min(6, Math.round(Number(group.columns) || 2))),
                outlineColor: String(group.outlineColor || ""),
                tileColor: String(group.tileColor || ""),
                apps: group.apps.map(appId => String(appId))
            })
        }
        return clean
    }

    function defaultTileGroups() {
        const ids = flatApps.map(entry => entry.id)
        return [
            { id: "create", title: i18n("Create"), columns: 2, apps: ids.slice(0, 6) },
            { id: "everyday", title: i18n("Everyday"), columns: 2, apps: ids.slice(6, 12) },
            { id: "explore", title: i18n("Explore"), columns: 2, apps: ids.slice(12, 18) }
        ]
    }

    function ensureTileLayout() {
        if (flatApps.length === 0) return
        if (refreshSharedLayout()) return
        const stored = String(plasmoid.configuration.tileLayout || "")
        if (stored.length > 0) {
            try {
                tileGroups = normalizedGroups(JSON.parse(stored))
                return
            } catch (error) {
                console.warn("Ignoring invalid tile layout:", error)
            }
        }
        saveTileGroups(defaultTileGroups())
    }

    function saveTileGroups(groups) {
        const clean = normalizedGroups(groups)
        tileGroups = clean
        const encoded = JSON.stringify(clean)
        plasmoid.configuration.tileLayout = encoded
        if (sharedLayoutEnabled) {
            sharedLayoutSettings.setValue("tileLayout", encoded)
            sharedLayoutRevision = Number(sharedLayoutSettings.value("revision", 0)) + 1
            sharedLayoutSettings.setValue("revision", sharedLayoutRevision)
            sharedLayoutSettings.sync()
        }
    }

    function refreshSharedLayout() {
        sharedLayoutSettings.sync()
        sharedLayoutEnabled = Boolean(sharedLayoutSettings.value("enabled", false))
        if (!sharedLayoutEnabled) return false

        const revision = Number(sharedLayoutSettings.value("revision", 0))
        const stored = String(sharedLayoutSettings.value("tileLayout", ""))
        if (stored.length === 0) return false
        if (revision === sharedLayoutRevision && tileGroups.length > 0) return true
        try {
            tileGroups = normalizedGroups(JSON.parse(stored))
            applySharedPreference("appListOpenOnLaunch", true)
            applySharedPreference("showDocumentsShortcut", true)
            applySharedPreference("homeShortcutLabel", false)
            applySharedPreference("homeShortcutUrl", false)
            applySharedPreference("showPicturesShortcut", true)
            applySharedPreference("picturesShortcutLabel", false)
            applySharedPreference("picturesShortcutUrl", false)
            applySharedPreference("showSystemSettingsShortcut", true)
            applySharedPreference("backgroundColor", false)
            applySharedPreference("backgroundOpacity", false)
            applySharedPreference("railColor", false)
            applySharedPreference("tileColor", false)
            applySharedPreference("accentColor", false)
            sharedLayoutRevision = revision
            return true
        } catch (error) {
            console.warn("Ignoring invalid shared tile layout:", error)
            return false
        }
    }

    function applySharedPreference(key, booleanValue) {
        const missing = "__plasma_start_screen_missing__"
        const value = sharedLayoutSettings.value(key, missing)
        if (value !== missing) {
            plasmoid.configuration[key] = booleanValue
                    ? value === true || value === 1 || value === "true"
                    : String(value)
        }
    }

    function setLauncherPreference(key, value) {
        plasmoid.configuration[key] = value
        if (sharedLayoutEnabled) {
            sharedLayoutSettings.setValue(key, value)
            sharedLayoutRevision = Number(sharedLayoutSettings.value("revision", 0)) + 1
            sharedLayoutSettings.setValue("revision", sharedLayoutRevision)
            sharedLayoutSettings.sync()
        }
    }

    function publishSharedLayout() {
        const clean = normalizedGroups(tileGroups)
        const encoded = JSON.stringify(clean)
        sharedLayoutSettings.sync()
        const revision = Number(sharedLayoutSettings.value("revision", 0)) + 1
        sharedLayoutSettings.setValue("tileLayout", encoded)
        sharedLayoutSettings.setValue("appListOpenOnLaunch", plasmoid.configuration.appListOpenOnLaunch)
        sharedLayoutSettings.setValue("showDocumentsShortcut", plasmoid.configuration.showDocumentsShortcut)
        sharedLayoutSettings.setValue("homeShortcutLabel", plasmoid.configuration.homeShortcutLabel)
        sharedLayoutSettings.setValue("homeShortcutUrl", plasmoid.configuration.homeShortcutUrl)
        sharedLayoutSettings.setValue("showPicturesShortcut", plasmoid.configuration.showPicturesShortcut)
        sharedLayoutSettings.setValue("picturesShortcutLabel", plasmoid.configuration.picturesShortcutLabel)
        sharedLayoutSettings.setValue("picturesShortcutUrl", plasmoid.configuration.picturesShortcutUrl)
        sharedLayoutSettings.setValue("showSystemSettingsShortcut", plasmoid.configuration.showSystemSettingsShortcut)
        sharedLayoutSettings.setValue("backgroundColor", plasmoid.configuration.backgroundColor)
        sharedLayoutSettings.setValue("backgroundOpacity", plasmoid.configuration.backgroundOpacity)
        sharedLayoutSettings.setValue("railColor", plasmoid.configuration.railColor)
        sharedLayoutSettings.setValue("tileColor", plasmoid.configuration.tileColor)
        sharedLayoutSettings.setValue("accentColor", plasmoid.configuration.accentColor)
        sharedLayoutSettings.setValue("revision", revision)
        sharedLayoutSettings.setValue("enabled", true)
        sharedLayoutSettings.sync()
        sharedLayoutEnabled = true
        sharedLayoutRevision = revision
        plasmoid.configuration.tileLayout = encoded
    }

    function prepareToOpen() {
        dismissTransientUi()
        refreshSharedLayout()
        appListVisible = plasmoid.configuration.appListOpenOnLaunch
    }

    function resetSearch() {
        searchField.clear()
    }

    function dismissTransientUi() {
        resetSearch()
        appContextMenu.close()
        tileContextMenu.close()
        groupEditorDialog.close()
        deleteGroupDialog.close()
        if (groupColorDialogLoader.item) groupColorDialogLoader.item.close()
        settingsPage.closeTransientDialogs()
        utilityRail.closeTransientMenus()
        for (let index = 0; index < tileGroupRepeater.count; ++index) {
            const group = tileGroupRepeater.itemAt(index)
            if (group) group.closeTransientMenus()
        }
        settingsPageVisible = false
        contextApp = null
        contextGroupIndex = -1
        contextAppIndex = -1
        editedGroupIndex = -1
        colorGroupIndex = -1
        colorGroupProperty = ""
        renameGroupMode = false
        tileDragActive = false
        groupDragActive = false
    }

    function copiedGroups() {
        return JSON.parse(JSON.stringify(tileGroups))
    }

    function addAppToGroup(entry, groupIndex) {
        if (!entry || !entry.id || groupIndex < 0 || groupIndex >= tileGroups.length) return
        let groups = copiedGroups()
        if (!groups[groupIndex].apps.includes(entry.id)) {
            groups[groupIndex].apps.push(entry.id)
            saveTileGroups(groups)
        }
    }

    function comparableAppId(appId) {
        let value = String(appId || "").trim().toLocaleLowerCase()
        if (value.startsWith("applications:")) value = value.slice(13)
        if (value.startsWith("file://")) value = value.slice(7)
        const slash = value.lastIndexOf("/")
        if (slash >= 0) value = value.slice(slash + 1)
        if (value.endsWith(".desktop")) value = value.slice(0, -8)
        return value
    }

    function resolveSearchApp(favoriteId, displayName) {
        const rawId = String(favoriteId || "")
        if (rawId.length > 0 && appsById[rawId]) return appsById[rawId]

        const wantedId = comparableAppId(rawId)
        if (wantedId.length > 0) {
            for (let i = 0; i < flatApps.length; ++i) {
                if (comparableAppId(flatApps[i].id) === wantedId) return flatApps[i]
            }
        }

        const wantedName = String(displayName || "").trim().toLocaleLowerCase()
        if (wantedName.length > 0) {
            for (let i = 0; i < flatApps.length; ++i) {
                if (flatApps[i].name.trim().toLocaleLowerCase() === wantedName) return flatApps[i]
            }
        }
        return null
    }

    function removeTile(groupIndex, appIndex) {
        if (groupIndex < 0 || groupIndex >= tileGroups.length) return
        let groups = copiedGroups()
        if (appIndex < 0 || appIndex >= groups[groupIndex].apps.length) return
        groups[groupIndex].apps.splice(appIndex, 1)
        saveTileGroups(groups)
    }

    function moveTile(sourceGroup, sourceIndex, targetGroup, targetIndex) {
        if (sourceGroup < 0 || sourceGroup >= tileGroups.length
                || targetGroup < 0 || targetGroup >= tileGroups.length) return
        let groups = copiedGroups()
        if (sourceIndex < 0 || sourceIndex >= groups[sourceGroup].apps.length) return
        const appId = groups[sourceGroup].apps[sourceIndex]
        groups[sourceGroup].apps.splice(sourceIndex, 1)
        if (sourceGroup === targetGroup && sourceIndex < targetIndex) --targetIndex
        const duplicateIndex = groups[targetGroup].apps.indexOf(appId)
        if (duplicateIndex >= 0) {
            groups[targetGroup].apps.splice(duplicateIndex, 1)
            if (duplicateIndex < targetIndex) --targetIndex
        }
        targetIndex = Math.max(0, Math.min(targetIndex, groups[targetGroup].apps.length))
        groups[targetGroup].apps.splice(targetIndex, 0, appId)
        saveTileGroups(groups)
    }

    function finishTileDrag(sourceGroup, sourceIndex, sceneX, sceneY) {
        tileDragActive = false
        for (let i = 0; i < tileGroupRepeater.count; ++i) {
            const group = tileGroupRepeater.itemAt(i)
            if (!group) continue
            const point = group.mapFromItem(null, sceneX, sceneY)
            if (point.x >= 0 && point.x <= group.width
                    && point.y >= 0 && point.y <= group.height) {
                moveTile(sourceGroup, sourceIndex, i, group.dropIndexAt(point.x, point.y))
                return
            }
        }
    }

    function createGroup(title) {
        let groups = copiedGroups()
        groups.push({
            id: "group-" + Date.now() + "-" + Math.floor(Math.random() * 100000),
            title: title,
            columns: 2,
            apps: []
        })
        saveTileGroups(groups)
    }

    function setGroupColumns(groupIndex, columns) {
        if (groupIndex < 0 || groupIndex >= tileGroups.length) return
        let groups = copiedGroups()
        groups[groupIndex].columns = Math.max(2, Math.min(6, Math.round(columns)))
        saveTileGroups(groups)
    }

    function setGroupColor(groupIndex, propertyName, colorValue) {
        if (groupIndex < 0 || groupIndex >= tileGroups.length) return
        let groups = copiedGroups()
        groups[groupIndex][propertyName] = String(colorValue || "")
        saveTileGroups(groups)
    }

    function resetGroupColors(groupIndex) {
        if (groupIndex < 0 || groupIndex >= tileGroups.length) return
        let groups = copiedGroups()
        groups[groupIndex].outlineColor = ""
        groups[groupIndex].tileColor = ""
        saveTileGroups(groups)
    }

    function reorderGroup(sourceIndex, insertionIndex) {
        if (sourceIndex < 0 || sourceIndex >= tileGroups.length) return
        let groups = copiedGroups()
        const movedGroup = groups.splice(sourceIndex, 1)[0]
        if (sourceIndex < insertionIndex) --insertionIndex
        insertionIndex = Math.max(0, Math.min(insertionIndex, groups.length))
        groups.splice(insertionIndex, 0, movedGroup)
        saveTileGroups(groups)
    }

    function finishGroupDrag(sourceIndex, sceneX, sceneY) {
        groupDragActive = false
        for (let i = 0; i < tileGroupRepeater.count; ++i) {
            if (i === sourceIndex) continue
            const group = tileGroupRepeater.itemAt(i)
            if (!group) continue
            const point = group.mapFromItem(null, sceneX, sceneY)
            if (point.x >= 0 && point.x <= group.width
                    && point.y >= 0 && point.y <= group.height) {
                reorderGroup(sourceIndex, i + (point.x > group.width / 2 ? 1 : 0))
                return
            }
        }
    }

    function groupAccent(groupIndex) {
        if (groupIndex >= 0 && groupIndex < tileGroups.length
                && tileGroups[groupIndex].outlineColor) {
            return tileGroups[groupIndex].outlineColor
        }
        const accents = ["#6d42dc", root.accentColor, "#008b9a", "#b34b70", "#39734d"]
        return accents[groupIndex % accents.length]
    }

    function groupTileColor(groupIndex) {
        return groupIndex >= 0 && groupIndex < tileGroups.length
                && tileGroups[groupIndex].tileColor
            ? tileGroups[groupIndex].tileColor
            : root.tileColor
    }

    function chooseGroupOutlineColor(groupIndex) {
        openGroupColorDialog(groupIndex, "outlineColor", groupAccent(groupIndex))
    }

    function chooseGroupTileColor(groupIndex) {
        openGroupColorDialog(groupIndex, "tileColor", groupTileColor(groupIndex))
    }

    function openGroupColorDialog(groupIndex, propertyName, initialColor) {
        colorGroupIndex = groupIndex
        colorGroupProperty = propertyName
        // Recreate the dialog for each use. Reopening a ColorDialog can leave
        // its color plane blank on some Plasma setups.
        groupColorDialogLoader.active = false
        groupColorDialogLoader.active = true
        Qt.callLater(function() {
            if (!groupColorDialogLoader.item) return
            groupColorDialogLoader.item.selectedColor = initialColor
            groupColorDialogLoader.item.open()
        })
    }

    function renameGroup(groupIndex, title) {
        if (groupIndex < 0 || groupIndex >= tileGroups.length) return
        let groups = copiedGroups()
        groups[groupIndex].title = title
        saveTileGroups(groups)
    }

    function deleteGroup(groupIndex) {
        if (groupIndex < 0 || groupIndex >= tileGroups.length) return
        let groups = copiedGroups()
        groups.splice(groupIndex, 1)
        saveTileGroups(groups)
    }

    function openAppContext(entry, item, x, y) {
        if (!entry || !entry.id) return
        contextApp = entry
        appContextMenu.parent = item
        appContextMenu.x = x
        appContextMenu.y = y
        appContextMenu.open()
    }

    function openTileContext(groupIndex, appIndex, item, x, y) {
        contextGroupIndex = groupIndex
        contextAppIndex = appIndex
        tileContextMenu.parent = item
        tileContextMenu.x = x
        tileContextMenu.y = y
        tileContextMenu.open()
    }

    function openGroupEditor(groupIndex) {
        renameGroupMode = groupIndex >= 0
        editedGroupIndex = groupIndex
        groupNameField.text = renameGroupMode ? tileGroups[groupIndex].title : ""
        groupEditorDialog.open()
    }

    function matches(text) {
        return searchField.text.length === 0
            || String(text).toLocaleLowerCase().includes(searchField.text.toLocaleLowerCase())
    }

    function launch(entry) {
        if (!entry || !entry.sourceModel) return
        entry.sourceModel.trigger(entry.sourceRow, "", null)
        root.closeRequested()
    }

    function launchSearchResult(row) {
        const results = root.searchResultsModel
        if (!results || row < 0 || row >= results.count) return
        if (results.trigger(row, "", null)) {
            root.closeRequested()
        }
    }

    function handleEscape() {
        if (settingsPageVisible) {
            settingsPageVisible = false
            forceActiveFocus()
            return
        }
        if (searchField.text.length > 0) {
            searchField.clear()
            searchField.forceActiveFocus()
        } else {
            root.closeRequested()
        }
    }

    QQC2.Menu {
        id: appContextMenu

        QQC2.MenuItem {
            text: i18n("Add to group")
            enabled: false
        }

        QQC2.MenuSeparator { }

        Repeater {
            model: root.tileGroups

            QQC2.MenuItem {
                required property int index
                required property var modelData
                text: modelData.title
                icon.name: "list-add"
                enabled: root.contextApp && !modelData.apps.includes(root.contextApp.id)
                onTriggered: root.addAppToGroup(root.contextApp, index)
            }
        }

        QQC2.MenuItem {
            visible: root.tileGroups.length === 0
            text: i18n("Create a group first")
            enabled: false
        }
    }

    QQC2.Menu {
        id: tileContextMenu

        QQC2.MenuItem {
            text: i18n("Remove from group")
            icon.name: "list-remove"
            onTriggered: root.removeTile(root.contextGroupIndex, root.contextAppIndex)
        }

        QQC2.MenuSeparator {
            visible: root.tileGroups.length > 1
        }

        Repeater {
            model: root.tileGroups

            QQC2.MenuItem {
                required property int index
                required property var modelData
                visible: index !== root.contextGroupIndex
                text: i18n("Move to %1", modelData.title)
                icon.name: "go-next"
                onTriggered: root.moveTile(root.contextGroupIndex, root.contextAppIndex, index, modelData.apps.length)
            }
        }
    }

    Loader {
        id: groupColorDialogLoader
        active: false

        sourceComponent: ColorDialog {
            title: root.colorGroupProperty === "outlineColor"
                ? i18n("Choose drag highlight color")
                : i18n("Choose group tile color")
            options: ColorDialog.DontUseNativeDialog
            onAccepted: {
                root.setGroupColor(root.colorGroupIndex,
                                   root.colorGroupProperty,
                                   selectedColor.toString())
                Qt.callLater(() => groupColorDialogLoader.active = false)
            }
            onRejected: Qt.callLater(() => groupColorDialogLoader.active = false)
        }
    }

    QQC2.Dialog {
        id: groupEditorDialog
        anchors.centerIn: parent
        width: 420
        modal: true
        focus: true
        title: root.renameGroupMode ? i18n("Rename group") : i18n("New group")
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        onOpened: {
            Qt.callLater(function() {
                groupNameField.forceActiveFocus()
                groupNameField.selectAll()
            })
        }
        onAccepted: {
            const title = groupNameField.text.trim()
            if (title.length === 0) return
            if (root.renameGroupMode) {
                root.renameGroup(root.editedGroupIndex, title)
            } else {
                root.createGroup(title)
            }
        }

        contentItem: QQC2.TextField {
            id: groupNameField
            placeholderText: i18n("Group name")
            selectByMouse: true
            focus: true
            onAccepted: groupEditorDialog.accept()
        }
    }

    QQC2.Dialog {
        id: deleteGroupDialog
        anchors.centerIn: parent
        width: 440
        modal: true
        title: i18n("Delete group?")
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No
        onAccepted: root.deleteGroup(root.editedGroupIndex)

        contentItem: QQC2.Label {
            text: i18n("The group will be removed. Its applications remain installed and can be added to another group.")
            wrapMode: Text.WordWrap
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.panelColor
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        UtilityRail {
            id: utilityRail
            Layout.fillHeight: true
            Layout.preferredWidth: 88
            backgroundColor: root.railColor
            menuColor: root.tileColor
            accentColor: root.accentColor
            appListVisible: root.appListVisible
            showDocumentsShortcut: plasmoid.configuration.showDocumentsShortcut
            homeShortcutLabel: plasmoid.configuration.homeShortcutLabel
            homeShortcutUrl: plasmoid.configuration.homeShortcutUrl
            showPicturesShortcut: plasmoid.configuration.showPicturesShortcut
            picturesShortcutLabel: plasmoid.configuration.picturesShortcutLabel
            picturesShortcutUrl: plasmoid.configuration.picturesShortcutUrl
            showSystemSettingsShortcut: plasmoid.configuration.showSystemSettingsShortcut
            onCloseRequested: root.closeRequested()
            onAppListToggleRequested: {
                root.settingsPageVisible = false
                root.appListVisible = !root.appListVisible
            }
        }

        Rectangle {
            visible: !root.settingsPageVisible && root.appListVisible
            Layout.fillHeight: true
            Layout.preferredWidth: Math.max(270, Math.min(340, root.width * 0.2))
            color: Qt.rgba(0.045, 0.075, 0.15, 0.84)

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 28
                anchors.rightMargin: 18
                anchors.topMargin: 34
                anchors.bottomMargin: 24
                spacing: 16

                QQC2.Label {
                    text: root.searchActive ? i18n("Search") : i18n("All apps")
                    color: "white"
                    font.pixelSize: 26
                    font.weight: Font.Medium
                }

                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: root.flatApps
                    visible: !root.searchActive
                    currentIndex: -1
                    boundsBehavior: Flickable.StopAtBounds
                    QQC2.ScrollBar.vertical: QQC2.ScrollBar { }

                    delegate: Item {
                        required property int index
                        required property var modelData
                        readonly property string sectionName: root.appSection(modelData.name)
                        readonly property bool startsSection: index === 0
                            || sectionName !== root.appSection(root.flatApps[index - 1].name)

                        width: appList.width - 12
                        visible: root.matches(modelData.name)
                        height: 48 + (startsSection ? 34 : 0)

                        QQC2.Label {
                            id: sectionHeading
                            anchors.top: parent.top
                            anchors.left: parent.left
                            height: parent.startsSection ? 34 : 0
                            visible: parent.startsSection
                            text: parent.sectionName
                            color: root.accentColor
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            verticalAlignment: Text.AlignVCenter
                        }

                        AppListDelegate {
                            id: appListDelegate
                            anchors.top: sectionHeading.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 48
                            appName: parent.modelData.name
                            appIcon: parent.modelData.icon
                            onActivated: root.launch(parent.modelData)
                            onContextRequested: (x, y) => root.openAppContext(parent.modelData, appListDelegate, x, y)
                        }
                    }
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.searchActive
                    text: runnerModel.querying ? i18n("Searching…") : i18n("Results appear on the right")
                    color: Qt.rgba(1, 1, 1, 0.62)
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignTop
                }
            }
        }

        Item {
            visible: !root.settingsPageVisible
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 52
                anchors.rightMargin: 48
                anchors.topMargin: 34
                anchors.bottomMargin: 30
                spacing: 22

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    QQC2.Label {
                        text: i18n("Start")
                        color: "white"
                        font.pixelSize: 31
                        font.weight: Font.Medium
                    }

                    Item { Layout.fillWidth: true }

                    QQC2.ToolButton {
                        id: launcherSettingsButton
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        hoverEnabled: true
                        Accessible.name: i18n("Launcher settings")
                        onClicked: root.settingsPageVisible = true

                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        QQC2.ToolTip.text: i18n("Launcher settings")

                        contentItem: QQC2.Label {
                            text: "•••"
                            color: "white"
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: launcherSettingsButton.down
                                ? Qt.rgba(1, 1, 1, 0.2)
                                : launcherSettingsButton.hovered
                                    ? Qt.rgba(1, 1, 1, 0.1)
                                    : "transparent"
                            radius: 3
                        }
                    }

                    QQC2.TextField {
                        id: searchField
                        Layout.preferredWidth: Math.min(420, root.width * 0.28)
                        Layout.preferredHeight: 46
                        placeholderText: i18n("Search applications")
                        color: "white"
                        font.pixelSize: 15
                        leftPadding: 42
                        rightPadding: clearSearchButton.visible ? 42 : 12
                        selectByMouse: true
                        onAccepted: root.launchSearchResult(0)

                        Kirigami.Icon {
                            anchors.left: parent.left
                            anchors.leftMargin: 13
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            source: "search"
                            color: "white"
                        }

                        QQC2.ToolButton {
                            id: clearSearchButton
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            width: 40
                            visible: searchField.text.length > 0
                            hoverEnabled: true
                            Accessible.name: i18n("Clear search")
                            onClicked: {
                                searchField.clear()
                                searchField.forceActiveFocus()
                            }

                            contentItem: Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                source: "dialog-close"
                                color: "white"
                            }

                            background: Rectangle {
                                color: clearSearchButton.down
                                    ? Qt.rgba(1, 1, 1, 0.2)
                                    : clearSearchButton.hovered
                                        ? Qt.rgba(1, 1, 1, 0.1)
                                        : "transparent"
                                radius: 3
                            }
                        }

                        background: Rectangle {
                            color: Qt.rgba(0.06, 0.09, 0.18, 0.72)
                            border.color: searchField.activeFocus ? root.accentColor : Qt.rgba(1, 1, 1, 0.24)
                            border.width: searchField.activeFocus ? 2 : 1
                            radius: 3
                        }
                    }
                }

                Flickable {
                    id: tileFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: Math.max(height, tileFlow.implicitHeight)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    visible: !root.searchActive

                    Flow {
                        id: tileFlow
                        width: tileFlick.width
                        height: implicitHeight
                        spacing: 34

                        Repeater {
                            id: tileGroupRepeater
                            model: root.tileGroups

                            TileGroup {
                                required property int index
                                required property var modelData

                                groupIndex: index
                                groupCount: root.tileGroups.length
                                groupData: modelData
                                appsById: root.appsById
                                unit: root.tileUnit
                                gap: root.gap
                                accent: root.groupAccent(index)
                                tileColor: root.groupTileColor(index)
                                dragActive: root.tileDragActive
                                groupDropActive: root.groupDragActive
                                onLaunchRequested: entry => root.launch(entry)
                                onTileContextRequested: (appIndex, item, x, y) => root.openTileContext(index, appIndex, item, x, y)
                                onTileMoveRequested: (sourceGroup, sourceIndex, targetGroup, targetIndex) => root.moveTile(sourceGroup, sourceIndex, targetGroup, targetIndex)
                                onTileDragStarted: root.tileDragActive = true
                                onTileDragFinished: (sourceGroup, sourceIndex, sceneX, sceneY) => root.finishTileDrag(sourceGroup, sourceIndex, sceneX, sceneY)
                                onRenameRequested: root.openGroupEditor(index)
                                onColumnCountRequested: columns => root.setGroupColumns(index, columns)
                                onOutlineColorRequested: root.chooseGroupOutlineColor(index)
                                onTileColorRequested: root.chooseGroupTileColor(index)
                                onColorsResetRequested: root.resetGroupColors(index)
                                onGroupMoveRequested: offset => root.reorderGroup(index, index + offset)
                                onGroupDragStarted: root.groupDragActive = true
                                onGroupDragFinished: (sourceIndex, sceneX, sceneY) => root.finishGroupDrag(sourceIndex, sceneX, sceneY)
                                onDeleteRequested: {
                                    root.editedGroupIndex = index
                                    deleteGroupDialog.open()
                                }
                            }
                        }

                        QQC2.ToolButton {
                            width: 44
                            height: 44
                            icon.name: "list-add"
                            display: QQC2.AbstractButton.IconOnly
                            hoverEnabled: true
                            Accessible.name: i18n("Add new group")
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                            QQC2.ToolTip.text: i18n("Add new group")
                            onClicked: root.openGroupEditor(-1)
                        }
                    }
                }

                ListView {
                    id: searchResults
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.searchActive && (runnerModel.querying
                        || (root.searchResultsModel && root.searchResultsModel.count > 0))
                    clip: true
                    spacing: 4
                    model: root.searchResultsModel
                    currentIndex: count > 0 ? 0 : -1
                    boundsBehavior: Flickable.StopAtBounds
                    QQC2.ScrollBar.vertical: QQC2.ScrollBar { }

                    delegate: SearchResultDelegate {
                        id: searchResultDelegate
                        required property int index
                        required property var model

                        width: searchResults.width - 16
                        highlighted: index === searchResults.currentIndex
                        resultName: String(model.display || "")
                        resultIcon: model.decoration
                        resultDescription: String(model.description || "")
                        onActivated: root.launchSearchResult(index)
                        onContextRequested: (x, y) => root.openAppContext(
                            root.resolveSearchApp(model.favoriteId, model.display),
                            searchResultDelegate, x, y)
                    }
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.searchActive && !runnerModel.querying
                        && (!root.searchResultsModel || root.searchResultsModel.count === 0)
                    text: i18n("No applications found")
                    color: Qt.rgba(1, 1, 1, 0.72)
                    font.pixelSize: 17
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        LauncherSettingsPage {
            id: settingsPage
            visible: root.settingsPageVisible
            Layout.fillWidth: true
            Layout.fillHeight: true
            sharedLayoutEnabled: root.sharedLayoutEnabled
            appListOpenOnLaunch: plasmoid.configuration.appListOpenOnLaunch
            showDocumentsShortcut: plasmoid.configuration.showDocumentsShortcut
            homeShortcutLabel: plasmoid.configuration.homeShortcutLabel
            homeShortcutUrl: plasmoid.configuration.homeShortcutUrl
            showPicturesShortcut: plasmoid.configuration.showPicturesShortcut
            picturesShortcutLabel: plasmoid.configuration.picturesShortcutLabel
            picturesShortcutUrl: plasmoid.configuration.picturesShortcutUrl
            showSystemSettingsShortcut: plasmoid.configuration.showSystemSettingsShortcut
            backgroundColor: root.baseBackgroundColor
            backgroundOpacity: root.backgroundOpacity
            railColor: root.baseRailColor
            tileColor: root.tileColor
            accentColor: root.accentColor
            onBackRequested: {
                root.settingsPageVisible = false
                root.forceActiveFocus()
            }
            onPublishSharedLayoutRequested: root.publishSharedLayout()
            onAppListOpenOnLaunchRequested: enabled => {
                root.setLauncherPreference("appListOpenOnLaunch", enabled)
                root.appListVisible = enabled
            }
            onDocumentsShortcutRequested: enabled => root.setLauncherPreference("showDocumentsShortcut", enabled)
            onHomeShortcutLabelRequested: label => root.setLauncherPreference("homeShortcutLabel", label)
            onHomeShortcutUrlRequested: url => root.setLauncherPreference("homeShortcutUrl", url)
            onPicturesShortcutRequested: enabled => root.setLauncherPreference("showPicturesShortcut", enabled)
            onPicturesShortcutLabelRequested: label => root.setLauncherPreference("picturesShortcutLabel", label)
            onPicturesShortcutUrlRequested: url => root.setLauncherPreference("picturesShortcutUrl", url)
            onSystemSettingsShortcutRequested: enabled => root.setLauncherPreference("showSystemSettingsShortcut", enabled)
            onBackgroundColorRequested: value => root.setLauncherPreference("backgroundColor", value)
            onBackgroundOpacityRequested: value => root.setLauncherPreference("backgroundOpacity", value)
            onRailColorRequested: value => root.setLauncherPreference("railColor", value)
            onTileColorRequested: value => root.setLauncherPreference("tileColor", value)
            onAccentColorRequested: value => root.setLauncherPreference("accentColor", value)
        }
    }

    Component.onCompleted: {
        forceActiveFocus()
        refreshSharedLayout()
        rebuildTimer.start()
    }
}
