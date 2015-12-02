set(minuet_CLASSES
    ascending-melodic-intervals.json
    descending-melodic-intervals.json
    major-scale-and-its-modes.json
    chords-root-position.json
)

install(FILES ${minuet_CLASSES} DESTINATION ${KDE_INSTALL_DATADIR}/minuet/exercises)
