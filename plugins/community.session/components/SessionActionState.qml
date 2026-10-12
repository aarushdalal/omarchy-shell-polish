// SPDX-License-Identifier: MIT
import QtQuick
QtObject {
    id: root
    property string pending: ""
    property string activeKind: ""
    property bool busy: false
    property bool canForce: false
    property string feedback: ""
    signal executeRequested(var command)
    signal succeeded()
    signal failed()
    function commandFor(kind) {
        var commands = {
            lock: ["loginctl", "lock-session"], sleep: ["systemctl", "suspend"],
            logout: ["multienv-logout"], switchDesktop: ["multienv-logout", "--greeter"],
            force: ["multienv-logout", "--force", "--timeout", "0"],
            shutdown: ["systemctl", "poweroff"], restart: ["systemctl", "reboot"],
            hibernate: ["systemctl", "hibernate"]
        };
        return commands[kind] || [];
    }
    function labelFor(kind) {
        return ({lock: qsTr("Lock"), sleep: qsTr("Sleep"), logout: qsTr("Log out"),
            switchDesktop: qsTr("Switch desktop"), force: qsTr("Force logout"),
            shutdown: qsTr("Power off"), restart: qsTr("Restart"), hibernate: qsTr("Hibernate")})[kind] || "";
    }
    function cancel() { if (!busy) { pending = ""; feedback = ""; } }
    function request(kind) {
        if (busy || commandFor(kind).length === 0 || (kind === "force" && !canForce)) return;
        if (kind !== "lock" && kind !== "sleep" && pending !== kind) {
            pending = kind;
            feedback = kind === "force" ? qsTr("Unsaved work can be lost. Confirm?") : qsTr("Confirm %1?").arg(labelFor(kind));
            return;
        }
        pending = ""; activeKind = kind; busy = true;
        feedback = (kind === "logout" || kind === "switchDesktop" || kind === "force") ? qsTr("Closing applications…") : qsTr("Working…");
        executeRequested(commandFor(kind));
    }
    function complete(code, details) {
        if (!busy) return;
        var leaving = activeKind === "logout" || activeKind === "switchDesktop" || activeKind === "force";
        canForce = leaving && code === 2;
        if (code === 0) { feedback = ""; succeeded(); busy = false; return; }
        feedback = leaving && code === 2 ? qsTr("Save remaining windows, or explicitly force logout.")
            : leaving && code === 3 ? qsTr("Manual login screen required. Disable autologin first.")
            : code === 4 ? qsTr("A logout request is already running.")
            : qsTr("Could not finish. %1").arg((details || qsTr("Check the session command.")).trim().slice(0, 240));
        failed();
        busy = false;
    }
}
