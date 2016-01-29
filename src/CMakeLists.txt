kde_enable_exceptions()

set(minuet_SRCS
    main.cpp
    song.cpp
    wizard.cpp
    minuet.cpp
    midisequencer.cpp
    midisequenceroutputthread.cpp
    exercisecontroller.cpp
)

kconfig_add_kcfg_files(minuet_SRCS minuetsettings.kcfgc)
ki18n_wrap_ui(minuet_SRCS
    settingsmidi.ui
    wizardsystemcheck.ui
)

add_executable(minuet ${minuet_SRCS})

target_link_libraries(minuet
    Qt5::Core
    Qt5::Gui
    Qt5::Widgets
    Qt5::Quick
    KF5::CoreAddons
    KF5::I18n
    KF5::XmlGui
    KF5::ConfigWidgets
    KF5::KIOWidgets
    KF5::Crash
    drumstick-file
    drumstick-alsa
    asound
)

install(TARGETS minuet ${INSTALL_TARGETS_DEFAULT_ARGS})
install(DIRECTORY qml DESTINATION ${KDE_INSTALL_DATADIR}/minuet)
install(PROGRAMS org.kde.minuet.desktop DESTINATION ${XDG_APPS_INSTALL_DIR})
install(FILES minuetui.rc DESTINATION ${KXMLGUI_INSTALL_DIR}/minuet)
