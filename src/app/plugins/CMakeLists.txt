set(minuet_PLUGINS
    PianoView.json
)

add_subdirectory(PianoView)

install(FILES ${minuet_PLUGINS} DESTINATION ${KDE_INSTALL_DATADIR}/minuet/plugins)
