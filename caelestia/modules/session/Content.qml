// SPDX-License-Identifier: GPL-3.0-only
// Based on Caelestia shell; modified 2026-10-11 for preset-aware motion and lifecycle handling.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Controls as Controls
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
    property alias pendingAction: actionState.pending
    property alias actionStarted: actionState.busy
    property bool hibernateSupported: false
    property alias canForce: actionState.canForce
    property alias feedback: actionState.feedback
    property var commandOverride: null
    SessionActionState {
        id: actionState
        onExecuteRequested: command => {
            actionProcess.command = root.commandOverride ? root.commandOverride(command) : command;
            actionProcess.running = true;
        }
        onSucceeded: root.screenState.session = false
        onFailed: root.screenState.session = true
    }
    StyledText {
        visible: actionState.feedback.length > 0
        width: Tokens.sizes.session.button
        text: actionState.feedback
        wrapMode: Text.WordWrap
        maximumLineCount: 3; elide: Text.ElideRight
        Controls.ToolTip.visible: feedbackHover.containsMouse
        Controls.ToolTip.text: actionState.feedback
        MouseArea { id: feedbackHover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
        font: Tokens.font.body.small
        color: Colours.palette.m3onSurface
    }
    IconButton {
        visible: actionState.pending.length > 0
        icon: "close"
        implicitWidth: Tokens.sizes.session.button
        implicitHeight: 32
        onClicked: actionState.cancel()
        Accessible.name: qsTr("Cancel confirmation")
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
        actionKind: "lock"; actionLabel: qsTr("Lock"); command: ["loginctl", "lock-session"]; needsConfirmation: false
        KeyNavigation.down: sleep
    }
    SessionButton {
        id: sleep; actionKind: "sleep"; actionLabel: qsTr("Sleep"); command: ["systemctl", "suspend"]; needsConfirmation: false
        KeyNavigation.down: logout
    }
    SessionButton {
        id: logout

        actionKind: "logout"; actionLabel: qsTr("Log out")

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

        actionKind: "shutdown"; actionLabel: qsTr("Power off")

        command: Config.session.commands.shutdown

        KeyNavigation.up: logout
        KeyNavigation.down: root.hibernateSupported ? hibernate : reboot
    }

    AnimatedImage {
        visible: !root.previewMode
        width: Tokens.sizes.session.button
        height: Tokens.sizes.session.button
        sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)

        playing: visible && root.screenState.session && !Motion.reducedMotion
        asynchronous: true
        layer.enabled: true
        layer.effect: MultiEffect { colorization: 1; colorizationColor: Colours.palette.m3primary; brightness: 0.25 }
        speed: Math.max(1.8, Math.min(2.4, Config.general.sessionGifSpeed * 2))
        source: Qt.resolvedUrl("../../assets/tech-sphere.gif")
        opacity: status === AnimatedImage.Ready ? 1 : 0
        Behavior on opacity { Anim { type: Anim.DefaultEffects } }
        fillMode: AnimatedImage.PreserveAspectFit
    }

    SessionButton {
        id: hibernate
        visible: root.hibernateSupported
        opacity: visible ? 1 : 0
        Behavior on opacity { Anim { type: Anim.DefaultEffects } }

        actionKind: "hibernate"; actionLabel: qsTr("Hibernate")

        command: Config.session.commands.hibernate

        KeyNavigation.up: shutdown
        KeyNavigation.down: reboot
    }

    SessionButton {
        id: reboot

        actionKind: "restart"; actionLabel: qsTr("Restart")

        command: Config.session.commands.reboot

        KeyNavigation.up: root.hibernateSupported ? hibernate : shutdown
    }

    SessionButton {
        actionKind: "switchDesktop"; actionLabel: qsTr("Switch desktop"); command: ["multienv-logout", "--greeter"]
        KeyNavigation.up: reboot
    }

    SessionButton {
        visible: root.canForce; opacity: visible ? 1 : 0
        actionKind: "force"; actionLabel: qsTr("Force logout"); command: ["multienv-logout", "--force", "--timeout", "0"]
        Behavior on opacity { Anim { type: Anim.DefaultEffects } }
    }
    Process {
        id: actionProcess
        stderr: StdioCollector { id: actionErrors }
        onExited: (code, status) => actionState.complete(code, actionErrors.text)
        onRunningChanged: {
            if (!running && actionState.busy) Qt.callLater(() => {
                if (!actionProcess.running && actionState.busy) actionState.complete(127, actionErrors.text);
            });
        }
    }

    component SessionButton: IconButton {
        id: button

        required property list<string> command
        required property string actionLabel
        required property string actionKind
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
        icon: actionState.pending === actionKind ? "check" : actionKind === "lock" ? "lock" : actionKind === "sleep" ? "bedtime" : actionKind === "logout" ? Config.session.icons.logout : actionKind === "shutdown" ? Config.session.icons.shutdown : actionKind === "restart" ? Config.session.icons.reboot : actionKind === "hibernate" ? Config.session.icons.hibernate : actionKind === "force" ? "warning" : "desktop_windows"
        Controls.ToolTip.visible: hovered
        Controls.ToolTip.text: actionState.pending === actionKind ? qsTr("Confirm %1").arg(actionLabel) : actionLabel
        Controls.ToolTip.delay: 400
        function exec(): void { actionState.request(actionKind); }
        implicitWidth: Tokens.sizes.session.button
        implicitHeight: Tokens.sizes.session.button

        inactiveColour: activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
        inactiveOnColour: activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        radius: pressed ? Tokens.rounding.medium : activeFocus ? Tokens.rounding.extraLarge : Tokens.rounding.largeIncreased
        font: Tokens.font.icon.builders.large.scale(1.3).build()
        onClicked: exec()

        Keys.onEnterPressed: exec()
        Keys.onReturnPressed: exec()
        Keys.onEscapePressed: { if (!actionState.busy) { if (root.pendingAction) actionState.cancel(); else root.screenState.session = false; } }
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
