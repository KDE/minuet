set(minuet_SRCS
    core.cpp
    plugincontroller.cpp
    uicontroller.cpp
    exercisecontroller.cpp
    mainwindow.cpp
    main.cpp
)

ki18n_wrap_ui(minuet_SRCS
    settingsmidi.ui
)

kconfig_add_kcfg_files(minuet_SRCS minuetsettings.kcfgc)

add_executable(minuet ${minuet_SRCS})

target_link_libraries(minuet
    Qt5::Core
    Qt5::Quick
    Qt5::Widgets
    KF5::Crash
    KF5::CoreAddons
    KF5::WidgetsAddons
    KF5::I18n
    KF5::KIOWidgets
    KF5::Completion
    KF5::XmlGui
    KF5::I18n
    Minuet::Interfaces
)

install(TARGETS minuet ${INSTALL_TARGETS_DEFAULT_ARGS})
install(PROGRAMS org.kde.minuet.desktop DESTINATION ${XDG_APPS_INSTALL_DIR})
install(FILES minuetui.rc DESTINATION ${KXMLGUI_INSTALL_DIR}/minuet)
install(DIRECTORY qml DESTINATION ${KDE_INSTALL_DATADIR}/minuet)
