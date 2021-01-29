include(ExternalProject)

ExternalProject_Add(Csound
    GIT_REPOSITORY    https://github.com/csound/csound.git
    GIT_TAG           6.11.0
    CONFIGURE_COMMAND "${CMAKE_SOURCE_DIR}/configure-csound-android.sh"
    BUILD_COMMAND "${CMAKE_SOURCE_DIR}/build-csound-android.sh"
    INSTALL_COMMAND   ""
)

set(CSOUND_ANDROID_LIBS_DIR ${CMAKE_CURRENT_BINARY_DIR}/Csound-prefix/src/Csound/Android/CsoundAndroid/libs/arm64-v8a/)
set(CSOUND_ROOT ${CMAKE_CURRENT_BINARY_DIR}/Csound-prefix/src/Csound/)

set(CSOUND_ANDROID ${CSOUND_ANDROID_LIBS_DIR}/libcsoundandroid.so)
set(CSOUND_SHARED ${CSOUND_ANDROID_LIBS_DIR}/libc++_shared.so)
set(CSOUND_SND ${CSOUND_ANDROID_LIBS_DIR}/libsndfile.so)

set(CSOUND_LIBS ${CSOUND_ANDROID} ${CSOUND_SHARED} ${CSOUND_SND})

include_directories(${CMAKE_CURRENT_BINARY_DIR}/Csound-prefix/src/Csound/include)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/Csound-prefix/src/Csound/Android/CsoundAndroid/jni)

set(csoundsoundcontroller_PLUGIN_SRCS
    csengine.cpp
    csoundsoundcontroller.cpp
)

add_library(minuetcsoundsoundcontroller ${csoundsoundcontroller_PLUGIN_SRCS})
add_library(Minuet::CsoundSoundController ALIAS minuetcsoundsoundcontroller)

target_link_libraries(minuetcsoundsoundcontroller
    Qt5::Core
    Minuet::Interfaces
    ${CSOUND_LIBS}
)

add_dependencies(minuetcsoundsoundcontroller Csound)

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    install(TARGETS minuetcsoundsoundcontroller DESTINATION ${KDE_INSTALL_PLUGINDIR}/minuet/)
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
