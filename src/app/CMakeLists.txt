set(minuet_SRCS
    main.cpp
    core.cpp
    uicontroller.cpp
    plugincontroller.cpp
    exercisecontroller.cpp
)

function(minuet_set_resource_alias file alias)
    set_source_files_properties(${file} PROPERTIES QT_RESOURCE_ALIAS ${alias})
endfunction()

minuet_set_resource_alias(qml/Main.qml Main.qml)
minuet_set_resource_alias(qml/AboutDialog.qml AboutDialog.qml)
minuet_set_resource_alias(qml/MinuetGlobalDrawer.qml MinuetGlobalDrawer.qml)
minuet_set_resource_alias(+android/qml/MinuetGlobalDrawer.qml +android/MinuetGlobalDrawer.qml)
minuet_set_resource_alias(qml/ExerciseView.qml ExerciseView.qml)
minuet_set_resource_alias(qml/PianoView/BlackKey.qml BlackKey.qml)
minuet_set_resource_alias(qml/PianoView/Octave.qml Octave.qml)
minuet_set_resource_alias(qml/PianoView/PianoView.qml PianoView.qml)
minuet_set_resource_alias(qml/PianoView/WhiteKey.qml WhiteKey.qml)
minuet_set_resource_alias(qml/SheetMusicView/Bravura.otf Bravura.otf)
minuet_set_resource_alias(qml/SheetMusicView/BravuraText.qml BravuraText.qml)
minuet_set_resource_alias(qml/SheetMusicView/Clef.qml Clef.qml)
minuet_set_resource_alias(qml/SheetMusicView/Note.qml Note.qml)
minuet_set_resource_alias(qml/SheetMusicView/Score.qml Score.qml)
minuet_set_resource_alias(qml/SheetMusicView/Sequence.qml Sequence.qml)
minuet_set_resource_alias(qml/SheetMusicView/SheetMusicView.qml SheetMusicView.qml)
minuet_set_resource_alias(qml/images/menu.png menu.png)
minuet_set_resource_alias(qml/images/keyboard_arrow_left.png keyboard_arrow_left.png)
minuet_set_resource_alias(qml/images/more_vert.png more_vert.png)
minuet_set_resource_alias(icons/64-apps-minuet.png minuet.png)
minuet_set_resource_alias(icons/22-actions-minuet-chords.svg minuet-chords.svg)
minuet_set_resource_alias(icons/22-actions-minuet-intervals.svg minuet-intervals.svg)
minuet_set_resource_alias(icons/22-actions-minuet-rhythms.svg minuet-rhythms.svg)
minuet_set_resource_alias(icons/22-actions-minuet-scales.svg minuet-scales.svg)

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

add_executable(minuet ${minuet_SRCS})

qt_add_qml_module(minuet
    URI org.kde.minuet
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    NO_GENERATE_EXTRA_QMLDIRS
    QML_FILES
        qml/Main.qml
        qml/AboutDialog.qml
        qml/MinuetGlobalDrawer.qml
        qml/ExerciseView.qml
        qml/PianoView/BlackKey.qml
        qml/PianoView/Octave.qml
        qml/PianoView/PianoView.qml
        qml/PianoView/WhiteKey.qml
        qml/SheetMusicView/BravuraText.qml
        qml/SheetMusicView/Clef.qml
        qml/SheetMusicView/Note.qml
        qml/SheetMusicView/Score.qml
        qml/SheetMusicView/Sequence.qml
        qml/SheetMusicView/SheetMusicView.qml
    RESOURCES
        +android/qml/MinuetGlobalDrawer.qml
        qml/SheetMusicView/Bravura.otf
)

qt_add_resources(minuet minuet_assets
    PREFIX /
    FILES
        qml/images/minuet-drawer.png
        qml/images/menu.png
        qml/images/keyboard_arrow_left.png
        qml/images/more_vert.png
        icons/64-apps-minuet.png
        icons/22-actions-minuet-chords.svg
        icons/22-actions-minuet-intervals.svg
        icons/22-actions-minuet-rhythms.svg
        icons/22-actions-minuet-scales.svg
        qtquickcontrols2.conf
        +android/qtquickcontrols2.conf
        +windows/qtquickcontrols2.conf
)

target_link_libraries(minuet PRIVATE
    Qt::Core
    Qt::Gui
    Qt::Qml
    Qt::Quick
    Qt::QuickControls2
    Qt::Svg
    KF6::I18n
    KF6::Kirigami
    Minuet::Interfaces
    Minuet::Utils
)

if(ANDROID)
    set(_minuet_android_abi "${CMAKE_ANDROID_ARCH_ABI}")
    if(NOT _minuet_android_abi)
        set(_minuet_android_abi "${ANDROID_ABI}")
    endif()

    find_library(MINUET_OBOE_LIBRARY
        NAMES "oboe_${_minuet_android_abi}"
        PATHS
            "${CMAKE_INSTALL_PREFIX}/lib/${_minuet_android_abi}"
            "${CMAKE_INSTALL_PREFIX}/lib"
        NO_DEFAULT_PATH
    )
    if(NOT MINUET_OBOE_LIBRARY)
        message(FATAL_ERROR "Could not find liboboe_${_minuet_android_abi}.so, required by FluidSynth on Android")
    endif()

    set_target_properties(minuet PROPERTIES
        QT_ANDROID_PACKAGE_NAME org.kde.minuet
        QT_ANDROID_MIN_SDK_VERSION 28
        QT_ANDROID_TARGET_SDK_VERSION 35
        QT_ANDROID_VERSION_CODE ${RELEASE_SERVICE_COMPACT_VERSION}
        QT_ANDROID_VERSION_NAME ${PROJECT_VERSION}
        QT_ANDROID_EXTRA_LIBS ${MINUET_OBOE_LIBRARY}
    )

    target_link_libraries(minuet PRIVATE
        KF6::ColorScheme
        Minuet::FluidSynthSoundController
    )
    ecm_add_android_apk(minuet ANDROID_DIR ${CMAKE_SOURCE_DIR}/android)
endif()

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
target_link_libraries(minuet PRIVATE
    KF6::CoreAddons
    KF6::Crash
)
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    install(TARGETS minuet ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
    install(PROGRAMS org.kde.minuet.desktop DESTINATION ${KDE_INSTALL_APPDIR})
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
