set(fluidsynthsoundcontroller_PLUGIN_SRCS
    fluidsynthsoundcontroller.cpp
)

if(ANDROID)
    add_library(minuetfluidsynthsoundcontroller STATIC ${fluidsynthsoundcontroller_PLUGIN_SRCS})
    add_library(Minuet::FluidSynthSoundController ALIAS minuetfluidsynthsoundcontroller)
else()
    add_library(minuetfluidsynthsoundcontroller MODULE ${fluidsynthsoundcontroller_PLUGIN_SRCS})
endif()

target_link_libraries(minuetfluidsynthsoundcontroller
    Qt::Core
    Minuet::Interfaces
    Minuet::Utils
    ${MINUET_FLUIDSYNTH_TARGET}
)

if(ANDROID)
    install(FILES GeneralUser-v1.47.sf2 DESTINATION ${KDE_INSTALL_DATADIR}/minuet/soundfonts)
else()
    install(TARGETS minuetfluidsynthsoundcontroller DESTINATION ${KDE_INSTALL_PLUGINDIR}/minuet/)
    install(FILES GeneralUser-v1.47.sf2 DESTINATION ${KDE_INSTALL_DATADIR}/minuet/soundfonts)
endif()
