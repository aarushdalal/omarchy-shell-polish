import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui

PanelWindow {
  id: window

  readonly property var monitor: Hyprland.monitorFor(screen)
  readonly property int workspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : (monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1)

  WlrLayershell.namespace: "omarchy-floating-bubble"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  color: "transparent"

  anchors {
    right: true
    bottom: true
  }

  // Margin from screen edges adapting to system spacing
  readonly property int margin: Math.round(16 * Style.fontScale)
  // Adaptive bubble height & icon sizes based on system fontScale
  readonly property int bubbleSize: Math.round(48 * Style.fontScale)
  readonly property int iconSize: Math.round(26 * Style.fontScale)
  readonly property int slotSize: bubbleSize - Math.round(10 * Style.fontScale)

  // Revision tracker to force immediate reactive re-evaluation on any Hyprland event
  property int eventRevision: 0

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event) return
      Hyprland.refreshToplevels()
      window.eventRevision++
    }
  }

  Connections {
    target: Hyprland.toplevels
    function onValuesChanged() {
      window.eventRevision++
    }
  }

  onWorkspaceIdChanged: {
    Hyprland.refreshToplevels()
    window.eventRevision++
  }

  Component.onCompleted: {
    Hyprland.refreshToplevels()
    window.eventRevision++
  }

  // Watchdog timer to ensure the bubble re-evaluates even if IPC drops an event
  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      Hyprland.refreshToplevels()
      window.eventRevision++
    }
  }

  // Detect if any window on this workspace is maximized or fullscreen
  // User Rule: NEVER come above a window which is maximized!
  readonly property bool hasMaximizedWindow: {
    var _rev = window.eventRevision
    var toplevels = Hyprland.toplevels.values
    for (var i = 0; i < toplevels.length; i++) {
      var toplevel = toplevels[i]
      if (!toplevel.workspace || toplevel.workspace.id !== workspaceId) continue
      var ipc = toplevel.lastIpcObject
      var fs = (ipc && ipc.fullscreen !== undefined) ? Number(ipc.fullscreen) : 0
      if (fs >= 1) return true
    }
    return false
  }

  // Per-Workspace Minimized Windows: each workspace remembers its own minimized apps!
  readonly property var minimizedWindows: {
    var _rev = window.eventRevision
    var list = []
    var toplevels = Hyprland.toplevels.values
    for (var i = 0; i < toplevels.length; i++) {
      var top = toplevels[i]
      if (!top.workspace) continue
      var wsName = String(top.workspace.name || "")
      if (wsName === "special:minimized" || wsName.indexOf("minimized") !== -1) {
        var ipc = top.lastIpcObject
        var tags = (ipc && ipc.tags) ? ipc.tags : []
        var fromWs = -1
        for (var t = 0; t < tags.length; t++) {
          var tagStr = String(tags[t] || "").replace(/\*$/, "")
          var m = tagStr.match(/omarchy-minimized-from-([0-9]+)/)
          if (m) { fromWs = parseInt(m[1]); break }
        }

        // Each workspace has its own bubble: strictly match windows minimized from THIS workspace
        if (fromWs === workspaceId) {
          var way = top.wayland
          var appId = way ? (way.appId || "") : ""
          var title = way ? (way.title || "") : ""
          var icon = ""
          if (appId) {
            var entry = DesktopEntries.heuristicLookup(appId)
            if (entry && entry.icon) {
              icon = Quickshell.iconPath(entry.icon, true)
            } else {
              icon = Quickshell.iconPath(appId, true)
            }
          }
          if (!icon) icon = Quickshell.iconPath("application-x-executable", true)
          list.push({
            address: top.address,
            appId: appId,
            title: title,
            icon: icon,
            fromWorkspace: fromWs
          })
        }
      }
    }
    return list
  }

  readonly property int count: minimizedWindows.length

  // Only show when THIS workspace has minimized windows AND no window on this workspace is maximized
  visible: count > 0 && !hasMaximizedWindow

  property bool isHovered: false

  Timer {
    id: hoverDebounce
    interval: 180
    onTriggered: {
      if (!bubbleHoverHandler.hovered && !listHoverArea.containsMouse) {
        window.isHovered = false
      }
    }
  }

  // Width calculation for expanded state
  readonly property int horizontalPadding: Math.round(8 * Style.fontScale)
  readonly property int itemSpacing: Math.round(6 * Style.fontScale)
  readonly property int expandedWidth: Math.max(
    bubbleSize,
    count * slotSize + (count - 1) * itemSpacing + horizontalPadding * 2
  )

  implicitWidth: bubbleContainer.width + margin * 2
  implicitHeight: bubbleSize + margin * 2

  // Only pass pointer events through the visible bubble
  mask: Region {
    item: bubbleContainer.visible ? bubbleContainer : null
  }

  Rectangle {
    id: bubbleContainer

    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: margin
    anchors.bottomMargin: margin

    height: bubbleSize
    width: window.isHovered ? expandedWidth : bubbleSize
    radius: bubbleSize / 2

    // Material 3 / Pixel Glass Surface
    color: Qt.rgba(Commons.Color.background.r, Commons.Color.background.g, Commons.Color.background.b, 0.88)
    border.width: 1.5
    border.color: window.isHovered
      ? Commons.Color.accent
      : Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.40)

    // Smooth horizontal expansion animation
    Behavior on width {
      NumberAnimation {
        duration: 240
        easing.type: Easing.OutBack
        easing.overshoot: 1.15
      }
    }

    Behavior on border.color {
      ColorAnimation { duration: 150 }
    }

    HoverHandler {
      id: bubbleHoverHandler
      onHoveredChanged: {
        if (hovered) {
          hoverDebounce.stop()
          window.isHovered = true
        } else {
          hoverDebounce.restart()
        }
      }
    }

    // Collapsed Single Icon + Badge View
    Item {
      id: collapsedView
      anchors.fill: parent
      visible: !window.isHovered
      opacity: window.isHovered ? 0 : 1

      Behavior on opacity {
        NumberAnimation { duration: 150 }
      }

      Image {
        id: latestIcon
        anchors.centerIn: parent
        width: iconSize
        height: iconSize
        fillMode: Image.PreserveAspectFit
        source: count > 0 ? minimizedWindows[count - 1].icon : ""
        asynchronous: true
      }

      // Count badge when more than 1 window is minimized on this workspace
      Rectangle {
        id: countBadge
        visible: count > 1
        width: Math.round(18 * Style.fontScale)
        height: Math.round(18 * Style.fontScale)
        radius: width / 2
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Math.round(2 * Style.fontScale)
        anchors.rightMargin: Math.round(2 * Style.fontScale)
        color: Commons.Color.accent

        Text {
          anchors.centerIn: parent
          text: count.toString()
          font.pixelSize: Math.round(10 * Style.fontScale)
          font.bold: true
          color: Commons.Color.background
        }
      }
    }

    // Expanded Horizontal Row of Minimized App Icons
    MouseArea {
      id: listHoverArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.RightButton
      onEntered: {
        hoverDebounce.stop()
        window.isHovered = true
      }
      onExited: {
        hoverDebounce.restart()
      }
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          // Right click restores all windows on this workspace
          Util.execDetached("omarchy-hyprland-window-restore --all " + workspaceId)
        }
      }

      Row {
        id: iconsRow
        anchors.centerIn: parent
        spacing: itemSpacing
        visible: window.isHovered
        opacity: window.isHovered ? 1 : 0

        Behavior on opacity {
          NumberAnimation { duration: 180 }
        }

        Repeater {
          model: window.isHovered ? minimizedWindows : []

          delegate: Rectangle {
            id: appSlot
            required property var modelData
            required property int index

            width: slotSize
            height: slotSize
            radius: slotSize / 2
            color: slotMouseArea.containsMouse
              ? Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.20)
              : "transparent"

            Behavior on color {
              ColorAnimation { duration: 120 }
            }

            scale: slotMouseArea.containsMouse ? 1.15 : 1.0
            Behavior on scale {
              NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
              }
            }

            Image {
              anchors.centerIn: parent
              width: iconSize
              height: iconSize
              fillMode: Image.PreserveAspectFit
              source: modelData.icon
              asynchronous: true
            }

            MouseArea {
              id: slotMouseArea
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

              onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                  // Restore window to current workspace
                  Util.execDetached("omarchy-hyprland-window-restore " + modelData.address + " " + workspaceId)
                } else if (mouse.button === Qt.MiddleButton) {
                  // Restore & Maximize
                  Util.execDetached("omarchy-hyprland-window-restore " + modelData.address + " " + workspaceId)
                  Util.execDetached("hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"set\", window = \"address:" + modelData.address + "\" })'")
                } else if (mouse.button === Qt.RightButton) {
                  // Restore all on this workspace
                  Util.execDetached("omarchy-hyprland-window-restore --all " + workspaceId)
                }
              }

              onDoubleClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                  // Double click restores and maximizes
                  Util.execDetached("omarchy-hyprland-window-restore " + modelData.address + " " + workspaceId)
                  Util.execDetached("hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"set\", window = \"address:" + modelData.address + "\" })'")
                }
              }
            }
          }
        }
      }
    }
  }
}
