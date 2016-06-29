set(drumsticksoundbackend_PLUGIN_SRCS
    drumsticksoundbackend.cpp
)

add_library(minuetdrumsticksoundbackend MODULE ${drumsticksoundbackend_PLUGIN_SRCS})

target_link_libraries(minuetdrumsticksoundbackend
    Qt5::Core
    Minuet::Interfaces
)

install(TARGETS minuetdrumsticksoundbackend DESTINATION ${PLUGIN_INSTALL_DIR}/minuet/)
