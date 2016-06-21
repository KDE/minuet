set(fluidsynthsoundbackend_PLUGIN_SRCS
    fluidsynthsoundbackend.cpp
)

add_library(minuetfluidsynthsoundbackend MODULE ${fluidsynthsoundbackend_PLUGIN_SRCS})

target_link_libraries(minuetfluidsynthsoundbackend
    Minuet::Interfaces
)

install(TARGETS minuetfluidsynthsoundbackend DESTINATION ${PLUGIN_INSTALL_DIR}/minuet/)
