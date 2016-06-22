set(minuetinterfaces_LIB_SRCS
    icore.cpp
    iplugin.cpp
    iplugincontroller.cpp
    iuicontroller.cpp
    isoundbackend.cpp
    iexercisecontroller.cpp
)

add_library(minuetinterfaces ${minuetinterfaces_LIB_SRCS})
add_library(Minuet::Interfaces ALIAS minuetinterfaces)

generate_export_header(minuetinterfaces EXPORT_FILE_NAME minuetinterfacesexport.h)

target_link_libraries(minuetinterfaces
    Qt5::Core
)

install(TARGETS
    minuetinterfaces
    EXPORT MinuetTargets
    ${KDE_INSTALL_TARGETS_DEFAULT_ARGS}
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/minuetinterfacesexport.h
    DESTINATION ${KDE_INSTALL_INCLUDEDIR}/minuet/interfaces
    COMPONENT Devel)

install(FILES
    icore.h
    iplugin.h
    iplugincontroller.h
    iuicontroller.h
    isoundbackend.h
    iexercisecontroller.h
    DESTINATION ${KDE_INSTALL_INCLUDEDIR}/minuet/interfaces
    COMPONENT Devel
)

