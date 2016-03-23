cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(minuet)

# KDE Application Version, managed by release script
set (KDE_APPLICATIONS_VERSION_MAJOR "16")
set (KDE_APPLICATIONS_VERSION_MINOR "07")
set (KDE_APPLICATIONS_VERSION_MICRO "70")
#set (KDE_APPLICATIONS_VERSION "${KDE_APPLICATIONS_VERSION_MAJOR}.${KDE_APPLICATIONS_VERSION_MINOR}.${KDE_APPLICATIONS_VERSION_MICRO}")
set (KDE_APPLICATIONS_VERSION "1.0.70")

set(ECM_MIN_VERSION "5.15.0")
set(QT_MIN_VERSION "5.4.0")
set(KF5_MIN_VERSION "5.15.0")

find_package(ECM ${ECM_MIN_VERSION} CONFIG REQUIRED)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR})

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
    I18n
    XmlGui
    KIO
    Crash
    DocTools
)

find_package(PkgConfig REQUIRED)
if(PKG_CONFIG_FOUND)
    message(STATUS "Program pkg-config found (${PKG_CONFIG_EXECUTABLE})")
else()
    message(FATAL_ERROR "Program pkg-config not found")
endif()

pkg_check_modules(ALSA REQUIRED alsa>=1.0.0)
if(ALSA_FOUND)
    link_directories(${ALSA_LIBDIR})
    include_directories(${ALSA_INCLUDEDIR})
    #link_libraries(${ALSA_LIBRARIES})
else()
    message(FATAL_ERROR "Please install ALSA library and headers (libasound2)")
endif()

pkg_check_modules(DRUMSTICK_ALSA REQUIRED drumstick-alsa>=1.0.1)
if(DRUMSTICK_ALSA_FOUND)
    link_directories(${DRUMSTICK_ALSA_LIBDIR})
    include_directories(${DRUMSTICK_ALSA_INCLUDEDIR})
    #link_libraries(${DRUMSTICK_ALSA_LIBRARIES})
else()
    message(FATAL_ERROR "Please install drumstick libraries and headers (package drumstick-devel)")
endif()

pkg_check_modules(DRUMSTICK_FILE REQUIRED drumstick-file>=1.0.1)
if(DRUMSTICK_FILE_FOUND)
    link_directories(${DRUMSTICK_FILE_LIBDIR})
    include_directories(${DRUMSTICK_FILE_INCLUDEDIR})
    #link_libraries(${DRUMSTICK_FILE_LIBRARIES})
else()
    message(FATAL_ERROR "Please install drumstick libraries and headers (package drumstick-devel)")
endif()

feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)

add_subdirectory(doc)
add_subdirectory(src)
add_subdirectory(icons)
add_subdirectory(exercises)

install(FILES org.kde.minuet.appdata.xml DESTINATION ${SHARE_INSTALL_PREFIX}/appdata/)
