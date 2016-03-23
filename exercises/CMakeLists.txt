set(minuet_EXERCISES
    intervals-ascending-melodic.json
    intervals-descending-melodic.json
    chords-root-position.json
    scales-major-and-its-modes.json
    rhythm-easy.json
    rhythm-medium.json
)

install(FILES ${minuet_EXERCISES} DESTINATION ${KDE_INSTALL_DATADIR}/minuet/exercises)
install(DIRECTORY exercise-images DESTINATION ${KDE_INSTALL_DATADIR}/minuet/qml)
