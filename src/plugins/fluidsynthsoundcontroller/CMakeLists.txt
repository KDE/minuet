set(fluidsynthsoundcontroller_PLUGIN_SRCS
    fluidsynthsoundcontroller.cpp
)

add_library(minuetfluidsynthsoundcontroller MODULE ${fluidsynthsoundcontroller_PLUGIN_SRCS})

target_link_libraries(minuetfluidsynthsoundcontroller
    Qt::Core
    Minuet::Interfaces
    Minuet::Utils
    PkgConfig::FLUIDSYNTH
)

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    install(TARGETS minuetfluidsynthsoundcontroller DESTINATION ${KDE_INSTALL_PLUGINDIR}/minuet/)
    install(FILES GeneralUser-v1.47.sf2 DESTINATION ${KDE_INSTALL_DATADIR}/minuet/soundfonts)
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
