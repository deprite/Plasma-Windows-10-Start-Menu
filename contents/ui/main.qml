import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root

    function toggleDashboard(): void {
        dashboardScreen.prepareToOpen()
        dashboard.toggle()
    }

    Plasmoid.icon: Plasmoid.configuration.icon || "start-here-kde"
    Plasmoid.title: i18n("Plasma Start Screen")
    toolTipMainText: Plasmoid.title
    toolTipSubText: i18n("Open the application launcher")
    activationTogglesExpanded: false

    // Global-shortcut activation can still ask Plasma to show the conventional
    // full representation. Reject that state in one direction only; the
    // dashboard has its own independent lifecycle below.
    onExpandedChanged: function() {
        if (root.expanded) {
            root.expanded = false
        }
    }

    // Keep the proven compact control and let its icon fill the panel slot.
    compactRepresentation: PlasmaComponents3.ToolButton {
        implicitWidth: 40
        implicitHeight: 40
        padding: 0
        Accessible.name: Plasmoid.title
        onClicked: root.toggleDashboard()

        contentItem: Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
        }
    }

    // Plasma needs both representations to manage the compact panel item.
    // The expanded-state guard above prevents this one from remaining open
    // when a global shortcut also opens the independent dashboard.
    fullRepresentation: StartScreen {
        onCloseRequested: root.expanded = false
    }

    Connections {
        target: Plasmoid
        function onActivated(): void {
            root.toggleDashboard()
        }
    }

    Kicker.DashboardWindow {
        id: dashboard
        visualParent: root
        // DashboardWindow normally forwards all keys to the StartScreen so
        // type-to-search works. While its editor is open, forward them to the
        // actual text field instead; otherwise the proxy bypasses popup focus.
        keyEventProxy: dashboardScreen.keyEventTarget
        // DashboardWindow asks KWin for compositor blur behind translucent
        // dashboard surfaces. The QML content supplies the configurable tint.
        backgroundColor: Qt.rgba(0, 0, 0, 0.01)

        onKeyEscapePressed: dashboardScreen.handleEscape()
        onActiveChanged: {
            if (!active && visible && !dashboardScreen.transientDialogOpen) {
                visible = false
            }
        }
        onVisibleChanged: {
            if (!visible) {
                dashboardScreen.dismissTransientUi()
            }
        }

        StartScreen {
            id: dashboardScreen
            anchors.fill: parent
            onCloseRequested: dashboard.visible = false
        }
    }
}
