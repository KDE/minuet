if (CMAKE_VERSION VERSION_LESS 2.8.9)
    message(FATAL_ERROR "Drumstick requires at least CMake version 2.8.9")
endif()

if (NOT Drumstick_FIND_COMPONENTS)
    set(Drumstick_NOT_FOUND_MESSAGE "The Drumstick package requires at least one component")
    set(Drumstick_FOUND False)
    return()
endif()

set(_DRUMSTICK_FIND_PARTS_REQUIRED)
if (Drumstick_FIND_REQUIRED)
    set(_DRUMSTICK_FIND_PARTS_REQUIRED REQUIRED)
endif()
set(_DRUMSTICK_FIND_PARTS_QUIET)
if (Drumstick_FIND_QUIETLY)
    set(_DRUMSTICK_FIND_PARTS_QUIET QUIET)
endif()

get_filename_component(_drumstick_install_prefix "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)

set(_DRUMSTICK_NOTFOUND_MESSAGE)

foreach(module ${Drumstick_FIND_COMPONENTS})
    find_package(Drumstick${module}
        ${_DRUMSTICK_FIND_PARTS_QUIET}
        ${_DRUMSTICK_FIND_PARTS_REQUIRED}
        PATHS "${_drumstick_install_prefix}" NO_DEFAULT_PATH
    )
    if (NOT Drumstick${module}_FOUND)
        if (Drumstick_FIND_REQUIRED_${module})
            set(_DRUMSTICK_NOTFOUND_MESSAGE "${_DRUMSTICK_NOTFOUND_MESSAGE}Failed to find Drumstick component \"${module}\" config file at \"${_drumstick_install_prefix}/Drumstick${module}/Drumstick${module}Config.cmake\"\n")
        elseif(NOT Drumstick_FIND_QUIETLY)
            message(WARNING "Failed to find Drumstick component \"${module}\" config file at \"${_drumstick_install_prefix}/Drumstick${module}/Drumstick${module}Config.cmake\"")
        endif()
    endif()
endforeach()

if (_DRUMSTICK_NOTFOUND_MESSAGE)
    set(Drumstick_NOT_FOUND_MESSAGE "${_DRUMSTICK_NOTFOUND_MESSAGE}")
    set(Drumstick_FOUND False)
else()
    set(Drumstick_FOUND True)
endif()
