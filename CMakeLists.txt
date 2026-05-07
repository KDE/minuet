cmake_minimum_required(VERSION 3.16)

set(CMAKE_AUTOMOC ON)
if(${CMAKE_VERSION} VERSION_GREATER "3.10.0")
    cmake_policy(SET CMP0071 OLD)
endif()

# KDE Application Version, managed by release script
set (RELEASE_SERVICE_VERSION_MAJOR "26")
set (RELEASE_SERVICE_VERSION_MINOR "07")
set (RELEASE_SERVICE_VERSION_MICRO "70")
set (RELEASE_SERVICE_COMPACT_VERSION "${RELEASE_SERVICE_VERSION_MAJOR}${RELEASE_SERVICE_VERSION_MINOR}${RELEASE_SERVICE_VERSION_MICRO}")
set (MINUET_VERSION "0.4.0.${RELEASE_SERVICE_COMPACT_VERSION}")

project(minuet VERSION ${MINUET_VERSION})

set(QT_MIN_VERSION "6.6.2")
set(KF_MIN_VERSION "6.7.0")

find_package(ECM ${KF_MIN_VERSION} CONFIG REQUIRED)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(GenerateExportHeader)
include(ECMFindQmlModule)
include(ECMSetupVersion)
include(ECMInstallIcons)
include(ECMAddAppIcon)
include(KDEClangFormat)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(FeatureSummary)

ecm_setup_version(${MINUET_VERSION} VARIABLE_PREFIX MINUET
    VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/src/app/minuet_version.h"
)
find_package(Qt6 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    Svg
)
include(ECMAddAndroidApk)

if(ANDROID)
    find_package(FluidSynth 2.5.4 CONFIG REQUIRED)
    if(TARGET FluidSynth::libfluidsynth)
        set(MINUET_FLUIDSYNTH_TARGET FluidSynth::libfluidsynth)
    else()
        message(FATAL_ERROR "Android builds require FluidSynth::libfluidsynth")
    endif()
else()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(FLUIDSYNTH REQUIRED IMPORTED_TARGET "fluidsynth>=2.5.4")
    set(MINUET_FLUIDSYNTH_TARGET PkgConfig::FLUIDSYNTH)
endif()

find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
    Kirigami
    I18n
)
ecm_find_qmlmodule(org.kde.kirigami REQUIRED)

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
        CoreAddons
        Crash
        DocTools
        QQC2DesktopStyle
    )
    ecm_find_qmlmodule(org.kde.desktop REQUIRED)
ELSE()
    find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
        ColorScheme
    )
    ecm_find_qmlmodule(org.kde.breeze REQUIRED)
ENDIF()

include_directories(${minuet_SOURCE_DIR}/src/ ${minuet_BINARY_DIR}/src/)

add_subdirectory(src)
add_subdirectory(data)
IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    add_subdirectory(doc)
    ki18n_install(po)
    if (KF6DocTools_FOUND)
        kdoctools_install(po)
    endif()
    install(FILES org.kde.minuet.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
