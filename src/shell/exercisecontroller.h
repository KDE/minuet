/****************************************************************************
**
** Copyright (C) 2016 by Sandro S. Andrade <sandroandrade@kde.org>
**
** This program is free software; you can redistribute it and/or
** modify it under the terms of the GNU General Public License as
** published by the Free Software Foundation; either version 2 of
** the License or (at your option) version 3 or any later version
** accepted by the membership of KDE e.V. (or its successor approved
** by the membership of KDE e.V.), which shall act as a proxy
** defined in Section 14 of version 3 of the license.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
**
****************************************************************************/

#ifndef MINUET_EXERCISECONTROLLER_H
#define MINUET_EXERCISECONTROLLER_H

#include <interfaces/iexercisecontroller.h>

#include <QJsonArray>
#include <QJsonObject>
#include <QStringList>

#include "minuetshellexport.h"

class MidiSequencer;

namespace Minuet
{
    
class MINUETSHELL_EXPORT ExerciseController : public IExerciseController
{
    Q_OBJECT
    Q_ENUMS(PlayMode)

public:
    explicit ExerciseController(MidiSequencer *midiSequencer = 0);
    virtual ~ExerciseController();
    
    bool initialize();

    enum PlayMode {
        ScalePlayMode = 0,
        ChordPlayMode,
        RhythmPlayMode
    };

    Q_INVOKABLE void setExerciseOptions(QJsonArray exerciseOptions);
    Q_INVOKABLE void setMinRootNote(unsigned int minRootNote);
    Q_INVOKABLE void setMaxRootNote(unsigned int maxRootNote);
    Q_INVOKABLE void setPlayMode(PlayMode playMode);
    Q_INVOKABLE void setAnswerLength(unsigned int answerLength);
    Q_INVOKABLE QStringList randomlyChooseExercises();
    Q_INVOKABLE unsigned int chosenRootNote();
    Q_INVOKABLE void playChoosenExercise();

    QString errorString() const;
    QJsonObject exercises() const;
    
private:
    bool mergeJsonFiles(const QString directoryName, QJsonObject &targetObject, bool applyDefinitionsFlag = false, QString commonKey = "", QString mergeKey = "");
    QJsonArray applyDefinitions(QJsonArray exercises, QJsonArray definitions);
    enum DefinitionFilteringMode {
        AndFiltering = 0,
        OrFiltering
    };
    void filterDefinitions(QJsonArray &definitions, QJsonObject &exerciseObject, const QString &filterTagsKey, DefinitionFilteringMode definitionFilteringMode);
    QJsonArray mergeJsonArrays(QJsonArray oldFile, QJsonArray newFile, QString commonKey = "", QString mergeKey = "");

    MidiSequencer *m_midiSequencer;
    QJsonObject m_exercises;
    QJsonObject m_definitions;
    QJsonArray m_exerciseOptions;
    unsigned int m_minRootNote;
    unsigned int m_maxRootNote;
    PlayMode m_playMode;
    unsigned int m_answerLength;
    unsigned int m_chosenRootNote;
    QString m_errorString;
};

}

#endif // MINUET_EXERCISECONTROLLER_H
