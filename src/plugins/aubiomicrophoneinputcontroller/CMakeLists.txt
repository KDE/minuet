# SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
#
# SPDX-License-Identifier: GPL-2.0-or-later

set(AUBIOMICROPHONEINPUTCONTROLLER_PLUGIN_SRCS
    aubioanalysisworker.cpp aubiomicrophoneinputcontroller.cpp
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

if(BUILD_TESTING AND NOT MINUET_MOBILE_PLATFORM)
    add_executable(
        aubioanalysisworkertest autotests/aubioanalysisworkertest.cpp
                                aubioanalysisworker.cpp
    )
    target_link_libraries(
        aubioanalysisworkertest Qt::Core Qt::Multimedia Qt::Test Aubio::aubio
    )
    add_test(NAME aubioanalysisworkertest COMMAND aubioanalysisworkertest)
endif()

if(MINUET_MOBILE_PLATFORM)

elseif(APPLE)
    set(MINUET_BUNDLE_PLUGIN_INSTALL_DIR "minuet.app/Contents/PlugIns/minuet")
    if(KDE_INSTALL_BUNDLEDIR)
        set(MINUET_BUNDLE_PLUGIN_INSTALL_DIR
            "${KDE_INSTALL_BUNDLEDIR}/minuet.app/Contents/PlugIns/minuet"
        )
    endif()

    install(TARGETS minuetaubiomicrophoneinputcontroller
            DESTINATION "${MINUET_BUNDLE_PLUGIN_INSTALL_DIR}"
    )
else()
    install(TARGETS minuetaubiomicrophoneinputcontroller
            DESTINATION ${KDE_INSTALL_PLUGINDIR}/minuet/
    )
endif()
