set(minuet_GUITAR
    GuitarView.qml
    FretBoard.qml
    NoteMark.qml
    String.qml
)

install(FILES ${minuet_GUITAR} DESTINATION ${KDE_INSTALL_DATADIR}/minuet/plugins/GuitarView)
