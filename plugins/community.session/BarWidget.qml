import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "components/polish" as Polish

BarWidget {
    id: root
    moduleName: "community.session"
    property bool opened: false
    property bool canForce: false
    property string pendingAction: ""
    property string feedback: "Save your work before leaving"
    function open() { pendingAction = ""; canForce = false; feedback = "Save your work before leaving"; opened = true; }
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
            Text { width: parent.width; text: root.pendingAction ? "Select again to confirm · Escape to cancel" : root.feedback; wrapMode: Text.WordWrap; color: Theme.textSecondary; font.family: Style.font.family; font.pixelSize: Style.font.body }
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
                Keys.onEscapePressed: { if (root.pendingAction) root.pendingAction = ""; else root.close(); }
            }
            Button { width: parent.width; focusable: true; bordered: true; text: root.pendingAction === "switch" ? "Confirm desktop switch" : "Switch desktop"; enabled: !action.running; onClicked: root.request("switch") }
            Button { width: parent.width; focusable: true; bordered: true; visible: root.canForce; opacity: visible ? 1 : 0; text: root.pendingAction === "force" ? "Confirm force logout" : "Force logout"; enabled: !action.running; onClicked: root.request("force"); Behavior on opacity { NumberAnimation { duration: Motion.micro } } }
            Button { width: parent.width; focusable: true; bordered: true; text: root.pendingAction === "restart" ? "Confirm restart" : "Restart"; enabled: !action.running; onClicked: root.request("restart") }
            Button { width: parent.width; focusable: true; bordered: true; text: root.pendingAction === "shutdown" ? "Confirm shutdown" : "Power off"; enabled: !action.running; onClicked: root.request("shutdown") }
            Button { width: parent.width; focusable: true; text: "Cancel"; enabled: !action.running; onClicked: root.close() }
        }
    }
    function request(kind) {
        if (action.running) return;
        if (kind === "lock" || kind === "sleep") {
            action.command = kind === "lock" ? ["loginctl", "lock-session"] : ["systemctl", "suspend"];
            action.running = true; return;
        }
        if (kind === "force" && !canForce) return;
        if (kind === "force") feedback = "Unsaved changes can be lost.";
        if (kind === "switch") feedback = "Choose your environment in the login screen.";
        if (pendingAction !== kind) { pendingAction = kind; return; }
        pendingAction = "";
        feedback = kind === "logout" ? "Waiting for applications to close…" : "Applying your choice…";
        action.command = kind === "logout" ? ["multienv-logout"] : kind === "switch" ? ["multienv-logout", "--greeter"] : kind === "force" ? ["multienv-logout", "--force", "--timeout", "0"] : ["systemctl", kind === "restart" ? "reboot" : "poweroff"];
        action.running = true;
    }
    Process {
        id: action
        onExited: (code, status) => {
            root.canForce = code === 2;
            if (code !== 0) root.feedback = code === 2 ? "Save or close remaining windows, or explicitly force logout." : code === 3 ? "Autologin is active. Restore the manual greeter with multienv fallback before switching." : "The action could not finish. Please try again.";
            else root.opened = false;
        }
    }
}
