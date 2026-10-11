// SPDX-License-Identifier: GPL-3.0-only
// Based on Caelestia shell; modified 2026-10-11 for preset-aware motion and lifecycle handling.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Column {
    id: root

    required property ScreenState screenState
    property bool previewMode: false
    property string pendingAction: ""
    property bool actionStarted: false
    property bool hibernateSupported: false
    property bool canForce: false
    property string feedback: ""
    StyledText { text: qsTr("DaemonOS · Session"); font: Tokens.font.title.medium }
    StyledText {
        text: root.pendingAction ? (root.pendingAction === qsTr("Force logout") ? qsTr("Unsaved changes can be lost · Escape to cancel") : root.pendingAction === qsTr("Switch desktop") ? qsTr("Choose your desktop at login · Escape to cancel") : qsTr("Select again to confirm · Escape to cancel")) : (root.feedback || qsTr("Save your work before leaving"))
        font: Tokens.font.body.small
        color: Qt.alpha(Colours.palette.m3onSurface, 0.65)
    }

    padding: Tokens.padding.large
    rightPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)
    spacing: Tokens.spacing.large

    Process {
        running: true
        command: ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", "CanHibernate"]
        stdout: StdioCollector { onStreamFinished: { var answer = text.trim(); root.hibernateSupported = answer === 's "yes"' || answer === 's "challenge"'; } }
    }
    SessionButton {
        actionLabel: qsTr("Lock"); icon: "lock"; command: ["loginctl", "lock-session"]; needsConfirmation: false
        KeyNavigation.down: sleep
    }
    SessionButton {
        id: sleep; actionLabel: qsTr("Sleep"); icon: "bedtime"; command: ["systemctl", "suspend"]; needsConfirmation: false
        KeyNavigation.down: logout
    }
    SessionButton {
        id: logout

        actionLabel: qsTr("Log out")

        icon: Config.session.icons.logout
        command: Config.session.commands.logout

        KeyNavigation.up: sleep
        KeyNavigation.down: shutdown

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher)
                    logout.forceActiveFocus();
            }

            target: root.screenState
        }
    }

    SessionButton {
        id: shutdown

        actionLabel: qsTr("Power off")

        icon: Config.session.icons.shutdown
        command: Config.session.commands.shutdown

        KeyNavigation.up: logout
        KeyNavigation.down: root.hibernateSupported ? hibernate : reboot
    }

    AnimatedImage {
        visible: !root.previewMode
        width: Tokens.sizes.session.button
        height: Tokens.sizes.session.button
        sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)

        playing: visible && root.screenState.session
        asynchronous: true
        speed: Config.general.sessionGifSpeed
        source: Paths.absolutePath(Config.paths.sessionGif)
        fillMode: AnimatedImage.PreserveAspectFit
    }

    SessionButton {
        id: hibernate
        visible: root.hibernateSupported
        opacity: visible ? 1 : 0
        Behavior on opacity { Anim { type: Anim.DefaultEffects } }

        actionLabel: qsTr("Hibernate")

        icon: Config.session.icons.hibernate
        command: Config.session.commands.hibernate

        KeyNavigation.up: shutdown
        KeyNavigation.down: reboot
    }

    SessionButton {
        id: reboot

        actionLabel: qsTr("Restart")

        icon: Config.session.icons.reboot
        command: Config.session.commands.reboot

        KeyNavigation.up: root.hibernateSupported ? hibernate : shutdown
    }

    SessionButton {
        actionLabel: qsTr("Switch desktop"); icon: "desktop_windows"; command: ["multienv-logout", "--greeter"]
        KeyNavigation.up: reboot
    }

    SessionButton {
        visible: root.canForce; opacity: visible ? 1 : 0
        actionLabel: qsTr("Force logout"); icon: "warning"; command: ["multienv-logout", "--force", "--timeout", "0"]
        Behavior on opacity { Anim { type: Anim.DefaultEffects } }
    }
    Process {
        id: logoutProcess
        onExited: (code, status) => {
            root.actionStarted = false;
            root.canForce = code === 2;
            root.pendingAction = "";
            if (code === 0) root.screenState.session = false;
            else root.feedback = code === 2 ? qsTr("Save remaining windows, or explicitly force logout.") : code === 3 ? qsTr("Restore the manual greeter before switching.") : qsTr("The action could not finish. Please try again.");
        }
    }

    component SessionButton: ButtonBase {
        id: button

        required property list<string> command
        required property string actionLabel
        property string icon
        property bool needsConfirmation: true
        Accessible.role: Accessible.Button
        Accessible.name: actionLabel
        disabled: root.actionStarted
        scale: pressed ? Motion.pressScale : 1
        Behavior on scale { Anim { type: Anim.FastSpatial } }
        Rectangle {
            anchors.fill: parent; color: "transparent"; radius: button.radius
            border.width: button.activeFocus ? 2 : 0
            border.color: Colours.palette.m3primary
        }
        Row {
            anchors.centerIn: parent; width: parent.width - 40; spacing: Tokens.spacing.medium
            MaterialIcon { id: actionIcon; text: button.icon; color: button.onColour; fontStyle: Tokens.font.icon.large }
            StyledText {
                text: root.pendingAction === button.actionLabel ? qsTr("Confirm ") + button.actionLabel : button.actionLabel
                color: button.onColour; font: Tokens.font.body.large
                width: parent.width - actionIcon.width - parent.spacing
                elide: Text.ElideRight
            }
        }

        function exec(): void {
            if (root.actionStarted) return;
            if (needsConfirmation && root.pendingAction !== actionLabel) {
                if (actionLabel === qsTr("Force logout")) root.feedback = qsTr("Unsaved changes can be lost.");
                root.pendingAction = actionLabel;
                forceActiveFocus();
                return;
            }
            root.actionStarted = true;
            var executable = command[0].split("/").pop();
            if (executable === "multienv-logout" || executable === "daemon-os-logout") {
                root.feedback = qsTr("Waiting for applications to close…");
                root.pendingAction = "";
                logoutProcess.command = command; logoutProcess.running = true;
                return;
            }
            if (!SessionManager.exec(command)) Quickshell.execDetached(command);
            root.screenState.session = false;
        }

        implicitWidth: 300
        implicitHeight: 48

        inactiveColour: activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
        inactiveOnColour: activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        radius: pressed ? Tokens.rounding.medium : activeFocus ? Tokens.rounding.extraLarge : Tokens.rounding.largeIncreased
        font: Tokens.font.body.large
        onClicked: exec()

        Keys.onEnterPressed: exec()
        Keys.onReturnPressed: exec()
        Keys.onEscapePressed: { if (root.pendingAction) root.pendingAction = ""; else root.screenState.session = false; }
        Keys.onPressed: event => {
            if (!Config.session.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if ((event.key === Qt.Key_J || event.key === Qt.Key_N) && KeyNavigation.down) {
                    KeyNavigation.down.focus = true;
                    event.accepted = true;
                } else if ((event.key === Qt.Key_K || event.key === Qt.Key_P) && KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                KeyNavigation.down.focus = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                if (KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            }
        }
    }
}
