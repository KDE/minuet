set(minuet_SRCS
    main.cpp
)

add_executable(minuet ${minuet_SRCS})

target_link_libraries(minuet
    Qt5::Widgets
    KF5::Crash
    KF5::CoreAddons
    KF5::I18n
    Minuet::Interfaces
    Minuet::Shell
)

install(TARGETS minuet ${INSTALL_TARGETS_DEFAULT_ARGS})
install(DIRECTORY qml DESTINATION ${KDE_INSTALL_DATADIR}/minuet)
install(PROGRAMS org.kde.minuet.desktop DESTINATION ${XDG_APPS_INSTALL_DIR})
