project(minuet)

cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)
set(QT_MIN_VERSION "5.3.0")

find_package(ECM 1.0.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(ECMInstallIcons)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings)
include(FeatureSummary)

find_package(Qt5 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS Core Gui Widgets Quick)

find_package(KF5 REQUIRED COMPONENTS
    CoreAddons
    I18n
    XmlGui
    ConfigWidgets
    DocTools
    KIO
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
