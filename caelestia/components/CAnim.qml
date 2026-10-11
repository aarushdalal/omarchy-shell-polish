// SPDX-License-Identifier: GPL-3.0-only
// Based on Caelestia shell; modified 2026-10-11 for preset-aware motion and lifecycle handling.
import QtQuick
import Caelestia.Config
import qs.services

ColorAnimation {
    duration: Motion.reducedMotion ? 40 : Motion.standard
    easing.type: Motion.easeStandard
}
