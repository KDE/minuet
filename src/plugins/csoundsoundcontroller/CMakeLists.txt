include(ExternalProject)

ExternalProject_Add(CsoundForAndroid
    URL               https://github.com/csound/csound/releases/download/6.11.0/Csound6.11.0-Android.zip
    URL_HASH          MD5=f2aeb39b5f227ae19c92f31b23d56342
    CONFIGURE_COMMAND ""
    BUILD_COMMAND     ""
    INSTALL_COMMAND   ""
)

ExternalProject_Add(Csound
    GIT_REPOSITORY    https://github.com/csound/csound.git
    GIT_TAG           6.11.0
    CONFIGURE_COMMAND ""
    BUILD_COMMAND     ""
    INSTALL_COMMAND   ""
)

set(CSOUND_ANDROID_LIBS_DIR ${CMAKE_CURRENT_BINARY_DIR}/CsoundForAndroid-prefix/src/CsoundForAndroid/CsoundForAndroid/CsoundAndroid/src/main/jniLibs/armeabi-v7a)
set(CSOUND_ROOT ${CMAKE_CURRENT_BINARY_DIR}/Csound-prefix/src/Csound/)

set(CSOUND_ANDROID ${CSOUND_ANDROID_LIBS_DIR}/libcsoundandroid.so)
set(CSOUND_SHARED ${CSOUND_ANDROID_LIBS_DIR}/libc++_shared.so)
set(CSOUND_SND ${CSOUND_ANDROID_LIBS_DIR}/libsndfile.so)

set(CSOUND_LIBS ${CSOUND_ANDROID} ${CSOUND_SHARED} ${CSOUND_SND})

include_directories(${CSOUND_ROOT}/include)
include_directories(${CSOUND_ROOT}/Android/CsoundAndroid/jni/)

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

add_dependencies(minuetcsoundsoundcontroller CsoundForAndroid Csound)

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    install(TARGETS minuetcsoundsoundcontroller DESTINATION ${PLUGIN_INSTALL_DIR}/minuet/)
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
