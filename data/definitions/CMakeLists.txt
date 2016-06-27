set(minuet_DEFINITIONS
    intervals-ascending-melodic-definitions.json
    intervals-descending-melodic-definitions.json
    chords-root-position-definitions.json
    scales-major-and-its-modes-definitions.json
    rhythm-definitions.json
)

install(FILES ${minuet_DEFINITIONS} DESTINATION ${KDE_INSTALL_DATADIR}/minuet/definitions)
