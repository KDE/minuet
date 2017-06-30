set(minuet_SRCS
    main.cpp
    core.cpp
    uicontroller.cpp
    plugincontroller.cpp
    exercisecontroller.cpp
)

qt5_add_resources(minuet_SRCS qml.qrc)

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    set(minuet_ICONS_PNG
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/16-apps-minuet.png
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/22-apps-minuet.png
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/32-apps-minuet.png
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/48-apps-minuet.png
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/64-apps-minuet.png
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/128-apps-minuet.png
    )

    set(minuet_ICONS_SVG
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/sc-apps-minuet.svgz
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/16-apps-minuet.svg
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/22-apps-minuet.svg
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/32-apps-minuet.svg
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/48-apps-minuet.svg
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/64-apps-minuet.svg
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/128-apps-minuet.svg
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/16-actions-minuet-scales.svg
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/16-actions-minuet-intervals.svg
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/16-actions-minuet-chords.svg
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/16-actions-minuet-rhythms.svg
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/22-actions-minuet-scales.svg
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/22-actions-minuet-intervals.svg
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/22-actions-minuet-chords.svg
        ${CMAKE_CURRENT_SOURCE_DIR}/icons/22-actions-minuet-rhythms.svg
    )

    ecm_add_app_icon(minuet_SRCS ICONS ${minuet_ICONS_PNG})
    ecm_install_icons(ICONS ${minuet_ICONS_PNG} ${minuet_ICONS_SVG} DESTINATION ${ICON_INSTALL_DIR} THEME hicolor)
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")

add_executable(minuet ${minuet_SRCS})

target_link_libraries(minuet
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::QuickControls2
    Qt5::Svg
    Minuet::Interfaces
)

IF(${CMAKE_SYSTEM_NAME} MATCHES "Android")
    target_link_libraries(minuet
        Minuet::CsoundSoundController
    )
ENDIF(${CMAKE_SYSTEM_NAME} MATCHES "Android")

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
target_link_libraries(minuet
    KF5::CoreAddons
    KF5::I18n
    KF5::Crash
)
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    install(TARGETS minuet ${INSTALL_TARGETS_DEFAULT_ARGS})
    install(PROGRAMS org.kde.minuet.desktop DESTINATION ${XDG_APPS_INSTALL_DIR})
    install(TARGETS minuet RUNTIME DESTINATION bin)
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")

add_subdirectory(plugins)