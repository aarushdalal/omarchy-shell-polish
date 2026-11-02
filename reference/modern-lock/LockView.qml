// SPDX-License-Identifier: MIT
// Visual-only refinement of the existing Modern Lock view; authentication remains in its host service.
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Effects
import qs.Commons
import qs.Commons as OmarchyPalette

Item {
    id: root
    readonly property string viewRevision: "minimal-stats-live-20261102"
    property string backgroundPath: ""
    property int backgroundVersion: 0
    property bool fingerprintConfigured: false
    property bool fingerprintBusy: false
    property bool authenticatingPassword: false
    property string failureMessage: ""
    property int failedAttempts: 0
    property bool inputEnabled: true
    property bool loadBackground: true
    property string passwordText: ""
    property string userName: ""
    property string timeFormat: "HH:mm"
    property string dateFormat: "dddd, MMMM d"
    property bool reducedMotion: false
    property bool loadSystemStats: true
    property string statsOverride: ""
    readonly property bool presentationVisible: !!(root.visible && root.Window.window && root.Window.window.visible)
    property date now: new Date()
    Loader {
        id: telemetry
        active: root.loadSystemStats && root.presentationVisible
        source: "LockTelemetry.qml"
    }
    property real fieldBackgroundOpacity: 0.72
    property real backgroundScrimOpacity: 0.22
    property real presentationProgress: 1
    function present() {
        presentation.stop()
        if (visible && !reducedMotion) { presentationProgress = 0; presentation.start() }
        else presentationProgress = 1
    }
    onVisibleChanged: root.present()
    onReducedMotionChanged: if (reducedMotion) { presentation.stop(); presentationProgress = 1 }
    NumberAnimation {
        id: presentation
        target: root; property: "presentationProgress"; from: 0; to: 1
        duration: 160; easing.type: Easing.OutCubic
    }
    signal submitPassword(string password)
    signal passwordTextEdited(string password)
    signal clearFailureRequested()
    signal wakeRequested()
    signal sleepRequested()
    signal shutdownRequested()
    signal rebootRequested()
    signal suspendRequested()

    function fileUrl(path) {
        return path ? "file://" + String(path).split("/").map(encodeURIComponent).join("/") + "?v=" + backgroundVersion : "";
    }
    function forcePasswordFocus() { password.forceActiveFocus(); }
    Component.onCompleted: { root.present(); if (inputEnabled) Qt.callLater(forcePasswordFocus) }
    onInputEnabledChanged: if (inputEnabled) Qt.callLater(forcePasswordFocus)
    onPasswordTextChanged: if (password.text !== passwordText) password.text = passwordText
    Timer { interval: 1000; repeat: true; running: root.presentationVisible; triggeredOnStart: true; onTriggered: root.now = new Date() }

    Rectangle { anchors.fill: parent; color: OmarchyPalette.Color.background }
    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: Math.min(1280, Math.max(1, root.width))
        asynchronous: true
        cache: false
    }
    MultiEffect {
        anchors.fill: parent; source: wallpaper
        autoPaddingEnabled: false
        blurEnabled: wallpaper.status === Image.Ready
        blur: 1; blurMax: 48; blurMultiplier: 1
    }
    Rectangle { anchors.fill: parent; color: Qt.alpha(OmarchyPalette.Color.background, Math.max(0, Math.min(1, root.backgroundScrimOpacity))) }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: root.inputEnabled
        onPositionChanged: root.wakeRequested()
        onClicked: { root.wakeRequested(); root.forcePasswordFocus(); }
    }
    Column {
        width: Math.min(360, root.width - 48)
        anchors.centerIn: parent
        spacing: root.height < 480 ? 14 : 22
        opacity: 0.90 + root.presentationProgress * 0.10
        transform: Translate { y: root.reducedMotion ? 0 : (1 - root.presentationProgress) * 5 }
        Column {
            width: parent.width
            spacing: root.height < 480 ? 6 : 10
            Text {
                width: parent.width
                text: Qt.formatDateTime(root.now, root.timeFormat)
                color: OmarchyPalette.Color.foreground
                font.family: "Noto Sans Light"; font.letterSpacing: -1.8; font.pixelSize: Math.min(86, root.height * .13)
                horizontalAlignment: Text.AlignHCenter
                style: Text.Outline; styleColor: Qt.alpha(OmarchyPalette.Color.background, .45)
            }
            Text {
                objectName: "lock-date"
                width: parent.width; text: Qt.formatDateTime(root.now, root.dateFormat)
                textFormat: Text.PlainText; horizontalAlignment: Text.AlignHCenter
                color: Qt.alpha(OmarchyPalette.Color.foreground, .64)
                font.family: "Noto Sans"; font.pixelSize: 12
            }
            Text {
                objectName: "lock-system-stats"
                width: parent.width
                text: root.statsOverride || (telemetry.item ? telemetry.item.summary : "CPU —   ·   RAM —   ·   Power —")
                textFormat: Text.PlainText; horizontalAlignment: Text.AlignHCenter
                color: Qt.alpha(OmarchyPalette.Color.foreground, .56)
                font.family: "Noto Sans"; font.pixelSize: 11
                wrapMode: Text.WordWrap
                Accessible.name: "System status: " + text
            }
        }
        TextField {
            id: password; objectName: "passwordField"
            width: parent.width; height: 54
            text: root.passwordText; echoMode: TextInput.Password; passwordCharacter: "●"
            color: OmarchyPalette.Color.lock.text
            placeholderText: ""
            placeholderTextColor: OmarchyPalette.Color.lock.placeholder
            font.family: "Noto Sans"; font.pixelSize: 16
            leftPadding: 18; rightPadding: 18
            horizontalAlignment: TextInput.AlignHCenter
            cursorVisible: activeFocus && length > 0
            readOnly: !root.inputEnabled || root.authenticatingPassword
            maximumLength: 1024; selectByMouse: true
            selectionColor: OmarchyPalette.Color.lock.selection
            Accessible.name: "Password. Enter with an empty field to use fingerprint."
            background: Rectangle {
                radius: 13
                color: Qt.alpha(OmarchyPalette.Color.background, Math.max(0, Math.min(1, root.fieldBackgroundOpacity)))
                border.width: 1
                border.color: root.failureMessage ? OmarchyPalette.Color.lock.borderError : password.activeFocus ? OmarchyPalette.Color.lock.borderActive : OmarchyPalette.Color.lock.border
                Behavior on border.color { enabled: root.visible && !root.reducedMotion; ColorAnimation { duration: 120 } }
                Rectangle {
                    anchors.fill: parent; anchors.margins: 1
                    radius: 12; color: "transparent"; border.width: 1
                    border.color: Qt.alpha(OmarchyPalette.Color.foreground, .045)
                }
            }
            Text {
                anchors.fill: parent
                visible: password.length === 0
                text: root.authenticatingPassword ? "Checking…" : "Password"
                color: OmarchyPalette.Color.lock.placeholder
                font: password.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onTextChanged: {
                if (text !== root.passwordText && root.inputEnabled) {
                    root.passwordTextEdited(text); root.clearFailureRequested(); root.wakeRequested();
                }
            }
            onAccepted: {
                if (root.inputEnabled && !root.authenticatingPassword) {
                    root.wakeRequested(); root.submitPassword(text);
                }
            }
            Keys.onEscapePressed: {
                if (root.inputEnabled && !root.authenticatingPassword) root.passwordTextEdited("");
            }
            Keys.onPressed: root.wakeRequested()
        }
        Text {
            width: parent.width
            visible: text.length > 0
            text: root.failureMessage || (root.fingerprintBusy ? "Touch the fingerprint reader" : "")
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            color: root.failureMessage ? OmarchyPalette.Color.lock.textError : OmarchyPalette.Color.foreground
            font.family: "Noto Sans"; font.pixelSize: 12
            style: Text.Outline; styleColor: Qt.alpha(OmarchyPalette.Color.background, .5)
        }
    }
}
