#include <QDir>
#include <QFile>

#include "xdgdatadirs.h"

using namespace Utils;

QStringList Utils::getXdgDataDirs()
{
    const QString xdgDataDirsEnv = QFile::decodeName(qgetenv("XDG_DATA_DIRS"));
    if (xdgDataDirsEnv.isEmpty()) {
        return {};
    }

    QStringList results;
    const auto paths = xdgDataDirsEnv.split(QLatin1Char(':'), Qt::SkipEmptyParts);
    // Normalize paths, skip relative paths
    for (const auto &path : paths) {
        if (!QDir::isAbsolutePath(path) || !QDir(path).exists()) {
            continue;
        }
        results.append(path);
    }

    return results;
}
