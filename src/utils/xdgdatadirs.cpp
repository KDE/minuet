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
    const auto paths = xdgDataDirsEnv.splitRef(QLatin1Char(':'), Qt::SkipEmptyParts);
    // Normalize paths, skip relative paths
    for (const auto &path : paths) {
        if (!QDir::isAbsolutePath(path.toString()) || !QDir(path.toString()).exists()) {
            continue;
        }
        results.append(path.toString());
    }

    return results;
}
