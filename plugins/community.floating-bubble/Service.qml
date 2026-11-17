import QtQuick
import Quickshell

Item {
  id: root

  property var shell: null
  property var manifest: null

  Variants {
    id: bubbleVariants
    model: Quickshell.screens

    delegate: Component {
      FloatingBubbleWindow {
        required property var modelData

        screen: modelData
      }
    }
  }
}
