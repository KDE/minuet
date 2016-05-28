#cmake_minimum_required(VERSION 3.3.2 FATAL_ERROR)#Currently I am using this version

project(minuetandroid)

#requirements

#find_package(ECM 1.7.0 REQUIRED NO_MODULE)
#set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
#set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules" ${CMAKE_MODULE_PATH})

#find_package(Qt5 ${QT_REQUIRED_VERSION} REQUIRED NO_MODULE COMPONENTS Qml Quick)

#find_package(KF5 REQUIRED COMPONENTS
#   Config
#  WidgetsAddons
#  NewStuff
#  I18n
#  XmlGui
#  KIO	
#  Crash
#  DocTools
#) 
#feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)

add_subdirectory(src)
