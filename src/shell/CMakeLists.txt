set(minuetshell_LIB_SRCS
    core.cpp
    plugincontroller.cpp
    exercisecontroller.cpp
)

add_library(minuetshell ${minuetshell_LIB_SRCS})
add_library(Minuet::Shell ALIAS minuetshell)

generate_export_header(minuetshell EXPORT_FILE_NAME minuetshellexport.h)

target_link_libraries(minuetshell
    Minuet::Interfaces
    KF5::CoreAddons
)

install(TARGETS
    minuetshell
    EXPORT MinuetTargets
    ${KDE_INSTALL_TARGETS_DEFAULT_ARGS}
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/minuetshellexport.h
    DESTINATION ${KDE_INSTALL_INCLUDEDIR}/minuet/shell
    COMPONENT Devel)

install(FILES
    core.h
    plugincontroller.h
    exercisecontroller.h
    DESTINATION ${KDE_INSTALL_INCLUDEDIR}/minuet/shell
    COMPONENT Devel
)
