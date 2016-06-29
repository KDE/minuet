kde_enable_exceptions()

set(drumsticksoundbackend_PLUGIN_SRCS
    drumsticksoundbackend.cpp
    midisequenceroutputthread.cpp
    song.cpp
)

add_library(minuetdrumsticksoundbackend MODULE ${drumsticksoundbackend_PLUGIN_SRCS})

target_link_libraries(minuetdrumsticksoundbackend
    Qt5::Core
    asound
    drumstick-alsa
    drumstick-file
    Minuet::Interfaces
)

install(TARGETS minuetdrumsticksoundbackend DESTINATION ${PLUGIN_INSTALL_DIR}/minuet/)
