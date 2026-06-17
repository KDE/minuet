# SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
#
# SPDX-License-Identifier: GPL-2.0-or-later

set(MINUETINTERFACES_LIB_SRCS iplugin.cpp imicrophoneinputcontroller.cpp
                              isoundcontroller.cpp
)

if(MINUET_MOBILE_PLATFORM)
    add_library(minuetinterfaces STATIC ${MINUETINTERFACES_LIB_SRCS})
else()
    add_library(minuetinterfaces ${MINUETINTERFACES_LIB_SRCS})
endif()
add_library(Minuet::Interfaces ALIAS minuetinterfaces)

set_target_properties(minuetinterfaces PROPERTIES VERSION 0.3.0)

generate_export_header(
    minuetinterfaces EXPORT_FILE_NAME minuetinterfacesexport.h
)

if(MINUET_MOBILE_PLATFORM)
    target_compile_definitions(
        minuetinterfaces PUBLIC MINUETINTERFACES_STATIC_DEFINE
    )
endif()

target_link_libraries(minuetinterfaces Qt::Core Qt::Quick)

qt_extract_metatypes(minuetinterfaces)

if(NOT MINUET_MOBILE_PLATFORM)
    install(
        FILES ${CMAKE_CURRENT_BINARY_DIR}/minuetinterfacesexport.h
        DESTINATION ${KDE_INSTALL_INCLUDEDIR}/minuet/interfaces
        COMPONENT Devel
    )

    install(
        TARGETS minuetinterfaces
        EXPORT MinuetTargets
        ${KDE_INSTALL_TARGETS_DEFAULT_ARGS}
    )

    install(
        FILES iplugin.h imicrophoneinputcontroller.h isoundcontroller.h
        DESTINATION ${KDE_INSTALL_INCLUDEDIR}/minuet/interfaces
        COMPONENT Devel
    )
endif()
