# SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
#
# SPDX-License-Identifier: GPL-2.0-or-later

set(MINUETUTILS_LIB_SRCS xdgdatadirs.cpp)

add_library(minuetutils STATIC ${MINUETUTILS_LIB_SRCS})
set_target_properties(minuetutils PROPERTIES AUTOMOC OFF)
add_library(Minuet::Utils ALIAS minuetutils)

target_link_libraries(minuetutils PRIVATE Qt::Core)
