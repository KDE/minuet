set(minuetutils_LIB_SRCS
    xdgdatadirs.cpp
)

add_library(minuetutils
    STATIC
    ${minuetutils_LIB_SRCS}
)
add_library(Minuet::Utils ALIAS minuetutils)

target_link_libraries(minuetutils
    PRIVATE
    Qt5::Core
)
