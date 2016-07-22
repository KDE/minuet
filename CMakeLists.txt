cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(minuet)

# KDE Application Version, managed by release script
set (KDE_APPLICATIONS_VERSION_MAJOR "16")
set (KDE_APPLICATIONS_VERSION_MINOR "07")
set (KDE_APPLICATIONS_VERSION_MICRO "80")
#set (KDE_APPLICATIONS_VERSION "${KDE_APPLICATIONS_VERSION_MAJOR}.${KDE_APPLICATIONS_VERSION_MINOR}.${KDE_APPLICATIONS_VERSION_MICRO}")
set (KDE_APPLICATIONS_VERSION "0.1.80")

set(ECM_MIN_VERSION "5.15.0")
set(QT_MIN_VERSION "5.7.0")
set(KF5_MIN_VERSION "5.15.0")

find_package(ECM ${ECM_MIN_VERSION} CONFIG REQUIRED)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR})

include(ECMSetupVersion)
include(ECMInstallIcons)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(GenerateExportHeader)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(FeatureSummary)

ecm_setup_version(${KDE_APPLICATIONS_VERSION} VARIABLE_PREFIX MINUET
                  VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/src/app/minuet_version.h"
)

find_package(Qt5 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS
    Core
    Widgets
    Quick
#    Gui
)

find_package(KF5 ${KF5_MIN_VERSION} REQUIRED COMPONENTS
    DocTools
    XmlGui
    I18n
    CoreAddons
    Completion
    WidgetsAddons
    KIO
    Crash
    TextEditor
)

feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)

include_directories(${minuet_SOURCE_DIR}/src/ ${minuet_BINARY_DIR}/src)

add_subdirectory(doc)
add_subdirectory(src)
add_subdirectory(icons)
add_subdirectory(data)

install(FILES org.kde.minuet.appdata.xml DESTINATION ${SHARE_INSTALL_PREFIX}/appdata/)

install(EXPORT MinuetTargets
    DESTINATION "${KDE_INSTALL_CMAKEPACKAGEDIR}/Minuet"
    NAMESPACE Minuet::
    FILE MinuetTargets.cmake)
