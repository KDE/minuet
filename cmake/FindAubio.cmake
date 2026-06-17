# SPDX-License-Identifier: BSD-2-Clause

find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(PC_AUBIO QUIET aubio)
endif()

find_path(
    AUBIO_INCLUDE_DIR
    NAMES aubio/aubio.h
    HINTS ${PC_AUBIO_INCLUDEDIR} ${PC_AUBIO_INCLUDE_DIRS}
)

find_library(
    AUBIO_LIBRARY
    NAMES aubio
    HINTS ${PC_AUBIO_LIBDIR} ${PC_AUBIO_LIBRARY_DIRS}
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
    Aubio
    REQUIRED_VARS AUBIO_INCLUDE_DIR AUBIO_LIBRARY
    VERSION_VAR PC_AUBIO_VERSION
)

if(Aubio_FOUND AND NOT TARGET Aubio::aubio)
    add_library(Aubio::aubio UNKNOWN IMPORTED)
    set_target_properties(
        Aubio::aubio
        PROPERTIES IMPORTED_LOCATION "${AUBIO_LIBRARY}"
                   INTERFACE_INCLUDE_DIRECTORIES "${AUBIO_INCLUDE_DIR}"
    )
    if(PC_AUBIO_CFLAGS_OTHER)
        set_property(
            TARGET Aubio::aubio PROPERTY INTERFACE_COMPILE_OPTIONS
                                         "${PC_AUBIO_CFLAGS_OTHER}"
        )
    endif()
endif()
