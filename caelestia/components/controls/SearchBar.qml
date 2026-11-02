import QtQuick
import Caelestia.Config
import qs.components
import qs.services

TextFieldBase {
    id: root

    readonly property alias bg: bg
    readonly property alias searchIcon: searchIcon
    readonly property alias clearIcon: clearIcon

    // Local reading surface; leave the wallpaper and global glass palette untouched.
    property color surfaceColor: Qt.alpha(Colours.palette.m3surfaceContainer, Colours.tPalette.m3surfaceContainer.a)
    property real minimumSurfaceOpacity: 0.94
    property real focusedMinimumSurfaceOpacity: 0.98
    readonly property real surfaceOpacity: {
        const value = root.activeFocus ? focusedMinimumSurfaceOpacity : minimumSurfaceOpacity;
        const fallback = root.activeFocus ? 0.98 : 0.94;
        return Math.max(surfaceColor.a, Math.max(0, Math.min(1, Number.isFinite(value) ? value : fallback)));
    }
    readonly property int focusDuration: Motion.reducedMotion ? 0 : Math.min(160, Motion.micro)

    Accessible.name: placeholderText || qsTr("Search")

    leftPadding: searchIcon.width + searchIcon.anchors.leftMargin + Tokens.spacing.medium
    rightPadding: clearIcon.width + clearIcon.anchors.rightMargin + Tokens.spacing.medium
    topPadding: Tokens.padding.large
    bottomPadding: Tokens.padding.large

    onPressed: {
        if (!Motion.reducedMotion && !stateLayer.disabled)
            stateLayer.press(stateLayer.mouseX, stateLayer.mouseY);
    }

    background: StyledRect {
        id: bg

        anchors.fill: parent
        color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, root.surfaceOpacity)
        radius: Tokens.rounding.full
        border.width: 1
        border.color: Qt.alpha(Colours.palette.m3onSurface, 0.13)

        // A static inset edge adds depth without an offscreen blur or shadow layer.
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, bg.radius - 1)
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3onSurface, 0.045)
        }

        Rectangle {
            objectName: "search-focus-outline"
            anchors.fill: parent
            radius: bg.radius
            color: "transparent"
            border.width: 1
            border.color: Colours.palette.m3primary
            opacity: root.activeFocus ? 0.85 : 0

            Behavior on opacity {
                enabled: root.visible && !Motion.reducedMotion
                NumberAnimation { duration: root.focusDuration; easing.type: Motion.easeStandard }
            }
        }

        StateLayer {
            id: stateLayer
            objectName: "search-background-feedback"

            cursorShape: Qt.IBeamCursor
            disabled: root.activeFocus
            manualPressOverride: tapHandler.pressed
            onClicked: root.focus = true
        }
    }

    StyledText {
        id: placeholder

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.leftPadding

        text: root.placeholderText
        color: root.placeholderTextColor
        font: root.font

        opacity: root.text ? 0 : 1

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    MaterialIcon {
        id: searchIcon

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.large

        text: "search"
        color: root.activeFocus ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.builders.medium.scale(0.9).build()
    }

    IconButton {
        id: clearIcon

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Tokens.padding.medium

        icon: "clear"
        type: IconButton.Text
        radius: Tokens.rounding.full
        radiusMorph: false
        enabled: root.text
        stateLayer.hoverEnabled: enabled
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Clear search")
        Accessible.onPressAction: if (enabled) root.clear()
        onClicked: root.clear()

        opacity: root.text ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    TapHandler {
        id: tapHandler
    }
}
