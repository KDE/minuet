set(fluidsynthsoundbackend_PLUGIN_SRCS
    fluidsynthsoundbackend.cpp
    fluidsynthconfigpage.cpp
)

ki18n_wrap_ui(fluidsynthsoundbackend_PLUGIN_SRCS
    fluidsynthsettings.ui
)

add_library(minuetfluidsynthsoundbackend MODULE ${fluidsynthsoundbackend_PLUGIN_SRCS})

target_link_libraries(minuetfluidsynthsoundbackend
    Qt5::Core
    KF5::TextEditor
    Minuet::Interfaces
    fluidsynth
)

install(TARGETS minuetfluidsynthsoundbackend DESTINATION ${PLUGIN_INSTALL_DIR}/minuet/)
install(FILES GeneralUser-v1.47.sf2 DESTINATION ${KDE_INSTALL_DATADIR}/minuet/soundfonts)
