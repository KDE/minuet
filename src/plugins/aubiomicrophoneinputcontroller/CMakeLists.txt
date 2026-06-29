# SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
#
# SPDX-License-Identifier: GPL-2.0-or-later

set(AUBIOMICROPHONEINPUTCONTROLLER_PLUGIN_SRCS
    aubiomicrophoneinputcontroller.cpp
)

if(MINUET_MOBILE_PLATFORM)
    add_library(
        minuetaubiomicrophoneinputcontroller STATIC
        ${AUBIOMICROPHONEINPUTCONTROLLER_PLUGIN_SRCS}
    )
    add_library(
        Minuet::AubioMicrophoneInputController ALIAS
        minuetaubiomicrophoneinputcontroller
    )
else()
    add_library(
        minuetaubiomicrophoneinputcontroller MODULE
        ${AUBIOMICROPHONEINPUTCONTROLLER_PLUGIN_SRCS}
    )
endif()

target_link_libraries(
    minuetaubiomicrophoneinputcontroller Qt::Core Qt::Multimedia
    Minuet::Interfaces Aubio::aubio
)

if(NOT MINUET_MOBILE_PLATFORM)
    install(TARGETS minuetaubiomicrophoneinputcontroller
            DESTINATION ${KDE_INSTALL_PLUGINDIR}/minuet/
    )
endif()
