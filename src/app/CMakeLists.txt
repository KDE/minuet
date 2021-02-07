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
    ecm_install_icons(ICONS ${minuet_ICONS_PNG} ${minuet_ICONS_SVG} DESTINATION ${KDE_INSTALL_ICONDIR} THEME hicolor)
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")

if(ANDROID)
    include(../../cmake/qt-android-mk-apk.cmake)
    add_library(minuet SHARED ${minuet_SRCS})
    qt_android_build_apk(
        TARGET ${PROJECT_NAME}
        PACKAGE_NAME org.kde.minuet
        QML_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR}
        ANDROID_EXTRA_FILES ${CMAKE_CURRENT_SOURCE_DIR}/../../android
        EXTRA_LIBS ../plugins/csoundsoundcontroller/libminuetcsoundsoundcontroller.so,../interfaces/libminuetinterfaces.so,../../src/plugins/csoundsoundcontroller/Csound-prefix/src/Csound/Android/CsoundAndroid/libs/arm64-v8a/libcsoundandroid.so,../../src/plugins/csoundsoundcontroller/Csound-prefix/src/Csound/Android/CsoundAndroid/libs/arm64-v8a/libsndfile.so,../../src/plugins/csoundsoundcontroller/Csound-prefix/src/Csound/Android/pluginlibs/libfluidsynth/libs/arm64-v8a/libfluidOpcodes.so,../../src/plugins/csoundsoundcontroller/Csound-prefix/src/Csound/Android/CsoundAndroid/libs/arm64-v8a/libc++_shared.so
    )
else()
    add_executable(minuet ${minuet_SRCS})
endif()

target_link_libraries(minuet
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::QuickControls2
    Qt5::Svg
    Minuet::Interfaces
    Minuet::Utils
)

if(ANDROID)
    target_link_libraries(minuet
        Minuet::CsoundSoundController
    )
endif()

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
target_link_libraries(minuet
    KF5::CoreAddons
    KF5::I18n
    KF5::Crash
)
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    install(TARGETS minuet ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
    install(PROGRAMS org.kde.minuet.desktop DESTINATION ${KDE_INSTALL_APPDIR})
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
