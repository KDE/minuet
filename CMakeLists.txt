cmake_minimum_required(VERSION 3.5 FATAL_ERROR)

set(CMAKE_AUTOMOC ON)
if(${CMAKE_VERSION} VERSION_GREATER "3.10.0")
    cmake_policy(SET CMP0071 OLD)
endif()

# KDE Application Version, managed by release script
set (RELEASE_SERVICE_VERSION_MAJOR "25")
set (RELEASE_SERVICE_VERSION_MINOR "04")
set (RELEASE_SERVICE_VERSION_MICRO "2")
set (RELEASE_SERVICE_COMPACT_VERSION "${RELEASE_SERVICE_VERSION_MAJOR}${RELEASE_SERVICE_VERSION_MINOR}${RELEASE_SERVICE_VERSION_MICRO}")
set (MINUET_VERSION "0.4.0.${RELEASE_SERVICE_COMPACT_VERSION}")

project(minuet VERSION ${MINUET_VERSION})

set(KF5_MIN_VERSION "5.90.0")
set(QT_MIN_VERSION "5.15.2")

find_package(ECM ${KF5_MIN_VERSION} CONFIG REQUIRED)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH}  ${minuet_SOURCE_DIR}/cmake)

include(GenerateExportHeader)
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
if (QT_MAJOR_VERSION STREQUAL "6")
    set(QT_REQUIRED_VERSION "6.4.0")
    set(KF_MIN_VERSION "5.240.0")
    set(KF_MAJOR_VERSION "6")
else()
    set(KF_MAJOR_VERSION "5")
endif()
find_package(Qt${QT_MAJOR_VERSION} ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    Svg
)

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    find_package(KF${KF_MAJOR_VERSION} ${KF5_MIN_VERSION} REQUIRED COMPONENTS
        CoreAddons
        I18n
        Crash
        DocTools
    )
    find_package(FluidSynth 1.1.6 REQUIRED)
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")

include_directories(${minuet_SOURCE_DIR}/src/ ${minuet_BINARY_DIR}/src/)

add_subdirectory(src)
add_subdirectory(data)
IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    add_subdirectory(doc)
    ki18n_install(po)
    if (KF${KF_MAJOR_VERSION}DocTools_FOUND)
        kdoctools_install(po)
    endif()
    install(FILES org.kde.minuet.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
