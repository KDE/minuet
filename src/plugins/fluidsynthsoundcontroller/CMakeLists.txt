# SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
#
# SPDX-License-Identifier: GPL-2.0-or-later

set(fluidsynthsoundcontroller_PLUGIN_SRCS
    fluidsynthsoundcontroller.cpp
)

if(ANDROID)
    add_library(minuetfluidsynthsoundcontroller STATIC ${fluidsynthsoundcontroller_PLUGIN_SRCS})
    add_library(Minuet::FluidSynthSoundController ALIAS minuetfluidsynthsoundcontroller)
else()
    add_library(minuetfluidsynthsoundcontroller MODULE ${fluidsynthsoundcontroller_PLUGIN_SRCS})
endif()

target_link_libraries(minuetfluidsynthsoundcontroller
    Qt::Core
    KF6::I18n
    Minuet::Interfaces
    Minuet::Utils
    FluidSynth::libfluidsynth
)

if(ANDROID)
    install(FILES GeneralUser-v1.47.sf2 DESTINATION ${KDE_INSTALL_DATADIR}/minuet/soundfonts)
else()
    install(TARGETS minuetfluidsynthsoundcontroller DESTINATION ${KDE_INSTALL_PLUGINDIR}/minuet/)
    install(FILES GeneralUser-v1.47.sf2 DESTINATION ${KDE_INSTALL_DATADIR}/minuet/soundfonts)
endif()
