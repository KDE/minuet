set(CSOUND_LIBS_DIR $ENV{CSOUND_ANDROID_ROOT}/CsoundForAndroid/CsoundAndroid/src/main/jniLibs/armeabi-v7a)

find_library(CSOUND_ANDROID NAMES libcsoundandroid.so HINTS ${CSOUND_LIBS_DIR} CMAKE_FIND_ROOT_PATH_BOTH NO_DEFAULT_PATH)
find_library(CSOUND_SHARED NAMES libc++_shared.so HINTS ${CSOUND_LIBS_DIR} CMAKE_FIND_ROOT_PATH_BOTH NO_DEFAULT_PATH)
find_library(CSOUND_SND NAMES libsndfile.so HINTS ${CSOUND_LIBS_DIR} CMAKE_FIND_ROOT_PATH_BOTH NO_DEFAULT_PATH)

set(CSOUND_LIBS ${CSOUND_ANDROID} ${CSOUND_SHARED} ${CSOUND_SND})

include_directories($ENV{CSOUND_ROOT}/include)
include_directories($ENV{CSOUND_ROOT}/android/CsoundAndroid/jni/)

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

target_link_libraries(minuetcsoundsoundcontroller ${CSOUND_LIBS})

IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    install(TARGETS minuetcsoundsoundcontroller DESTINATION ${PLUGIN_INSTALL_DIR}/minuet/)
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
