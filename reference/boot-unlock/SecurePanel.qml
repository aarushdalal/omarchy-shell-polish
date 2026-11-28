import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "ThemeColors.js" as ThemeColors

Item {
    id: root

    // Palette Tokens dynamically synchronized from the active wallpaper colors.toml
    readonly property bool isLightTheme: (ThemeColors.palette.mode || "dark") === "light"
    readonly property color canvasColor: ThemeColors.palette.background || "#08090d"
    readonly property color surfaceColor: ThemeColors.palette.lighterBg || "#14171c"
    readonly property color mainColor: ThemeColors.palette.foreground || "#f1f5f9"
    readonly property color rawSecondary: ThemeColors.palette.secondary || "#94a3b8"
    readonly property color rawMuted: ThemeColors.palette.muted || "#64748b"
    readonly property color secondaryColor: Math.abs((0.2126 * rawSecondary.r + 0.7152 * rawSecondary.g + 0.0722 * rawSecondary.b) - (0.2126 * surfaceColor.r + 0.7152 * surfaceColor.g + 0.0722 * surfaceColor.b)) >= 0.30 ? rawSecondary : Qt.tint(rawSecondary, Qt.rgba(mainColor.r, mainColor.g, mainColor.b, 0.55))
    readonly property color mutedColor: Math.abs((0.2126 * rawMuted.r + 0.7152 * rawMuted.g + 0.0722 * rawMuted.b) - (0.2126 * surfaceColor.r + 0.7152 * surfaceColor.g + 0.0722 * surfaceColor.b)) >= 0.22 ? rawMuted : Qt.rgba((secondaryColor.r + rawMuted.r) * 0.5, (secondaryColor.g + rawMuted.g) * 0.5, (secondaryColor.b + rawMuted.b) * 0.5, 1.0)

    readonly property color accent: ThemeColors.palette.accent || "#38bdf8"
    readonly property color accentHover: ThemeColors.palette.accentHover || "#60a5fa"
    readonly property color pressedAccent: ThemeColors.palette.blue || "#0284c7"
    readonly property color actionInk: ThemeColors.palette.background || "#060b13"

    readonly property color fieldBg: isLightTheme ? Qt.rgba(1, 1, 1, 0.56) : Qt.rgba(0, 0, 0, 0.35)
    readonly property color fieldBorder: Qt.rgba(accent.r, accent.g, accent.b, isLightTheme ? 0.34 : 0.22)
    readonly property color fieldBorderActive: Qt.rgba(accent.r, accent.g, accent.b, 0.78)

    readonly property color sessionActiveBg: Qt.rgba(accent.r, accent.g, accent.b, isLightTheme ? 0.24 : 0.22)
    readonly property color sessionInactiveBg: isLightTheme ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(0, 0, 0, 0.30)

    readonly property color buttonBg: isLightTheme ? Qt.rgba(1, 1, 1, 0.50) : Qt.rgba(0, 0, 0, 0.35)
    readonly property color buttonHoverBg: Qt.rgba(accent.r, accent.g, accent.b, 0.16)
    readonly property color buttonBorder: Qt.rgba(accent.r, accent.g, accent.b, isLightTheme ? 0.34 : 0.22)

    readonly property color errorColor: ThemeColors.palette.red || "#f87171"
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
    property string brandTagline: "WORKSTATION MONOLITH"
    property string brandLogo: ""
    property bool brandLogoColorize: false
    property string heading: "Welcome back"
    property string actionText: "Sign in"
    property string backgroundPath: "/var/cache/multienv/background_blurred.png"
    property string fallbackBackgroundPath: "/var/cache/multienv/background.png"
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

    // --- Fallback Theme Background ---
    Rectangle {
        anchors.fill: parent
        color: root.canvasColor
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: root.surfaceColor }
            GradientStop { position: 0.55; color: root.canvasColor }
            GradientStop { position: 1.0; color: Qt.darker(root.canvasColor, 1.35) }
        }
    }

    // --- Active Wallpaper Image with Rich Smooth Atmospheric Blur ---
    Image {
        id: bgImage
        anchors.fill: parent
        source: (root.backgroundPath.indexOf(":") > 0 ? "" : "file://") + root.backgroundPath
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: Math.min(1920, Math.max(1, root.width))
        asynchronous: false
        cache: false
        onStatusChanged: {
            if (status === Image.Error && source.toString().indexOf("_blurred") !== -1) {
                source = (root.fallbackBackgroundPath.indexOf(":") > 0 ? "" : "file://") + root.fallbackBackgroundPath;
            }
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: bgImage
        autoPaddingEnabled: false
        blurEnabled: bgImage.status === Image.Ready
        blur: bgImage.source.toString().indexOf("_blurred") !== -1 ? 0.22 : 0.65
        blurMax: 48
        blurMultiplier: 1.0
        opacity: bgImage.status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // Atmospheric Vignette & Scrim Overlay for optimal legibility (preserves artwork luminescence)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: root.isLightTheme ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.24) }
            GradientStop { position: 0.4; color: root.isLightTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.08) }
            GradientStop { position: 0.7; color: root.isLightTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.12) }
            GradientStop { position: 1.0; color: root.isLightTheme ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.30) }
        }
    }

    // Top Navigation / Header (Separate Floating Element Above Blurred Background)
    Row {
        x: Math.max(32, root.width * 0.05)
        y: 24
        spacing: 11

        // Optional Opt-In Brand Logo SVG
        Item {
            visible: root.brandLogo.length > 0
            width: 26
            height: 26
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: brandLogoImg
                objectName: "brandLogoImage"
                anchors.fill: parent
                visible: !root.brandLogoColorize
                source: root.brandLogo.length === 0 ? "" : ((root.brandLogo.indexOf(":") > 0 ? "" : (root.brandLogo.charAt(0) === "/" ? "file://" : "")) + root.brandLogo)
                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(26, 26)
                cache: false
                asynchronous: false
            }

            MultiEffect {
                anchors.fill: brandLogoImg
                source: brandLogoImg
                visible: root.brandLogoColorize
                colorization: 1.0
                colorizationColor: root.accent
            }
        }

        // Default Minimal Dot Indicator (when no custom BrandLogo is configured)
        Rectangle {
            visible: root.brandLogo.length === 0
            width: 7; height: 7; radius: 3.5
            color: root.accent
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.centerIn: parent
                width: 13; height: 13; radius: 6.5
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25)
            }
        }

        Text {
            objectName: "brandText"
            text: root.brand
            color: root.mainColor
            font.family: "Noto Sans"
            font.pixelSize: 12
            font.letterSpacing: 2.4
            font.weight: Font.Bold
            anchors.verticalCenter: parent.verticalCenter
            style: root.isLightTheme ? Text.Normal : Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.45)
        }

        Rectangle {
            width: 1; height: 11
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35)
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.brandTagline
            color: root.secondaryColor
            font.family: "Noto Sans"
            font.pixelSize: 10
            font.letterSpacing: 2
            anchors.verticalCenter: parent.verticalCenter
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
        color: root.isLightTheme ? Qt.rgba(1, 1, 1, 0.65) : Qt.rgba(root.canvasColor.r, root.canvasColor.g, root.canvasColor.b, 0.72)
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.24)

        Row {
            anchors.centerIn: parent
            spacing: 7
            Rectangle {
                width: 6; height: 6; radius: 3
                color: ThemeColors.palette.green || "#10b981"
                anchors.verticalCenter: parent.verticalCenter
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
            opacity: 0.50
            scale: 0.98
        }

        // Clean Translucent Frosted Glass Card (Dynamic Theme Palette)
        Rectangle {
            id: cardBackground
            anchors.fill: parent
            radius: 28
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { 
                    position: 0.0; 
                    color: Qt.rgba(Qt.color(ThemeColors.palette.lighterBg || "#141824").r, 
                                   Qt.color(ThemeColors.palette.lighterBg || "#141824").g, 
                                   Qt.color(ThemeColors.palette.lighterBg || "#141824").b, 
                                   0.80) 
                }
                GradientStop { 
                    position: 1.0; 
                    color: Qt.rgba(Qt.color(ThemeColors.palette.background || "#08090d").r, 
                                   Qt.color(ThemeColors.palette.background || "#08090d").g, 
                                   Qt.color(ThemeColors.palette.background || "#08090d").b, 
                                   0.88) 
                }
            }
            border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.24)
            border.width: 1
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
                    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
                    border.width: 1

                    // Breathing focus halo
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: 29
                        color: "transparent"
                        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.45)
                        border.width: 1.5
                        opacity: password.activeFocus ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    Image {
                        id: userIconImg
                        anchors.centerIn: parent
                        width: 24; height: 24
                        source: "icons/user.svg"
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(24, 24)
                    }
                    MultiEffect {
                        anchors.fill: userIconImg
                        source: userIconImg
                        colorization: 1.0
                        colorizationColor: root.mainColor
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

                    Item {
                        width: 16; height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: password.activeFocus ? 1.0 : 0.72
                        Behavior on opacity { NumberAnimation { duration: 140 } }

                        Image {
                            id: lockIconImg
                            anchors.fill: parent
                            source: "icons/lock.svg"
                            fillMode: Image.PreserveAspectFit
                            sourceSize: Qt.size(16, 16)
                        }
                        MultiEffect {
                            anchors.fill: lockIconImg
                            source: lockIconImg
                            colorization: 1.0
                            colorizationColor: password.activeFocus ? root.accent : root.secondaryColor
                        }
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
                            color: unlock.down ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.30) : (password.length > 0 || unlock.activeFocus || unlock.hovered ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20) : Qt.rgba(0, 0, 0, 0.25))
                            border.color: unlock.activeFocus ? root.accent : (password.length > 0 ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.45) : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18))
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }
                        }

                        contentItem: Item {
                            anchors.centerIn: parent
                            width: 16; height: 16
                            opacity: (password.length > 0 || unlock.hovered || unlock.activeFocus) ? 0.95 : 0.55
                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            Image {
                                id: arrowIconImg
                                anchors.fill: parent
                                source: "icons/arrow-right.svg"
                                fillMode: Image.PreserveAspectFit
                                sourceSize: Qt.size(16, 16)
                            }
                            MultiEffect {
                                anchors.fill: arrowIconImg
                                source: arrowIconImg
                                colorization: 1.0
                                colorizationColor: root.mainColor
                            }
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
                    Item {
                        width: 15; height: 15
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: root.fingerprintBusy ? 1.0 : breathingPulse.opacityVal

                        Image {
                            id: fpIconImg
                            anchors.fill: parent
                            source: "icons/fingerprint.svg"
                            fillMode: Image.PreserveAspectFit
                            sourceSize: Qt.size(15, 15)
                        }
                        MultiEffect {
                            anchors.fill: fpIconImg
                            source: fpIconImg
                            colorization: 1.0
                            colorizationColor: root.accent
                        }

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
                    Item {
                        width: 13; height: 13
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: powerBtn.hovered ? 1.0 : 0.80

                        Image {
                            id: powerIconImg
                            anchors.fill: parent
                            source: powerBtn.text === "Restart" ? "icons/restart.svg" : "icons/power.svg"
                            fillMode: Image.PreserveAspectFit
                            sourceSize: Qt.size(13, 13)
                        }
                        MultiEffect {
                            anchors.fill: powerIconImg
                            source: powerIconImg
                            colorization: 1.0
                            colorizationColor: powerBtn.hovered ? root.mainColor : root.secondaryColor
                        }
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
            color: root.surfaceColor
            radius: 14
            border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
            border.width: 1
        }

        onAccepted: root.powerRequested("confirmed:" + action)
    }

    function confirmPower(action) {
        powerDialog.action = action;
        powerDialog.open();
    }
}
