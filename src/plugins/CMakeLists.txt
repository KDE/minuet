find_package(PkgConfig REQUIRED)
if(PKG_CONFIG_FOUND)
    message(STATUS "Program pkg-config found (${PKG_CONFIG_EXECUTABLE})")
else()
    message(FATAL_ERROR "Program pkg-config not found")
endif()

pkg_check_modules(FLUIDSYNTH REQUIRED fluidsynth>=1.1.6)

if(NOT FLUIDSYNTH_FOUND)
    message(WARNING "Please install fluidsynth libraries and headers (package fluidsynth) if you want to build fluidsynth soundbackend")
endif()

if(FLUIDSYNTH_FOUND)
    link_directories(${FLUIDSYNTH_LIBDIR})
    include_directories(${FLUIDSYNTH_INCLUDEDIR})
endif()

if(FLUIDSYNTH_FOUND)
    add_subdirectory(fluidsynthsoundbackend)
endif()
