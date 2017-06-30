set(minuet_PIANO
    BlackKey.qml
    Octave.qml
    PianoView.qml
    WhiteKey.qml
)

install(FILES ${minuet_PIANO} DESTINATION ${KDE_INSTALL_DATADIR}/minuet/plugins/PianoView)
