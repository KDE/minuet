# SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
#
# SPDX-License-Identifier: GPL-2.0-or-later

set(minuet_SRCS
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

if(NOT MINUET_MOBILE_PLATFORM)
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
endif()

qt_add_executable(minuet)

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    set_target_properties(minuet PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_GUI_IDENTIFIER org.kde.minuet
        MACOSX_BUNDLE_BUNDLE_NAME Minuet
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
    )
endif()

set(minuet_qml_module_options)
if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    # Qt 6.11 creates a non-idempotent clean_qml_context_properties target
    # that can fail Xcode builds when contextPropertyDump.ini is already absent.
    list(APPEND minuet_qml_module_options
        NO_LINT
        IMPORT_PATH ${KDE_INSTALL_FULL_QMLDIR}
    )
endif()

qt_add_qml_module(minuet
    ${minuet_qml_module_options}
    URI org.kde.minuet
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    SOURCES
        ${minuet_SRCS}
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
        qml/ExerciseView.qml
        qml/MinuetDrawer.qml
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

qt_add_resources(minuet minuet_assets
    PREFIX /
    FILES
        qml/images/minuet-icon.svg
        qml/images/minuet-icon.png
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

if(MINUET_MOBILE_PLATFORM)
    file(GLOB minuet_DEFINITION_FILES CONFIGURE_DEPENDS
        ${CMAKE_SOURCE_DIR}/data/definitions/*.json
    )
    file(GLOB minuet_EXERCISE_FILES CONFIGURE_DEPENDS
        ${CMAKE_SOURCE_DIR}/data/exercises/*.json
    )
    qt_add_resources(minuet minuet_mobile_data
        PREFIX /
        BASE ${CMAKE_SOURCE_DIR}
        FILES
            ${minuet_DEFINITION_FILES}
            ${minuet_EXERCISE_FILES}
            ${CMAKE_SOURCE_DIR}/src/plugins/fluidsynthsoundcontroller/GeneralUser-v1.47.sf2
    )
endif()

target_link_libraries(minuet PRIVATE
    Qt::Core
    Qt::Gui
    Qt::Qml
    Qt::Quick
    Qt::QuickControls2
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

if(ANDROID)
    set_target_properties(minuet PROPERTIES
        QT_ANDROID_PACKAGE_NAME org.kde.minuet
        QT_ANDROID_MIN_SDK_VERSION 28
        QT_ANDROID_TARGET_SDK_VERSION 35
        QT_ANDROID_VERSION_CODE ${RELEASE_SERVICE_COMPACT_VERSION}
        QT_ANDROID_VERSION_NAME ${PROJECT_VERSION}
    )
    kirigami_package_breeze_icons(ICONS
        ${KIRIGAMI_ADDONS_ICONS}
        arrow-up
        arrow-down
        dialog-close
        go-home
        help-about-symbolic
        settings-configure
        view-list-details
    )
    ecm_add_android_apk(minuet ANDROID_DIR ${CMAKE_SOURCE_DIR}/android)
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    # Locate the directory where Breeze icons were installed by the dependency script
    find_path(BREEZE_ICONS_DIR
        NAMES index.theme
        PATHS "${KDE_INSTALL_FULL_ICONDIR}/breeze"
        NO_DEFAULT_PATH
   )

    if(BREEZE_ICONS_DIR)
        # Explicit list of standard Breeze SVG icons required by Kirigami/Minuet layouts
        set(REQUIRED_BREEZE_ICONS
	    "actions/22/arrow-up.svg"
            "actions/22/arrow-down.svg"
            "actions/22/dialog-close.svg"
            "actions/22/go-home.svg"
            "actions/22/help-about-symbolic.svg"
            "actions/22/settings-configure.svg"
            "actions/22/view-list-details.svg"
            "actions/22/application-exit.svg"
            "actions/22/dialog-error.svg"
            "actions/22/dialog-information.svg"
            "actions/22/dialog-positive.svg"
            "actions/22/dialog-warning.svg"
            "actions/22/edit-clear-locationbar-ltr.svg"
            "actions/22/edit-clear-locationbar-rtl.svg"
            "actions/22/edit-copy.svg"
            "actions/22/edit-delete-remove.svg"
            "emblems/22/emblem-error.svg"
            "emblems/22/emblem-information.svg"
            "emblems/22/emblem-success.svg"
            "emblems/22/emblem-warning.svg"
            "actions/22/globe.svg"
            "actions/22/go-next.svg"
            "actions/22/go-next-symbolic.svg"
            "actions/22/go-next-symbolic-rtl.svg"
            "actions/22/go-previous.svg"
            "actions/22/go-previous-symbolic.svg"
            "actions/22/go-previous-symbolic-rtl.svg"
            "actions/22/go-up.svg"
            "actions/22/handle-sort.svg"
            "actions/22/mail-sent.svg"
            "actions/22/open-menu-symbolic.svg"
            "actions/22/open-link-symbolic.svg"
            "actions/22/open-link-symbolic-rtl.svg"
            "actions/22/overflow-menu-left.svg"
            "actions/22/overflow-menu-right.svg"
            "actions/22/overflow-menu.svg"
            "actions/22/password-show-off.svg"
            "actions/22/password-show-on.svg"
            "status/22/process-working-symbolic.svg"
            "actions/22/search.svg"
            "actions/22/tools-report-bug.svg"
            "actions/22/user.svg"
            "actions/22/view-left-new.svg"
            "actions/22/view-right-new.svg"
            "actions/22/view-left-close.svg"
            "actions/22/view-right-close.svg"
            "actions/22/globe-symbolic.svg"
            "actions/22/tools-report-bug-symbolic.svg"
            "actions/22/donate-symbolic.svg"
            "categories/22/applications-development-symbolic.svg"
            "actions/22/edit-copy-symbolic.svg"
            "actions/22/get-hot-new-stuff-symbolic.svg"
            "actions/22/mail-sent-symbolic.svg"
            "actions/22/license-symbolic.svg"
            "actions/22/go-previous-view-symbolic.svg"
            "actions/22/go-previous-rtl-symbolic.svg"
            "actions/22/go-jump-today-symbolic.svg"
            "actions/22/go-next-view-symbolic.svg"
            "actions/22/go-next-rtl-symbolic.svg"
            "actions/22/view-calendar-symbolic.svg"
            "status/22/clock-symbolic.svg"
            "actions/22/dialog-cancel-symbolic.svg"
            "actions/22/dialog-ok-apply-symbolic.svg"
            "actions/22/draw-arrow-back-symbolic.svg"
            "actions/22/system-user-list.svg"
            "actions/22/arrow-left.svg"
            "actions/22/arrow-right.svg"
            "actions/22/zoom-in.svg"
            "actions/22/zoom-out.svg"
            "actions/22/object-rotate-left.svg"
            "actions/22/object-rotate-right.svg"
            "actions/22/add-subtitle.svg"
            "actions/22/document-save.svg"
            "actions/22/open-menu.svg"
            "actions/22/application-menu.svg"
            "actions/22/application-menu-symbolic.svg"
            "actions/22/sidebar-show.svg"
            "actions/22/view-get-hot-new-symbolic.svg"
	    "actions/22/window-close-symbolic.svg"
            "actions/22/dialog-close-symbolic.svg"
        )

        set(BREEZE_RESOURCE_FILES)
        foreach(icon ${REQUIRED_BREEZE_ICONS})
            if(EXISTS "${BREEZE_ICONS_DIR}/${icon}")
                list(APPEND BREEZE_RESOURCE_FILES "${BREEZE_ICONS_DIR}/${icon}")
            endif()
        endforeach()

        # Include the core index.theme so the Qt Icon Engine recognizes the directory structure
        if(EXISTS "${BREEZE_ICONS_DIR}/index.theme")
            list(APPEND BREEZE_RESOURCE_FILES "${BREEZE_ICONS_DIR}/index.theme")
        endif()

        # Package the assets directly into the application binary under the required virtual prefix
        qt_add_resources(minuet breeze_mobile_icons
            PREFIX /icons/breeze
            BASE ${BREEZE_ICONS_DIR}
            FILES ${BREEZE_RESOURCE_FILES}
        )
    endif()
endif()

if(MINUET_MOBILE_PLATFORM)
    target_link_libraries(minuet PRIVATE
        KF6::ColorScheme
        Minuet::FluidSynthSoundController
    )
endif()

if(APPLE AND NOT (CMAKE_SYSTEM_NAME STREQUAL "iOS"))
    find_library(CoreFoundation_FRAMEWORK CoreFoundation REQUIRED)
    target_link_libraries(minuet PRIVATE KF6::IconThemes ${CoreFoundation_FRAMEWORK})
endif()

if(NOT MINUET_MOBILE_PLATFORM)
    target_link_libraries(minuet PRIVATE
        KF6::Crash
    )
endif()

if(NOT MINUET_MOBILE_PLATFORM)
    install(TARGETS minuet ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
    install(PROGRAMS org.kde.minuet.desktop DESTINATION ${KDE_INSTALL_APPDIR})
endif()
