IF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
    find_package(PkgConfig REQUIRED)
    if(PKG_CONFIG_FOUND)
        message(STATUS "Program pkg-config found (${PKG_CONFIG_EXECUTABLE})")
    else()
        message(FATAL_ERROR "Program pkg-config not found")
    endif()

    pkg_check_modules(PC_FLUIDSYNTH REQUIRED fluidsynth>=1.1.6)

    if(NOT PC_FLUIDSYNTH_FOUND)
        message(WARNING "Please install fluidsynth libraries and headers (package fluidsynth) if you want to build fluidsynth soundcontroller")
    endif()

    if(PC_FLUIDSYNTH_FOUND)
        find_library(FLUIDSYNTH_LIBRARIES
          NAMES fluidsynth
          HINTS ${PC_FLUIDSYNTH_LIBDIR}
        )
        find_path(FLUIDSYNTH_INCLUDE_DIRS
          NAMES fluidsynth.h
          HINTS ${PC_FLUIDSYNTH_INCLUDEDIR}
        )

        add_subdirectory(fluidsynthsoundcontroller)
    endif()
ENDIF(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Android")
IF(${CMAKE_SYSTEM_NAME} MATCHES "Android")
    add_subdirectory(csoundsoundcontroller)
ENDIF(${CMAKE_SYSTEM_NAME} MATCHES "Android")
