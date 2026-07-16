// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

Item {
    property int countIn: 0
    property bool countInOverlayInitial: false
    property real countInOverlaySize: 0
    property real countInOverlayX: 0
    property real countInOverlayY: 0
    property var currentExercise
    property string currentExerciseIconName: ""
    property bool onboardingCardsHidden: false
    property int onboardingCountIn: 0
    property bool onboardingPreviewActive: false

    signal countInSubTickRequested
}
