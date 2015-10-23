set( minuet_SRCS
    main.cpp
    minuet.cpp
    minuetview.cpp
)

kconfig_add_kcfg_files(minuet_SRCS minuetSettings.kcfgc)
ki18n_wrap_ui(minuet_SRCS minuetViewBase.ui settingsBase.ui)

add_executable( minuet ${minuet_SRCS} )

target_link_libraries( minuet
    Qt5::Widgets
    KF5::CoreAddons
    KF5::I18n
    KF5::XmlGui
    KF5::ConfigWidgets
)

install( TARGETS minuet ${INSTALL_TARGETS_DEFAULT_ARGS} )
install( PROGRAMS minuet.desktop  DESTINATION ${XDG_APPS_INSTALL_DIR} )
install( FILES minuetui.rc DESTINATION ${KXMLGUI_INSTALL_DIR}/minuet )
