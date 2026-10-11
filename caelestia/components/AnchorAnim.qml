// SPDX-License-Identifier: GPL-3.0-only
// Based on Caelestia shell; modified 2026-10-11 for preset-aware motion and lifecycle handling.
import QtQuick
import Caelestia.Config
import qs.services

AnchorAnimation {
    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial
    }

    property int type: AnchorAnim.DefaultSpatial

    duration: Motion.reducedMotion ? 40 : (type === 8 || type === 11 ? Motion.micro : type === 10 || type === 13 ? Motion.expressive : Motion.standard)
    easing.type: type >= 11 ? Motion.easeStandard : Motion.easeExpressive
    easing.overshoot: Motion.springOvershoot
}
