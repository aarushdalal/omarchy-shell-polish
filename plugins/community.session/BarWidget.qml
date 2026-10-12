import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "components/polish" as Polish
import "components" as Session

BarWidget {
    id: root
    moduleName: "community.session"
    property bool opened: false
    property alias canForce: sessionState.canForce
    property alias pendingAction: sessionState.pending
    property alias feedback: sessionState.feedback
    property var commandOverride: null
    function open() { if (!sessionState.busy) sessionState.cancel(); opened = true; }
    Session.SessionActionState {
        id: sessionState
        onExecuteRequested: command => { action.command = root.commandOverride ? root.commandOverride(command) : command; action.running = true; }
        onSucceeded: root.opened = false
        onFailed: root.opened = true
    }
    function close() { if (!action.running) opened = false; }
    function toggle() { if (opened) close(); else open(); }
    implicitWidth: trigger.implicitWidth
    implicitHeight: trigger.implicitHeight
    BarIconButton {
        id: trigger; anchors.fill: parent; bar: root.bar
        text: "󰍃"; tooltipText: "Session"; active: root.opened
        onPressed: root.toggle()
    }
    Polish.RefinedKeyboardPanel {
        id: panel
        anchorItem: trigger; owner: root; bar: root.bar; open: root.opened
        focusTarget: logoutButton
        contentWidth: panel.fittedContentWidth(Style.space(340))
        contentHeight: panel.fittedContentHeight(actions.implicitHeight)
        Column {
            id: actions; width: parent.width; spacing: Style.space(12)
            Text { text: "Omarchy · Session"; color: Theme.textPrimary; font.family: Style.font.family; font.pixelSize: Style.font.display }
            Text { width: parent.width; text: root.feedback || "Choose an action"; wrapMode: Text.WordWrap; color: Theme.textSecondary; font.family: Style.font.family; font.pixelSize: Style.font.body }
            Row {
                width: parent.width; spacing: Style.space(8)
                Button { width: (parent.width - parent.spacing) / 2; focusable: true; text: "Lock"; enabled: !action.running; onClicked: root.request("lock") }
                Button { width: (parent.width - parent.spacing) / 2; focusable: true; text: "Sleep"; enabled: !action.running; onClicked: root.request("sleep") }
            }
            Button {
                id: logoutButton; width: parent.width; focusable: true; bordered: true
                text: root.pendingAction === "logout" ? "Confirm logout" : "Log out"
                enabled: !action.running
                onClicked: root.request("logout")
                Keys.onEscapePressed: { if (root.pendingAction) sessionState.cancel(); else root.close(); }
            }
            Button { width: parent.width; focusable: true; bordered: true; text: root.pendingAction === "switchDesktop" ? "Confirm desktop switch" : "Switch desktop"; enabled: !action.running; onClicked: root.request("switchDesktop") }
            Button { width: parent.width; focusable: true; bordered: true; visible: root.canForce; opacity: visible ? 1 : 0; text: root.pendingAction === "force" ? "Confirm force logout" : "Force logout"; enabled: !action.running; onClicked: root.request("force"); Behavior on opacity { NumberAnimation { duration: Motion.micro } } }
            Button { width: parent.width; focusable: true; bordered: true; text: root.pendingAction === "restart" ? "Confirm restart" : "Restart"; enabled: !action.running; onClicked: root.request("restart") }
            Button { width: parent.width; focusable: true; bordered: true; text: root.pendingAction === "shutdown" ? "Confirm shutdown" : "Power off"; enabled: !action.running; onClicked: root.request("shutdown") }
            Button { width: parent.width; focusable: true; text: "Cancel"; enabled: !action.running; onClicked: root.close() }
        }
    }
    function request(kind) { sessionState.request(kind); }
    Process {
        id: action
        stderr: StdioCollector { id: actionErrors }
        onExited: (code, status) => sessionState.complete(code, actionErrors.text)
        onRunningChanged: {
            if (!running && sessionState.busy) Qt.callLater(() => {
                if (!action.running && sessionState.busy) sessionState.complete(127, actionErrors.text);
            });
        }
    }
}
