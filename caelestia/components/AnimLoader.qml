// SPDX-License-Identifier: GPL-3.0-only
// Based on Caelestia shell; modified 2026-10-11 for preset-aware motion and lifecycle handling.
import QtQuick

Loader {
    id: root
    property Component sourceComp
    property bool isComplete: false
    property int outAnimType: Anim.FastEffects
    property int inAnimType: Anim.DefaultEffects
    asynchronous: true
    opacity: 0

    function reveal() {
        if (active && status === Loader.Ready && sourceComponent === sourceComp) {
            incoming.restart();
        }
    }
    function replaceContent() {
        sourceComponent = sourceComp;
        reveal();
    }
    Component.onCompleted: { isComplete = true; replaceContent(); }
    onSourceCompChanged: {
        if (!isComplete) return;
        incoming.stop();
        if (opacity > 0) outgoing.restart();
        else replaceContent();
    }
    onStatusChanged: { if (status === Loader.Ready) reveal(); else opacity = 0; }
    onActiveChanged: {
        if (!active) { outgoing.stop(); incoming.stop(); opacity = 0; }
        else reveal();
    }
    Anim {
        id: outgoing
        target: root; property: "opacity"; to: 0; type: root.outAnimType
        onFinished: root.replaceContent()
    }
    Anim {
        id: incoming
        target: root; property: "opacity"; to: 1; type: root.inAnimType
    }
}
