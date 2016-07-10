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
else()
    message(FATAL_ERROR "Please install ALSA library and headers (libasound2)")
endif()

pkg_check_modules(DRUMSTICK_ALSA drumstick-alsa>=1.0.1)
pkg_check_modules(DRUMSTICK_FILE drumstick-file>=1.0.1)

if(DRUMSTICK_ALSA_FOUND)
    link_directories(${DRUMSTICK_ALSA_LIBDIR})
    include_directories(${DRUMSTICK_ALSA_INCLUDEDIR})
endif()

if(DRUMSTICK_FILE_FOUND)
    link_directories(${DRUMSTICK_FILE_LIBDIR})
    include_directories(${DRUMSTICK_FILE_INCLUDEDIR})
endif()

if(NOT DRUMSTICK_ALSA_FOUND OR NOT DRUMSTICK_FILE_FOUND)
    message(WARNING "Please install drumstick libraries and headers (package drumstick-devel) if you want to build drumstick soundbackend")
endif()

if(ALSA_FOUND AND DRUMSTICK_ALSA_FOUND AND DRUMSTICK_FILE_FOUND)
    add_subdirectory(drumsticksoundbackend)
endif()

pkg_check_modules(FLUIDSYNTH fluidsynth>=1.1.6)

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
