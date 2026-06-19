# SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
#
# SPDX-License-Identifier: GPL-2.0-or-later

set(MINUET_SRCS
    main.cpp
    core.cpp
    exercisecatalogcontroller.cpp
    exercisesessioncontroller.cpp
    instrumentcatalogcontroller.cpp
    pianokeyboardcontroller.cpp
    uicontroller.cpp
    plugincontroller.cpp
    settingscontroller.cpp
    sheetmusiccontroller.cpp
    smuflmetadata.cpp
)

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    list(APPEND MINUET_SRCS ios/iossplashscreen.h ios/iossplashscreen.mm)
    set_source_files_properties(
        ios/iossplashscreen.mm PROPERTIES COMPILE_OPTIONS "-fobjc-arc"
    )
endif()

if(NOT MINUET_MOBILE_PLATFORM)
    set(_minuet_icon_dir "${CMAKE_CURRENT_SOURCE_DIR}/icons")
    set(MINUET_ICONS_PNG
        ${_minuet_icon_dir}/16-apps-minuet.png
        ${_minuet_icon_dir}/22-apps-minuet.png
        ${_minuet_icon_dir}/32-apps-minuet.png
        ${_minuet_icon_dir}/48-apps-minuet.png
        ${_minuet_icon_dir}/64-apps-minuet.png
        ${_minuet_icon_dir}/128-apps-minuet.png
    )

    set(MINUET_ICONS_SVG
        ${_minuet_icon_dir}/sc-apps-minuet.svgz
        ${_minuet_icon_dir}/16-apps-minuet.svg
        ${_minuet_icon_dir}/22-apps-minuet.svg
        ${_minuet_icon_dir}/32-apps-minuet.svg
        ${_minuet_icon_dir}/48-apps-minuet.svg
        ${_minuet_icon_dir}/64-apps-minuet.svg
        ${_minuet_icon_dir}/128-apps-minuet.svg
        ${_minuet_icon_dir}/16-actions-minuet-scales-symbolic.svg
        ${_minuet_icon_dir}/16-actions-minuet-intervals-symbolic.svg
        ${_minuet_icon_dir}/16-actions-minuet-chords-symbolic.svg
        ${_minuet_icon_dir}/16-actions-minuet-rhythms-symbolic.svg
        ${_minuet_icon_dir}/16-actions-minuet-clap-symbolic.svg
        ${_minuet_icon_dir}/16-actions-minuet-sing-symbolic.svg
        ${_minuet_icon_dir}/22-actions-minuet-scales-symbolic.svg
        ${_minuet_icon_dir}/22-actions-minuet-intervals-symbolic.svg
        ${_minuet_icon_dir}/22-actions-minuet-chords-symbolic.svg
        ${_minuet_icon_dir}/22-actions-minuet-rhythms-symbolic.svg
        ${_minuet_icon_dir}/22-actions-minuet-clap-symbolic.svg
        ${_minuet_icon_dir}/22-actions-minuet-sing-symbolic.svg
    )

    ecm_add_app_icon(MINUET_SRCS ICONS ${MINUET_ICONS_PNG})
    ecm_install_icons(
        ICONS
        ${MINUET_ICONS_PNG}
        ${MINUET_ICONS_SVG}
        DESTINATION
        ${KDE_INSTALL_ICONDIR}
        THEME
        hicolor
    )
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    qt_add_executable(minuet)
else()
    add_executable(minuet)
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    set(IOS_ASSETS ${CMAKE_CURRENT_SOURCE_DIR}/ios/Assets.xcassets)
    set(IOS_LAUNCH_SCREEN
        ${CMAKE_CURRENT_SOURCE_DIR}/ios/LaunchScreen.storyboard
    )
    target_sources(minuet PRIVATE ${IOS_ASSETS})
    set_source_files_properties(
        ${IOS_ASSETS} PROPERTIES MACOSX_PACKAGE_LOCATION Resources
    )

    set_target_properties(
        minuet
        PROPERTIES
            MACOSX_BUNDLE TRUE
            MACOSX_BUNDLE_GUI_IDENTIFIER org.kde.minuet
            MACOSX_BUNDLE_BUNDLE_NAME Minuet
            MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
            MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
            QT_IOS_LAUNCH_SCREEN ${IOS_LAUNCH_SCREEN}
            XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME AppIcon
            XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION ${PROJECT_VERSION}
            XCODE_ATTRIBUTE_INFOPLIST_KEY_NSMicrophoneUsageDescription
            "Minuet uses the microphone for clapping and singing exercises."
    )
endif()

set(MINUET_QML_MODULE_OPTIONS)
if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    # Qt 6.11 creates a non-idempotent clean_qml_context_properties target that
    # can fail Xcode builds when contextPropertyDump.ini is already absent.
    list(APPEND MINUET_QML_MODULE_OPTIONS NO_LINT IMPORT_PATH
         ${KDE_INSTALL_FULL_QMLDIR}
    )
endif()

qt_add_qml_module(
    minuet
    ${MINUET_QML_MODULE_OPTIONS}
    URI
    org.kde.minuet
    VERSION
    1.0
    RESOURCE_PREFIX
    /qt/qml
    SOURCES
    ${MINUET_SRCS}
    core.h
    exercisecatalogcontroller.h
    exercisesessioncontroller.h
    instrumentcatalogcontroller.h
    interfaceqmltypes.h
    pianokeyboardcontroller.h
    plugincontroller.h
    settingscontroller.h
    sheetmusiccontroller.h
    smuflmetadata.h
    uicontroller.h
    QML_FILES
    qml/Main.qml
    qml/AboutPage.qml
    qml/ActionListItem.qml
    qml/ExerciseMenuPage.qml
    qml/ExercisePage.qml
    qml/AccuracyMeter.qml
    qml/ExerciseClappingView.qml
    qml/ExerciseSingingView.qml
    qml/ExerciseView.qml
    qml/GraphicalMeter.qml
    qml/MinuetDrawer.qml
    qml/PracticeModePage.qml
    qml/SettingsPage.qml
    qml/PianoView/BlackKey.qml
    qml/PianoView/Octave.qml
    qml/PianoView/PianoView.qml
    qml/PianoView/WhiteKey.qml
    qml/SheetMusicView/BravuraText.qml
    qml/SheetMusicView/SheetMusicView.qml
    RESOURCES
    qml/SheetMusicView/Bravura.otf
    qml/SheetMusicView/bravura_metadata.json
)

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    foreach(pofile IN LISTS MINUET_PO_FILES)
        get_filename_component(language_dir "${pofile}" DIRECTORY)
        get_filename_component(language "${language_dir}" NAME)
        set(MO_FILE
            "${CMAKE_BINARY_DIR}/locale/${language}/LC_MESSAGES/minuet.mo"
        )
        set_source_files_properties(
            "${MO_FILE}"
            PROPERTIES GENERATED TRUE
                       MACOSX_PACKAGE_LOCATION
                       "Resources/locale/${language}/LC_MESSAGES"
        )
        target_sources(minuet PRIVATE "${MO_FILE}")
    endforeach()
endif()

qt_add_resources(
    minuet
    minuet_assets
    PREFIX
    /
    FILES
    qml/images/minuet-icon.svg
    qml/images/minuet-icon.png
    qml/images/menu.png
    qml/images/keyboard_arrow_left.png
    qml/images/more_vert.png
    icons/64-apps-minuet.png
    icons/22-actions-minuet-chords-symbolic.svg
    icons/22-actions-minuet-clap-symbolic.svg
    icons/22-actions-minuet-intervals-symbolic.svg
    icons/22-actions-minuet-rhythms-symbolic.svg
    icons/22-actions-minuet-scales-symbolic.svg
    icons/22-actions-minuet-sing-symbolic.svg
    icons/pitch-meter-background.png
    icons/tempo-meter-background.png
    icons/meter-needle.png
    qtquickcontrols2.conf
    +android/qtquickcontrols2.conf
    +windows/qtquickcontrols2.conf
)

if(MINUET_MOBILE_PLATFORM)
    file(GLOB minuet_DEFINITION_FILES CONFIGURE_DEPENDS
         ${CMAKE_SOURCE_DIR}/data/definitions/*.json
    )
    file(GLOB minuet_EXERCISE_FILES CONFIGURE_DEPENDS
         ${CMAKE_SOURCE_DIR}/data/exercises/*.json
    )
    list(FILTER minuet_EXERCISE_FILES EXCLUDE REGEX
         ".*/(singing-exercises|clapping-rhythm-exercises)\\.json$"
    )
    string(CONCAT _minuet_soundfont
                  "${CMAKE_SOURCE_DIR}/src/plugins/fluidsynthsoundcontroller/"
                  "GeneralUser-v1.47.sf2"
    )
    qt_add_resources(
        minuet
        minuet_mobile_data
        PREFIX
        /
        BASE
        ${CMAKE_SOURCE_DIR}
        FILES
        ${minuet_DEFINITION_FILES}
        ${minuet_EXERCISE_FILES}
        ${_minuet_soundfont}
    )
endif()

target_link_libraries(
    minuet
    PRIVATE Qt::Core
            Qt::Gui
            Qt::Qml
            Qt::Quick
            Qt::QuickControls2
            Qt::Multimedia
            Qt::Svg
            KF6::CoreAddons
            KF6::I18n
            KF6::I18nQml
            KF6::Kirigami
            KirigamiApp
            KirigamiAddonsComponents
            Minuet::Interfaces
            Minuet::Utils
)

if(ANDROID OR CMAKE_SYSTEM_NAME STREQUAL "iOS")
    kirigami_package_breeze_icons(
        TARGET
        minuet
        ICONS
        ${KIRIGAMI_ADDONS_ICONS}
        arrow-up
        arrow-down
        data-information
        dialog-close
        go-home-symbolic
        help-about-symbolic
        help-contents
        settings-configure-symbolic
        view-list-details-symbolic
        open-menu
        application-menu
        application-menu-symbolic
        sidebar-show
        view-get-hot-new-symbolic
        window-close-symbolic
        dialog-close-symbolic
        dialog-cancel-symbolic
        go-next-symbolic
        go-previous-symbolic
    )
endif()

if(ANDROID)
    set_target_properties(
        minuet
        PROPERTIES QT_ANDROID_PACKAGE_NAME org.kde.minuet
                   QT_ANDROID_MIN_SDK_VERSION 28
                   QT_ANDROID_TARGET_SDK_VERSION 35
                   QT_ANDROID_VERSION_CODE ${RELEASE_SERVICE_COMPACT_VERSION}
                   QT_ANDROID_VERSION_NAME ${PROJECT_VERSION}
    )
    ecm_add_android_apk(minuet ANDROID_DIR ${MINUET_ANDROID_PACKAGE_DIR})
endif()

if(MINUET_MOBILE_PLATFORM)
    target_link_libraries(
        minuet PRIVATE KF6::ColorScheme Minuet::FluidSynthSoundController
                       Minuet::AubioMicrophoneInputController
    )
endif()

if(APPLE)
    find_library(CoreFoundation_FRAMEWORK CoreFoundation REQUIRED)
    target_link_libraries(minuet PRIVATE ${CoreFoundation_FRAMEWORK})
endif()

if(APPLE AND NOT (CMAKE_SYSTEM_NAME STREQUAL "iOS"))
    target_link_libraries(minuet PRIVATE KF6::IconThemes)
endif()

if(NOT MINUET_MOBILE_PLATFORM)
    target_link_libraries(minuet PRIVATE KF6::Crash)
endif()

if(NOT MINUET_MOBILE_PLATFORM)
    install(TARGETS minuet ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
    install(PROGRAMS org.kde.minuet.desktop DESTINATION ${KDE_INSTALL_APPDIR})
endif()
