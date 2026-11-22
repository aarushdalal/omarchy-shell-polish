import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root

    // Palette Tokens matching Modern Lock Screen & Dark Glass Theme
    readonly property color canvasColor: "#08090d"
    readonly property color mainColor: "#f1f5f9"
    readonly property color secondaryColor: "#94a3b8"
    readonly property color mutedColor: "#64748b"

    readonly property color accent: "#38bdf8"
    readonly property color accentHover: "#60a5fa"
    readonly property color pressedAccent: "#0284c7"
    readonly property color actionInk: "#060b13"

    readonly property color fieldBg: Qt.rgba(0, 0, 0, 0.28)
    readonly property color fieldBorder: Qt.rgba(1, 1, 1, 0.10)
    readonly property color fieldBorderActive: Qt.rgba(56/255, 189/255, 248/255, 0.65)

    readonly property color sessionActiveBg: Qt.rgba(56/255, 189/255, 248/255, 0.18)
    readonly property color sessionInactiveBg: Qt.rgba(0, 0, 0, 0.25)

    readonly property color buttonBg: Qt.rgba(0, 0, 0, 0.30)
    readonly property color buttonHoverBg: Qt.rgba(1, 1, 1, 0.10)
    readonly property color buttonBorder: Qt.rgba(1, 1, 1, 0.10)

    readonly property color errorColor: "#f87171"
    readonly property color errorBg: Qt.rgba(0.25, 0.06, 0.08, 0.88)
    readonly property color errorBorder: Qt.rgba(0.97, 0.44, 0.44, 0.45)

    property string userName: ""
    property bool editUser: false
    property string passwordText: ""
    property bool busy: false
    property bool fingerprintBusy: false
    property bool fingerprintAvailable: true
    property bool failed: false
    property string message: ""
    property string brand: "MULTIENV"
    property string heading: "Welcome back"
    property string actionText: "Sign in"
    property string backgroundPath: "/var/cache/multienv/background.png"
    property var sessionNames: []
    property int sessionIndex: -1
    property bool reducedMotion: false
    property bool centeredLayout: true
    property bool mediaWidgetVisible: false
    property bool allowSleep: false
    property bool allowRestart: true
    property bool allowShutdown: true
    property string timeFormat: "HH:mm"
    property string dateFormat: "dddd, MMMM d"
    property date now: new Date()
    property bool appeared: false
    readonly property bool compact: width < 960
    readonly property bool hasSessions: sessionNames.length > 0

    signal passwordEdited(string value)
    signal userEdited(string value)
    signal submitted(string value)
    signal fingerprintRequested()
    signal sessionSelected(int index)
    signal powerRequested(string action)
    signal activity()

    function focusPassword() { password.forceActiveFocus(); }

    function cycleSession(delta) {
        if (busy || !hasSessions) return;
        sessionSelected((sessionIndex + delta + sessionNames.length) % sessionNames.length);
        focusPassword();
    }

    function submit() {
        if (busy) return;
        if (password.text.length > 0) submitted(password.text);
        else if (fingerprintAvailable) fingerprintRequested();
    }

    Component.onCompleted: { appeared = true; Qt.callLater(focusPassword); }
    onPasswordTextChanged: { if (password.text !== passwordText) password.text = passwordText; }
    Timer { interval: 1000; repeat: true; running: root.visible; onTriggered: root.now = new Date() }

    // On login failure: trigger visceral subtle shake animation
    onFailedChanged: {
        if (root.failed && !root.reducedMotion) {
            shakeAnimation.restart();
        }
    }

    // --- Fallback Pure Dark Background ---
    Rectangle {
        anchors.fill: parent
        color: root.canvasColor
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#0d1018" }
            GradientStop { position: 0.5; color: "#08090d" }
            GradientStop { position: 1.0; color: "#040507" }
        }
    }

    // --- Active Wallpaper Image with Soft Blur ---
    Image {
        id: bgImage
        anchors.fill: parent
        source: root.backgroundPath
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: Math.min(1920, Math.max(1, root.width))
        asynchronous: false
        cache: false
    }

    MultiEffect {
        anchors.fill: parent
        source: bgImage
        autoPaddingEnabled: false
        blurEnabled: bgImage.status === Image.Ready
        blur: 1.0
        blurMax: 64
        blurMultiplier: 2.5
        opacity: bgImage.status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // Atmospheric Vignette & Scrim Overlay for optimal legibility
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
            GradientStop { position: 0.3; color: Qt.rgba(0, 0, 0, 0.20) }
            GradientStop { position: 0.7; color: Qt.rgba(0, 0, 0, 0.25) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.55) }
        }
    }

    // Top Navigation / Header (Minimal Brand)
    Row {
        x: Math.max(32, root.width * 0.05)
        y: 28
        spacing: 10

        Rectangle {
            width: 7; height: 7; radius: 3.5
            color: root.accent
            anchors.verticalCenter: parent.verticalCenter

            // Subtle glow
            Rectangle {
                anchors.centerIn: parent
                width: 13; height: 13; radius: 6.5
                color: Qt.rgba(56/255, 189/255, 248/255, 0.25)
            }
        }

        Text {
            text: root.brand
            color: root.mainColor
            font.family: "Noto Sans"
            font.pixelSize: 11
            font.letterSpacing: 2.5
            font.weight: Font.Bold
        }

        Rectangle {
            width: 1; height: 10
            color: Qt.rgba(1, 1, 1, 0.2)
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: "WORKSTATION MONOLITH"
            color: root.mutedColor
            font.family: "Noto Sans"
            font.pixelSize: 10
            font.letterSpacing: 2
        }
    }

    // Top Right Host Status Pill
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: Math.max(32, root.width * 0.05)
        anchors.top: parent.top
        anchors.topMargin: 24
        height: 26
        width: hostLabel.implicitWidth + 24
        radius: 13
        color: Qt.rgba(0.05, 0.07, 0.11, 0.75)
        border.color: Qt.rgba(1, 1, 1, 0.12)

        Row {
            anchors.centerIn: parent
            spacing: 7
            Rectangle {
                width: 6; height: 6; radius: 3
                color: "#10b981"
            }
            Text {
                id: hostLabel
                text: "ARCH LINUX • HYPRLAND"
                color: root.secondaryColor
                font.family: "Noto Sans"
                font.pixelSize: 10
                font.letterSpacing: 1.2
                font.weight: Font.Medium
            }
        }
    }

    // Monolith Mask Item for the Secondary Focused Blur Layer
    Item {
        id: cardMaskItem
        width: card.width; height: card.height
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: 28
            color: "#ffffff"
        }
    }

    // Shake Animation on Authentication Error
    SequentialAnimation {
        id: shakeAnimation
        NumberAnimation { target: cardTranslate; property: "x"; to: -10; duration: 45; easing.type: Easing.InOutQuad }
        NumberAnimation { target: cardTranslate; property: "x"; to: 10; duration: 45; easing.type: Easing.InOutQuad }
        NumberAnimation { target: cardTranslate; property: "x"; to: -7; duration: 45; easing.type: Easing.InOutQuad }
        NumberAnimation { target: cardTranslate; property: "x"; to: 7; duration: 45; easing.type: Easing.InOutQuad }
        NumberAnimation { target: cardTranslate; property: "x"; to: -3; duration: 45; easing.type: Easing.InOutQuad }
        NumberAnimation { target: cardTranslate; property: "x"; to: 0; duration: 45; easing.type: Easing.InOutQuad }
    }

    // --- Minimal Centered Deck (Refined Glass Monolith) ---
    Item {
        id: card
        objectName: "floatingCard"
        width: Math.min(390, root.width - 40)
        height: contentCol.implicitHeight + 52
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.height > 900 ? -20 : -10

        opacity: root.appeared ? 1 : 0
        scale: root.appeared ? 1 : 0.96
        transform: Translate {
            id: cardTranslate
            x: 0
            y: root.reducedMotion ? 0 : (1 - (root.appeared ? 1 : 0)) * 8
        }
        Behavior on opacity { NumberAnimation { duration: root.reducedMotion ? 1 : 240; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 1 : 280; easing.type: Easing.OutBack } }

        // Multi-Layer Ambient Depth Drop Shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 32
            color: "#000000"
            opacity: 0.45
            scale: 0.98
        }

        // Frosted Glass Core with Layer 2 Deep Refraction Blur
        Item {
            id: frostedGlassCore
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: cardMaskItem
            }

            Image {
                id: innerBg
                x: -card.x
                y: -card.y
                width: root.width
                height: root.height
                source: bgImage.source
                fillMode: Image.PreserveAspectCrop
                asynchronous: false
                visible: bgImage.status === Image.Ready
            }

            MultiEffect {
                anchors.fill: innerBg
                source: innerBg
                blurEnabled: bgImage.status === Image.Ready
                blur: 1.0
                blurMax: 64
                blurMultiplier: 2.4
                brightness: 0.12
                contrast: 0.18
                saturation: 0.20
            }

            // Glass Surface Gradient Tint
            Rectangle {
                anchors.fill: parent
                radius: 28
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.08) }
                    GradientStop { position: 0.3; color: Qt.rgba(0, 0, 0, 0.18) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.45) }
                }
            }

            // Beveled Specular Border
            Rectangle {
                anchors.fill: parent
                radius: 28
                color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.14)
                border.width: 1.5

                // Top rim high-luminance specular line
                Rectangle {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 48
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.22)
                }
            }
        }

        Column {
            id: contentCol
            width: parent.width - 48
            anchors.centerIn: parent
            spacing: 16

            // Digital Clock & Date Section
            Column {
                width: parent.width
                spacing: 4

                Text {
                    width: parent.width
                    text: Qt.formatDateTime(root.now, root.timeFormat)
                    color: root.mainColor
                    font.family: "Noto Sans Light"
                    font.letterSpacing: -2.5
                    font.pixelSize: Math.min(72, root.height * 0.11)
                    horizontalAlignment: Text.AlignHCenter
                    style: Text.Outline
                    styleColor: Qt.rgba(0, 0, 0, 0.6)
                }

                Text {
                    width: parent.width
                    text: Qt.formatDateTime(root.now, root.dateFormat)
                    color: root.secondaryColor
                    font.family: "Noto Sans"
                    font.pixelSize: 12
                    font.letterSpacing: 0.8
                    horizontalAlignment: Text.AlignHCenter
                    style: Text.Outline
                    styleColor: Qt.rgba(0, 0, 0, 0.4)
                }
            }

            // User Identity & Avatar Disc Section
            Column {
                width: parent.width
                spacing: 8

                // Circular Frosted Glass Avatar Disk with Pure SVG Vector Icon
                Rectangle {
                    width: 52; height: 52; radius: 26
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Qt.rgba(0, 0, 0, 0.35)
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    border.width: 1

                    // Breathing focus halo
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: 29
                        color: "transparent"
                        border.color: Qt.rgba(56/255, 189/255, 248/255, 0.45)
                        border.width: 1.5
                        opacity: password.activeFocus ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 24; height: 24
                        source: "icons/user.svg"
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(24, 24)
                    }
                }

                // Username Label
                Text {
                    width: parent.width
                    text: root.userName.length > 0 ? root.userName : "User"
                    color: root.mainColor
                    font.family: "Noto Sans"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }

                // Optional Username Input (only when editUser enabled)
                TextField {
                    id: username
                    objectName: "usernameField"
                    visible: root.editUser
                    width: Math.min(220, parent.width)
                    height: 32
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.userName || ""
                    color: root.mainColor
                    placeholderText: "Username"
                    placeholderTextColor: root.mutedColor
                    font.family: "Noto Sans"
                    font.pixelSize: 12
                    horizontalAlignment: TextInput.AlignHCenter
                    readOnly: root.busy
                    Accessible.name: "Username"
                    background: Rectangle {
                        radius: 8
                        color: root.fieldBg
                        border.width: username.activeFocus ? 1.5 : 1
                        border.color: username.activeFocus ? root.accent : root.fieldBorder
                    }
                    onTextEdited: root.userEdited(text)
                    onAccepted: root.focusPassword()
                }
            }

            // Segmented MultiEnv Environment Switcher with Sliding Capsule
            Rectangle {
                id: sessionTrack
                visible: root.hasSessions
                width: parent.width
                height: 38
                radius: 19
                color: root.sessionInactiveBg
                border.color: root.fieldBorder
                border.width: 1

                readonly property real tabWidth: (width - 6 - (root.sessionNames.length - 1) * 4) / Math.max(1, root.sessionNames.length)

                // Smooth Sliding Active Pill Indicator
                Rectangle {
                    id: sessionSlider
                    visible: root.hasSessions && root.sessionIndex >= 0
                    width: sessionTrack.tabWidth
                    height: sessionTrack.height - 6
                    y: 3
                    x: 3 + (root.sessionIndex * (sessionTrack.tabWidth + 4))
                    radius: 16
                    color: root.sessionActiveBg
                    border.color: root.accent
                    border.width: 1

                    Behavior on x {
                        NumberAnimation {
                            duration: root.reducedMotion ? 1 : 220
                            easing.type: Easing.OutQuint
                        }
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    Repeater {
                        model: root.sessionNames
                        Button {
                            id: envBtn
                            required property int index
                            required property string modelData
                            text: modelData
                            width: sessionTrack.tabWidth
                            height: parent.height
                            enabled: !root.busy
                            activeFocusOnTab: false
                            Accessible.name: "Environment: " + text
                            Accessible.checkable: true
                            Accessible.checked: root.sessionIndex === index

                            onClicked: {
                                root.sessionSelected(index);
                                root.focusPassword();
                            }

                            background: Item {}

                            contentItem: Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Rectangle {
                                    width: 5; height: 5; radius: 2.5
                                    color: root.accent
                                    visible: root.sessionIndex === envBtn.index
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: envBtn.text
                                    color: root.sessionIndex === envBtn.index ? root.mainColor : root.secondaryColor
                                    font.family: "Noto Sans"
                                    font.pixelSize: 11
                                    font.weight: root.sessionIndex === envBtn.index ? Font.DemiBold : Font.Normal
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            // Unified Password Field & Integrated Pure SVG Action
            Rectangle {
                id: passwordBox
                width: parent.width
                height: 48
                radius: 14
                color: root.fieldBg
                border.width: password.activeFocus ? 1.5 : 1
                border.color: root.failed ? root.errorColor : password.activeFocus ? root.fieldBorderActive : root.fieldBorder
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 6
                    spacing: 8

                    Image {
                        width: 16; height: 16
                        source: "icons/lock.svg"
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(16, 16)
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: password.activeFocus ? 1.0 : 0.6
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }

                    TextField {
                        id: password
                        objectName: "passwordField"
                        width: parent.width - 66
                        height: parent.height
                        text: root.passwordText
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        readOnly: root.busy
                        selectByMouse: true
                        maximumLength: 1024
                        color: root.mainColor
                        font.family: "Noto Sans"
                        font.pixelSize: 15
                        verticalAlignment: TextInput.AlignVCenter
                        placeholderText: root.busy ? "Authenticating…" : "Enter password"
                        placeholderTextColor: root.mutedColor
                        Accessible.name: "Password. Enter with an empty field to use fingerprint."
                        background: Item {}

                        onTextChanged: {
                            if (text !== root.passwordText) {
                                root.passwordEdited(text);
                                root.activity();
                            }
                        }
                        onAccepted: root.submit()

                        Keys.onPressed: function(event) {
                            root.activity();
                            if (root.hasSessions && event.key === Qt.Key_Tab && (event.modifiers & Qt.ControlModifier)) {
                                unlock.forceActiveFocus();
                                event.accepted = true;
                            } else if (root.hasSessions && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
                                root.cycleSession(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape && !root.busy) {
                                root.passwordEdited("");
                                event.accepted = true;
                            }
                        }
                    }

                    // Integrated Forward Action Button with Pure SVG Chevron
                    Button {
                        id: unlock
                        objectName: "unlockButton"
                        width: 36
                        height: 36
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: !root.busy
                        text: root.actionText

                        onClicked: root.submit()

                        background: Rectangle {
                            radius: 10
                            color: unlock.down ? Qt.rgba(56/255, 189/255, 248/255, 0.25) : (password.length > 0 || unlock.activeFocus || unlock.hovered ? Qt.rgba(56/255, 189/255, 248/255, 0.20) : Qt.rgba(0, 0, 0, 0.25))
                            border.color: unlock.activeFocus ? root.accent : (password.length > 0 ? Qt.rgba(56/255, 189/255, 248/255, 0.40) : Qt.rgba(1, 1, 1, 0.08))
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }
                        }

                        contentItem: Image {
                            anchors.centerIn: parent
                            width: 16; height: 16
                            source: "icons/arrow-right.svg"
                            fillMode: Image.PreserveAspectFit
                            sourceSize: Qt.size(16, 16)
                            opacity: (password.length > 0 || unlock.hovered || unlock.activeFocus) ? 0.95 : 0.45
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }
                    }
                }
            }

            // Biometric Fingerprint Status & Touch Area with Pure SVG Icon
            Button {
                id: fingerprint
                width: parent.width
                height: 26
                visible: root.fingerprintAvailable
                text: root.fingerprintBusy ? "Touch reader now…" : "Touch sensor or press Enter to scan"
                enabled: !root.busy
                onClicked: root.fingerprintRequested()

                background: Rectangle {
                    radius: 7
                    color: fingerprint.activeFocus || fingerprint.hovered ? root.buttonHoverBg : "transparent"
                    border.color: fingerprint.activeFocus ? root.accent : "transparent"
                }

                contentItem: Row {
                    anchors.centerIn: parent
                    spacing: 7

                    // Breathing Pure SVG Fingerprint Glyph
                    Image {
                        width: 15; height: 15
                        source: "icons/fingerprint.svg"
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(15, 15)
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: root.fingerprintBusy ? 1.0 : breathingPulse.opacityVal

                        QtObject {
                            id: breathingPulse
                            property real opacityVal: 0.4
                        }

                        SequentialAnimation {
                            running: root.fingerprintAvailable && !root.reducedMotion
                            loops: Animation.Infinite
                            NumberAnimation { target: breathingPulse; property: "opacityVal"; to: 0.95; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { target: breathingPulse; property: "opacityVal"; to: 0.35; duration: 1200; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        text: fingerprint.text
                        color: fingerprint.hovered ? root.mainColor : root.mutedColor
                        font.family: "Noto Sans"
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Status / Error Toast Message
            Rectangle {
                width: parent.width
                height: statusMsg.implicitHeight + 12
                radius: 10
                visible: (root.message.length > 0) || root.failed
                color: root.failed ? root.errorBg : Qt.rgba(0.06, 0.08, 0.12, 0.85)
                border.color: root.failed ? root.errorBorder : root.buttonBorder

                Text {
                    id: statusMsg
                    anchors.centerIn: parent
                    width: parent.width - 20
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: root.message || (root.failed ? "Authentication failed. Try again." : "")
                    color: root.failed ? root.errorColor : root.secondaryColor
                    font.family: "Noto Sans"
                    font.pixelSize: 11
                }
            }
        }
    }

    // --- Bottom Power Controls (Floating Glass Dock with Pure SVG Icons) ---
    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 26
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        Repeater {
            model: ["Restart", "Shut down"]
            Button {
                id: powerBtn
                required property string modelData
                text: modelData
                height: 32
                width: 108
                enabled: !root.busy
                onClicked: root.powerRequested(text)

                background: Rectangle {
                    radius: 10
                    color: powerBtn.activeFocus || powerBtn.hovered ? root.buttonHoverBg : root.buttonBg
                    border.color: powerBtn.activeFocus ? root.accent : root.buttonBorder
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                contentItem: Row {
                    anchors.centerIn: parent
                    spacing: 7
                    Image {
                        width: 13; height: 13
                        source: powerBtn.text === "Restart" ? "icons/restart.svg" : "icons/power.svg"
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(13, 13)
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: powerBtn.hovered ? 1.0 : 0.7
                    }
                    Text {
                        text: powerBtn.text
                        color: powerBtn.hovered ? root.mainColor : root.secondaryColor
                        font.family: "Noto Sans"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    // Bottom Left Keyboard Ribbon
    Text {
        visible: !root.compact
        x: Math.max(32, root.width * 0.05)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        text: root.hasSessions ? "TAB: Switch Desktop   CTRL+TAB: Controls   ENTER: Sign In   ESC: Clear" : "ENTER: Sign In   ESC: Clear"
        color: root.mutedColor
        font.family: "Noto Sans"
        font.pixelSize: 10
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.5)
    }

    // Modal Confirmation Dialog for Power Actions
    Dialog {
        id: powerDialog
        anchors.centerIn: parent
        modal: true
        property string action: ""
        title: action + " workstation?"
        standardButtons: Dialog.Ok | Dialog.Cancel

        palette.windowText: root.mainColor
        palette.text: root.mainColor
        palette.buttonText: root.mainColor
        palette.button: root.buttonBg

        background: Rectangle {
            color: "#121622"
            radius: 14
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1
        }

        onAccepted: root.powerRequested("confirmed:" + action)
    }

    function confirmPower(action) {
        powerDialog.action = action;
        powerDialog.open();
    }
}
