set(minuetinterfaces_LIB_SRCS
    icore.cpp
    iplugin.cpp
    iplugincontroller.cpp
    iuicontroller.cpp
    isoundcontroller.cpp
    iexercisecontroller.cpp
)

add_library(minuetinterfaces ${minuetinterfaces_LIB_SRCS})
add_library(Minuet::Interfaces ALIAS minuetinterfaces)

set_target_properties(minuetinterfaces PROPERTIES VERSION 0.3.0)

generate_export_header(minuetinterfaces EXPORT_FILE_NAME minuetinterfacesexport.h)

target_link_libraries(minuetinterfaces
    Qt5::Core
    Qt5::Quick
)

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/minuetinterfacesexport.h
        DESTINATION ${KDE_INSTALL_INCLUDEDIR}/minuet/interfaces
        COMPONENT Devel
    )

    install(TARGETS
        minuetinterfaces
        EXPORT MinuetTargets
        ${KDE_INSTALL_TARGETS_DEFAULT_ARGS}
    )

    install(FILES
        icore.h
        iplugin.h
        iplugincontroller.h
        iuicontroller.h
        isoundcontroller.h
        iexercisecontroller.h
        DESTINATION ${KDE_INSTALL_INCLUDEDIR}/minuet/interfaces
        COMPONENT Devel
    )
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
