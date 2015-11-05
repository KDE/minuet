/****************************************************************************
**
** Copyright (C) 2015 by Sandro S. Andrade <sandroandrade@kde.org>
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

#include "exercisecontroller.h"

#include <QtCore/QDateTime>
#include <QtCore/QJsonObject>

#include "midisequencer.h"

ExerciseController::ExerciseController(MidiSequencer *midiSequencer) :
    m_midiSequencer(midiSequencer)
{
}

ExerciseController::~ExerciseController()
{
}

void ExerciseController::setExerciseOptions(QJsonArray exerciseOptions)
{
    m_exerciseOptions = exerciseOptions;
}

QString ExerciseController::randomlyChooseExercise()
{
    qsrand(QDateTime::currentDateTime().toTime_t());
    m_chosenExercise = qrand() % m_exerciseOptions.size();
    return m_exerciseOptions[m_chosenExercise].toObject()["name"].toString();
}

void ExerciseController::playChoosenExercise()
{
}
