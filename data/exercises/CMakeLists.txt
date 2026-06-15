# SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
#
# SPDX-License-Identifier: GPL-2.0-or-later

set(MINUET_EXERCISES
    intervals-ascending-melodic-exercises.json
    intervals-descending-melodic-exercises.json
    intervals-melodic-exercises.json
    intervals-harmonic-exercises.json
    chords-three-notes-exercises.json
    chords-sevenths-exercises.json
    chords-extended-exercises.json
    chords-combined-exercises.json
    scales-major-and-its-modes-exercises.json
    scales-harmonic-minor-and-its-modes-exercises.json
    scales-harmonic-major-and-its-modes-exercises.json
    scales-pentatonic-major-and-its-modes-exercises.json
    scales-simmetric-exercises.json
    scales-bebop-exercises.json
    rhythm-easy.json
    rhythm-medium.json
)

install(FILES ${MINUET_EXERCISES}
        DESTINATION ${KDE_INSTALL_DATADIR}/minuet/exercises
)
