set(minuet_PLUGINS
    PianoView.json
    GuitarView.json
)

add_subdirectory(PianoView)
add_subdirectory(GuitarView)

install(FILES ${minuet_PLUGINS} DESTINATION ${KDE_INSTALL_DATADIR}/minuet/plugins)
