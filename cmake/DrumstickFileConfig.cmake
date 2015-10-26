# - Try to find DrumstickFile
# Once done, this will define
#
#  DrumstickFile_FOUND - system has DrumstickFile
#  DrumstickFile_INCLUDE_DIRS - the DrumstickFile include directories
#  DrumstickFile_LIBRARIES - link these to use DrumstickFile

include(LibFindMacros)

libfind_pkg_check_modules(DrumstickFile_PKGCONF drumstick-file)

find_path(DrumstickFile_INCLUDE_DIR
  NAMES drumstick/qsmf.h
  PATHS ${DrumstickFile_PKGCONF_INCLUDE_DIRS}
)

find_library(DrumstickFile_LIBRARY
  NAMES drumstick-file
  PATHS ${DrumstickFile_PKGCONF_LIBRARY_DIRS}
)

set(DrumstickFile_PROCESS_INCLUDES ${DrumstickFile_INCLUDE_DIR})
set(DrumstickFile_PROCESS_LIBS ${DrumstickFile_LIBRARY})
libfind_process(DrumstickFile)
