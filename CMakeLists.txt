# SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
#
# SPDX-License-Identifier: GPL-2.0-or-later

cmake_minimum_required(VERSION 3.16)

set(CMAKE_AUTOMOC ON)
if(${CMAKE_VERSION} VERSION_GREATER "3.10.0")
    cmake_policy(SET CMP0071 OLD)
endif()

# KDE Application Version, managed by release script
set(RELEASE_SERVICE_VERSION_MAJOR "26")
set(RELEASE_SERVICE_VERSION_MINOR "11")
set(RELEASE_SERVICE_VERSION_MICRO "70")
string(CONCAT RELEASE_SERVICE_VERSION "${RELEASE_SERVICE_VERSION_MAJOR}."
              "${RELEASE_SERVICE_VERSION_MINOR}."
              "${RELEASE_SERVICE_VERSION_MICRO}"
)
string(
    CONCAT RELEASE_SERVICE_COMPACT_VERSION "${RELEASE_SERVICE_VERSION_MAJOR}"
           "${RELEASE_SERVICE_VERSION_MINOR}"
           "${RELEASE_SERVICE_VERSION_MICRO}"
)

project(minuet VERSION ${RELEASE_SERVICE_VERSION})

set(MINUET_MOBILE_PLATFORM FALSE)
if(ANDROID OR CMAKE_SYSTEM_NAME STREQUAL "iOS")
    set(MINUET_MOBILE_PLATFORM TRUE)
endif()

set(QT_MIN_VERSION "6.6.2")
set(KF_MIN_VERSION "6.7.0")

find_package(ECM ${KF_MIN_VERSION} CONFIG REQUIRED)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(GenerateExportHeader)
include(ECMFindQmlModule)
include(ECMSetupVersion)
include(ECMInstallIcons)
include(ECMAddAppIcon)
include(KDEClangFormat)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(FeatureSummary)

file(GLOB MINUET_PO_FILES CONFIGURE_DEPENDS
     "${CMAKE_CURRENT_SOURCE_DIR}/po/*/minuet.po"
)
set(MINUET_PLATFORM_TRANSLATED_LANGUAGES)
foreach(pofile IN LISTS MINUET_PO_FILES)
    get_filename_component(language_dir "${pofile}" DIRECTORY)
    get_filename_component(language "${language_dir}" NAME)

    if(language STREQUAL "ca@valencia")
        set(PLATFORM_LANGUAGE "ca-ES-valencia")
    elseif(language STREQUAL "zh_CN")
        set(PLATFORM_LANGUAGE "zh-CN")
    elseif(language STREQUAL "zh_TW")
        set(PLATFORM_LANGUAGE "zh-TW")
    else()
        string(REPLACE "_" "-" PLATFORM_LANGUAGE "${language}")
    endif()
    list(APPEND MINUET_PLATFORM_TRANSLATED_LANGUAGES "${PLATFORM_LANGUAGE}")
endforeach()

if(APPLE)
    set(QT_I18N_SOURCE_LANGUAGE en)
    set(QT_I18N_TRANSLATED_LANGUAGES ${MINUET_PLATFORM_TRANSLATED_LANGUAGES})
endif()

if(ANDROID)
    set(MINUET_ANDROID_PACKAGE_DIR
        "${CMAKE_CURRENT_BINARY_DIR}/android-package"
    )
    file(GLOB_RECURSE minuet_android_package_files CONFIGURE_DEPENDS
         "${CMAKE_CURRENT_SOURCE_DIR}/src/app/android/*"
    )
    file(REMOVE_RECURSE "${MINUET_ANDROID_PACKAGE_DIR}")
    file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/src/app/android/"
         DESTINATION "${MINUET_ANDROID_PACKAGE_DIR}"
    )

    set(MINUET_ANDROID_LOCALE_CONFIG
        "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
    )
    string(APPEND MINUET_ANDROID_LOCALE_CONFIG "<locale-config xmlns:android="
           "\"http://schemas.android.com/apk/res/android\">\n"
    )
    foreach(language IN LISTS MINUET_PLATFORM_TRANSLATED_LANGUAGES)
        string(APPEND MINUET_ANDROID_LOCALE_CONFIG
               "    <locale android:name=\"${language}\"/>\n"
        )
    endforeach()
    string(APPEND MINUET_ANDROID_LOCALE_CONFIG "</locale-config>\n")
    file(MAKE_DIRECTORY "${MINUET_ANDROID_PACKAGE_DIR}/res/xml")
    file(WRITE "${MINUET_ANDROID_PACKAGE_DIR}/res/xml/locales_config.xml"
         "${MINUET_ANDROID_LOCALE_CONFIG}"
    )
endif()

ecm_setup_version(
    ${PROJECT_VERSION} VARIABLE_PREFIX MINUET VERSION_HEADER
    "${CMAKE_CURRENT_BINARY_DIR}/src/app/minuet_version.h"
)
find_package(
    Qt6 ${QT_MIN_VERSION} CONFIG REQUIRED
    COMPONENTS Core
               Gui
               Qml
               Quick
               QuickControls2
               QuickEffects
               Multimedia
               Svg
)
if(BUILD_TESTING AND NOT MINUET_MOBILE_PLATFORM)
    find_package(Qt6 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS Test)
endif()
if(APPLE AND NOT (CMAKE_SYSTEM_NAME STREQUAL "iOS"))
    find_package(
        Qt6Core ${QT_MIN_VERSION} CONFIG REQUIRED
        COMPONENTS QDarwinMicrophonePermissionPlugin
    )
endif()
if(COMMAND qt_policy AND QT_KNOWN_POLICY_QTP0004)
    qt_policy(SET QTP0004 NEW)
endif()
include(ECMAddAndroidApk)

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(FLUIDSYNTH REQUIRED "fluidsynth>=2.5.3")

    find_library(
        FLUIDSYNTH_STATIC_LIBRARY
        NAMES fluidsynth
        PATHS ${FLUIDSYNTH_LIBRARY_DIRS}
        NO_DEFAULT_PATH REQUIRED
    )

    set(_minuet_fluidsynth_static_libraries ${FLUIDSYNTH_STATIC_LIBRARIES})
    list(REMOVE_ITEM _minuet_fluidsynth_static_libraries fluidsynth)

    add_library(FluidSynth::libfluidsynth STATIC IMPORTED)
    set_target_properties(
        FluidSynth::libfluidsynth
        PROPERTIES IMPORTED_LOCATION "${FLUIDSYNTH_STATIC_LIBRARY}"
                   INTERFACE_INCLUDE_DIRECTORIES "${FLUIDSYNTH_INCLUDE_DIRS}"
    )
    target_link_libraries(
        FluidSynth::libfluidsynth
        INTERFACE ${_minuet_fluidsynth_static_libraries}
    )
    target_link_options(
        FluidSynth::libfluidsynth INTERFACE ${FLUIDSYNTH_STATIC_LDFLAGS_OTHER}
    )
elseif(APPLE OR ANDROID)
    find_package(FluidSynth 2.5.3 CONFIG REQUIRED)
    if(NOT TARGET FluidSynth::libfluidsynth)
        message(
            FATAL_ERROR
                "Minuet requires the FluidSynth::libfluidsynth library target"
        )
    endif()
else()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(FLUIDSYNTH REQUIRED IMPORTED_TARGET "fluidsynth>=2.5.3")

    add_library(FluidSynth::libfluidsynth INTERFACE IMPORTED)
    target_link_libraries(
        FluidSynth::libfluidsynth INTERFACE PkgConfig::FLUIDSYNTH
    )
endif()

find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS CoreAddons Kirigami I18n)
find_package(Aubio REQUIRED)
find_package(KF6KirigamiAddons REQUIRED)
ecm_find_qmlmodule(org.kde.kirigami REQUIRED)
ecm_find_qmlmodule(org.kde.coreaddons REQUIRED)
ecm_find_qmlmodule(org.kde.kirigamiaddons.formcard REQUIRED)
ecm_find_qmlmodule(org.kde.kirigamiaddons.onboarding REQUIRED)

if(NOT MINUET_MOBILE_PLATFORM)
    find_package(
        KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS Crash DocTools IconThemes
                                                  QQC2DesktopStyle
    )
    ecm_find_qmlmodule(org.kde.desktop REQUIRED)
else()
    find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS ColorScheme)
    if(IOS)
        find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS IconThemes)
    endif()
endif()

include_directories(${minuet_SOURCE_DIR}/src/ ${minuet_BINARY_DIR}/src/)

add_subdirectory(src)
add_subdirectory(data)
ki18n_install(po)
add_dependencies(minuet pofiles)

if(ANDROID)
    add_custom_target(
        minuet_android_translations
        COMMAND ${CMAKE_COMMAND} -E remove_directory
                "${MINUET_ANDROID_PACKAGE_DIR}/assets/share/locale"
        COMMAND ${CMAKE_COMMAND} -E make_directory
                "${MINUET_ANDROID_PACKAGE_DIR}/assets/share"
        COMMAND
            ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_CURRENT_BINARY_DIR}/locale"
            "${MINUET_ANDROID_PACKAGE_DIR}/assets/share/locale"
        COMMENT "Copying Minuet translations into the Android package"
        VERBATIM
    )
    add_dependencies(minuet_android_translations pofiles)
    add_dependencies(create-apk-minuet minuet_android_translations)
endif()

if(NOT MINUET_MOBILE_PLATFORM)
    add_subdirectory(doc)
    if(KF6DocTools_FOUND)
        kdoctools_install(po)
    endif()
    install(FILES org.kde.minuet.metainfo.xml
            DESTINATION ${KDE_INSTALL_METAINFODIR}
    )
endif()

include(KDEClangFormat)
file(GLOB_RECURSE ALL_FORMAT_FILES src/*.cpp src/*.h)
kde_clang_format(${ALL_FORMAT_FILES})

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
