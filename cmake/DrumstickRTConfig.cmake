# - Try to find DrumstickRT
# Once done, this will define
#
#  DrumstickRT_FOUND - system has DrumstickRT
#  DrumstickRT_INCLUDE_DIRS - the DrumstickRT include directories
#  DrumstickRT_LIBRARIES - link these to use DrumstickRT

include(LibFindMacros)

libfind_pkg_check_modules(DrumstickRT_PKGCONF drumstick-rt)

find_path(DrumstickRT_INCLUDE_DIR
  NAMES drumstick/rtmidiinput.h
  PATHS ${DrumstickRT_PKGCONF_INCLUDE_DIRS}
)

find_library(DrumstickRT_LIBRARY
  NAMES drumstick-rt
  PATHS ${DrumstickRT_PKGCONF_LIBRARY_DIRS}
)

set(DrumstickRT_PROCESS_INCLUDES ${DrumstickRT_INCLUDE_DIR})
set(DrumstickRT_PROCESS_LIBS ${DrumstickRT_LIBRARY})
libfind_process(DrumstickRT)
