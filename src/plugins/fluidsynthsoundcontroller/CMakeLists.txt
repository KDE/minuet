# SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
#
# SPDX-License-Identifier: GPL-2.0-or-later

set(FLUIDSYNTHSOUNDCONTROLLER_PLUGIN_SRCS fluidsynthsoundcontroller.cpp)

if(MINUET_MOBILE_PLATFORM)
    add_library(
        minuetfluidsynthsoundcontroller STATIC
        ${FLUIDSYNTHSOUNDCONTROLLER_PLUGIN_SRCS}
    )
    add_library(
        Minuet::FluidSynthSoundController ALIAS minuetfluidsynthsoundcontroller
    )
else()
    add_library(
        minuetfluidsynthsoundcontroller MODULE
        ${FLUIDSYNTHSOUNDCONTROLLER_PLUGIN_SRCS}
    )
endif()

target_link_libraries(
    minuetfluidsynthsoundcontroller Qt::Core KF6::I18n Minuet::Interfaces
    Minuet::Utils FluidSynth::libfluidsynth
)

if(APPLE AND NOT (CMAKE_SYSTEM_NAME STREQUAL "iOS"))
    get_target_property(
        _minuet_fluidsynth_is_framework FluidSynth::libfluidsynth FRAMEWORK
    )
    if(_minuet_fluidsynth_is_framework)
        get_target_property(
            _minuet_fluidsynth_location FluidSynth::libfluidsynth
            IMPORTED_LOCATION
        )
        get_target_property(
            _minuet_fluidsynth_soname FluidSynth::libfluidsynth IMPORTED_SONAME
        )
        if(NOT _minuet_fluidsynth_location OR NOT _minuet_fluidsynth_soname)
            get_target_property(
                _minuet_fluidsynth_configs FluidSynth::libfluidsynth
                IMPORTED_CONFIGURATIONS
            )
            foreach(config IN LISTS _minuet_fluidsynth_configs)
                if(NOT _minuet_fluidsynth_location)
                    get_target_property(
                        _minuet_fluidsynth_location FluidSynth::libfluidsynth
                        IMPORTED_LOCATION_${config}
                    )
                endif()
                if(NOT _minuet_fluidsynth_soname)
                    get_target_property(
                        _minuet_fluidsynth_soname FluidSynth::libfluidsynth
                        IMPORTED_SONAME_${config}
                    )
                endif()
            endforeach()
        endif()

        if(_minuet_fluidsynth_location)
            get_filename_component(
                _minuet_fluidsynth_framework_version_dir
                "${_minuet_fluidsynth_location}" DIRECTORY
            )
            get_filename_component(
                _minuet_fluidsynth_framework_versions_dir
                "${_minuet_fluidsynth_framework_version_dir}" DIRECTORY
            )
            get_filename_component(
                _minuet_fluidsynth_framework_dir
                "${_minuet_fluidsynth_framework_versions_dir}" DIRECTORY
            )
            get_filename_component(
                _minuet_fluidsynth_frameworks_dir
                "${_minuet_fluidsynth_framework_dir}" DIRECTORY
            )
            set_property(
                TARGET minuetfluidsynthsoundcontroller
                APPEND
                PROPERTY BUILD_RPATH "${_minuet_fluidsynth_frameworks_dir}"
            )
            set_property(
                TARGET minuetfluidsynthsoundcontroller
                APPEND
                PROPERTY INSTALL_RPATH "${_minuet_fluidsynth_frameworks_dir}"
            )
            set_property(
                TARGET minuetfluidsynthsoundcontroller
                APPEND
                PROPERTY INSTALL_RPATH "@loader_path/../../Frameworks"
            )
        endif()

        if(_minuet_fluidsynth_soname AND NOT _minuet_fluidsynth_soname MATCHES
                                         "^@rpath/"
        )
            add_custom_command(
                TARGET minuetfluidsynthsoundcontroller
                POST_BUILD
                COMMAND
                    ${CMAKE_INSTALL_NAME_TOOL} -change
                    "${_minuet_fluidsynth_soname}"
                    "@rpath/${_minuet_fluidsynth_soname}"
                    "$<TARGET_FILE:minuetfluidsynthsoundcontroller>"
                COMMENT "Fixing the FluidSynth framework path"
            )
        endif()
    endif()
endif()

if(MINUET_MOBILE_PLATFORM)
    install(FILES GeneralUser-v1.47.sf2
            DESTINATION ${KDE_INSTALL_DATADIR}/minuet/soundfonts
    )
elseif(APPLE)
    set(MINUET_BUNDLE_PLUGIN_INSTALL_DIR "minuet.app/Contents/PlugIns/minuet")
    set(MINUET_BUNDLE_SOUNDFONT_INSTALL_DIR
        "minuet.app/Contents/Resources/minuet/soundfonts"
    )

    if(KDE_INSTALL_BUNDLEDIR)
        set(MINUET_BUNDLE_PLUGIN_INSTALL_DIR
            "${KDE_INSTALL_BUNDLEDIR}/minuet.app/Contents/PlugIns/minuet"
        )
        string(CONCAT MINUET_BUNDLE_SOUNDFONT_INSTALL_DIR
                      "${KDE_INSTALL_BUNDLEDIR}/minuet.app/Contents/Resources/"
                      "minuet/soundfonts"
        )
    endif()

    install(TARGETS minuetfluidsynthsoundcontroller
            DESTINATION "${MINUET_BUNDLE_PLUGIN_INSTALL_DIR}"
    )

    install(FILES GeneralUser-v1.47.sf2
            DESTINATION "${MINUET_BUNDLE_SOUNDFONT_INSTALL_DIR}"
    )
else()
    install(TARGETS minuetfluidsynthsoundcontroller
            DESTINATION ${KDE_INSTALL_PLUGINDIR}/minuet/
    )

    install(FILES GeneralUser-v1.47.sf2
            DESTINATION ${KDE_INSTALL_DATADIR}/minuet/soundfonts
    )
endif()
