set(minuet_EXERCISES
    intervals-ascending-melodic-exercises.json
    intervals-descending-melodic-exercises.json
    chords-root-position-exercises.json
    scales-major-and-its-modes-exercises.json
    rhythm-easy.json
    rhythm-medium.json
)

install(FILES ${minuet_EXERCISES} DESTINATION ${KDE_INSTALL_DATADIR}/minuet/exercises)
