set(minuet_CLASSES
    intervals-ascending-melodic.json
    intervals-descending-melodic.json
    chords-root-position.json
    scales-major-and-its-modes.json
)

install(FILES ${minuet_CLASSES} DESTINATION ${KDE_INSTALL_DATADIR}/minuet/exercises)
