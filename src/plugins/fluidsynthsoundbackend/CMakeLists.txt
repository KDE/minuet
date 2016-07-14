set(fluidsynthsoundbackend_PLUGIN_SRCS
    fluidsynthsoundbackend.cpp
)

add_library(minuetfluidsynthsoundbackend MODULE ${fluidsynthsoundbackend_PLUGIN_SRCS})

target_link_libraries(minuetfluidsynthsoundbackend
    Qt5::Core
    Minuet::Interfaces
    fluidsynth
)

install(TARGETS minuetfluidsynthsoundbackend DESTINATION ${PLUGIN_INSTALL_DIR}/minuet/)
