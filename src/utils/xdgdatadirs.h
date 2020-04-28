#ifndef MINUET_UTILS_XDGDATADIRS
#define MINUET_UTILS_XDGDATADIRS

#include <QString>

namespace Utils
{
/**
 * @brief Get valid paths from XDG_DATA_DIRS environment variable
 * Qt does not check XDG_DATA_DIRS for MACOS but KDE prefix.sh script sets it.
 * If AppDataLocation fail, we should give a shot and check XDG env variable
 *
 * @return QStringList
 */
QStringList getXdgDataDirs();

}

#endif
