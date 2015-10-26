# - Try to find DrumstickAlsa
# Once done, this will define
#
#  DrumstickAlsa_FOUND - system has DrumstickAlsa
#  DrumstickAlsa_INCLUDE_DIRS - the DrumstickAlsa include directories
#  DrumstickAlsa_LIBRARIES - link these to use DrumstickAlsa

include(LibFindMacros)

libfind_pkg_check_modules(DrumstickAlsa_PKGCONF drumstick-alsa)

find_path(DrumstickAlsa_INCLUDE_DIR
  NAMES drumstick/alsaport.h
  PATHS ${DrumstickAlsa_PKGCONF_INCLUDE_DIRS}
)

find_library(DrumstickAlsa_LIBRARY
  NAMES drumstick-alsa
  PATHS ${DrumstickAlsa_PKGCONF_LIBRARY_DIRS}
)

set(DrumstickAlsa_PROCESS_INCLUDES ${DrumstickAlsa_INCLUDE_DIR})
set(DrumstickAlsa_PROCESS_LIBS ${DrumstickAlsa_LIBRARY})
libfind_process(DrumstickAlsa)
