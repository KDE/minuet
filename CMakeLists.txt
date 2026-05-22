cmake_minimum_required(VERSION 3.16)

set(CMAKE_AUTOMOC ON)
if(${CMAKE_VERSION} VERSION_GREATER "3.10.0")
    cmake_policy(SET CMP0071 OLD)
endif()

# KDE Application Version, managed by release script
set (RELEASE_SERVICE_VERSION_MAJOR "26")
set (RELEASE_SERVICE_VERSION_MINOR "07")
set (RELEASE_SERVICE_VERSION_MICRO "70")
set (RELEASE_SERVICE_VERSION "${RELEASE_SERVICE_VERSION_MAJOR}.${RELEASE_SERVICE_VERSION_MINOR}.${RELEASE_SERVICE_VERSION_MICRO}")
set (RELEASE_SERVICE_COMPACT_VERSION "${RELEASE_SERVICE_VERSION_MAJOR}${RELEASE_SERVICE_VERSION_MINOR}${RELEASE_SERVICE_VERSION_MICRO}")

project(minuet VERSION ${RELEASE_SERVICE_VERSION})

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

ecm_setup_version(${PROJECT_VERSION} VARIABLE_PREFIX MINUET
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
if(COMMAND qt_policy AND QT_KNOWN_POLICY_QTP0004)
    qt_policy(SET QTP0004 NEW)
endif()
include(ECMAddAndroidApk)

find_package(FluidSynth 2.5.3 CONFIG QUIET)
if(TARGET FluidSynth::libfluidsynth)
    set(MINUET_FLUIDSYNTH_TARGET FluidSynth::libfluidsynth)
else()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(FLUIDSYNTH REQUIRED IMPORTED_TARGET "fluidsynth>=2.5.3")
    set(MINUET_FLUIDSYNTH_TARGET PkgConfig::FLUIDSYNTH)
endif()

find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
    CoreAddons
    Kirigami
    I18n
)
find_package(KF6KirigamiAddons REQUIRED)
ecm_find_qmlmodule(org.kde.kirigami REQUIRED)
ecm_find_qmlmodule(org.kde.coreaddons REQUIRED)
ecm_find_qmlmodule(org.kde.kirigamiaddons.formcard REQUIRED)

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
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
