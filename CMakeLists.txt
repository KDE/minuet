cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(minuet)

set(CMAKE_AUTOMOC ON)
cmake_policy(SET CMP0071 OLD)

# KDE Application Version, managed by release script
set (KDE_APPLICATIONS_VERSION_MAJOR "18")
set (KDE_APPLICATIONS_VERSION_MINOR "11")
set (KDE_APPLICATIONS_VERSION_MICRO "70")
#set (KDE_APPLICATIONS_VERSION "${KDE_APPLICATIONS_VERSION_MAJOR}.${KDE_APPLICATIONS_VERSION_MINOR}.${KDE_APPLICATIONS_VERSION_MICRO}")
set (KDE_APPLICATIONS_VERSION "0.4.0")

set(ECM_MIN_VERSION "5.15.0")
set(QT_MIN_VERSION "5.7.0")

find_package(ECM ${ECM_MIN_VERSION} CONFIG REQUIRED)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR} ${minuet_SOURCE_DIR}/cmake)

include(GenerateExportHeader)
include(ECMSetupVersion)
include(ECMInstallIcons)
include(ECMAddAppIcon)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(FeatureSummary)

ecm_setup_version(${KDE_APPLICATIONS_VERSION} VARIABLE_PREFIX MINUET
    VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/src/app/minuet_version.h"
)

find_package(Qt5 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    Svg
)

find_package(Qt5 CONFIG QUIET OPTIONAL_COMPONENTS QuickCompiler)

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    find_package(KF5 ${KF5_MIN_VERSION} REQUIRED COMPONENTS
        CoreAddons
        I18n
        Crash
        DocTools
    )
    find_package(FluidSynth 1.1.6 REQUIRED)
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")

feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)

include_directories(${minuet_SOURCE_DIR}/src/ ${minuet_BINARY_DIR}/src/)

add_subdirectory(src)
add_subdirectory(data)
IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    add_subdirectory(doc)
    install(FILES org.kde.minuet.appdata.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
