cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(minuet)

# KDE Application Version, managed by release script
set (KDE_APPLICATIONS_VERSION_MAJOR "16")
set (KDE_APPLICATIONS_VERSION_MINOR "04")
set (KDE_APPLICATIONS_VERSION_MICRO "0")
set (KDE_APPLICATIONS_VERSION "${KDE_APPLICATIONS_VERSION_MAJOR}.${KDE_APPLICATIONS_VERSION_MINOR}.${KDE_APPLICATIONS_VERSION_MICRO}")

set(ECM_MIN_VERSION "5.18.0")
set(QT_MIN_VERSION "5.5.0")
set(KF5_MIN_VERSION "5.18.0")

find_package(ECM ${ECM_MIN_VERSION} CONFIG REQUIRED)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(ECMSetupVersion)
include(ECMInstallIcons)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings)
include(FeatureSummary)

ecm_setup_version(${KDE_APPLICATIONS_VERSION} VARIABLE_PREFIX MINUET
                  VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/src/minuet_version.h"
)

find_package(Qt5 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS Core Gui Widgets Quick)

find_package(KF5 ${KF5_MIN_VERSION} REQUIRED COMPONENTS
    CoreAddons
    I18n
    XmlGui
    ConfigWidgets
    DocTools
    KIO
    Crash
)

find_package(Drumstick REQUIRED COMPONENTS Alsa File)

MESSAGE(STATUS "Drumstick_FOUND: " ${Drumstick_FOUND} ${DRUMSTICK_LIBRARIES})
MESSAGE(STATUS "DrumstickFile_FOUND: " ${DrumstickFile_FOUND} ${DRUMSTICK_LIBRARIES})

feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)

add_subdirectory(doc)
add_subdirectory(src)
add_subdirectory(icons)
add_subdirectory(exercises)

install(FILES org.kde.minuet.appdata.xml DESTINATION ${SHARE_INSTALL_PREFIX}/appdata/)
