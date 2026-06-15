# SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
#
# SPDX-License-Identifier: GPL-2.0-or-later

set(MINUET_DEFINITIONS
    intervals-ascending-melodic-harmonic-definitions.json
    intervals-descending-melodic-definitions.json
    intervals-melodic-definitions.json
    chords-three-notes-definitions.json
    chords-sevenths-definitions.json
    chords-extended-definitions.json
    scales-major-and-its-modes-definitions.json
    scales-harmonic-minor-and-its-modes-definitions.json
    scales-harmonic-major-and-its-modes-definitions.json
    scales-pentatonic-major-and-its-modes-definitions.json
    scales-simmetric-definitions.json
    scales-bebop-definitions.json
    rhythm-definitions.json
)

install(FILES ${MINUET_DEFINITIONS}
        DESTINATION ${KDE_INSTALL_DATADIR}/minuet/definitions
)
