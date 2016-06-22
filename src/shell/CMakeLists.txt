kde_enable_exceptions()

set(minuetshell_LIB_SRCS
    core.cpp
    plugincontroller.cpp
    uicontroller.cpp
    exercisecontroller.cpp
    minuetmainwindow.cpp
    wizard.cpp
    midisequencer.cpp
    song.cpp
    midisequenceroutputthread.cpp
)

ki18n_wrap_ui(minuetshell_LIB_SRCS
    settingsmidi.ui
    wizardsystemcheck.ui
)

kconfig_add_kcfg_files(minuetshell_LIB_SRCS minuetsettings.kcfgc)

add_library(minuetshell ${minuetshell_LIB_SRCS})
add_library(Minuet::Shell ALIAS minuetshell)

generate_export_header(minuetshell EXPORT_FILE_NAME minuetshellexport.h)

target_link_libraries(minuetshell
    Qt5::Core
    Qt5::Gui
    Qt5::Quick
    Qt5::Widgets
    KF5::CoreAddons
    KF5::WidgetsAddons
    KF5::KIOWidgets
    KF5::Completion
    KF5::XmlGui
    KF5::I18n
    asound
    drumstick-alsa
    drumstick-file
    Minuet::Interfaces
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
    uicontroller.h
    exercisecontroller.h
    minuetmainwindow.h
    wizard.h
    midisequencer.h
    song.h
    midisequenceroutputthread.h
    DESTINATION ${KDE_INSTALL_INCLUDEDIR}/minuet/shell
    COMPONENT Devel
)
install(FILES minuetui.rc DESTINATION ${KXMLGUI_INSTALL_DIR}/minuet)
