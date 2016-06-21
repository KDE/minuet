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

#include "song.h"

#include <drumstick/alsaevent.h>

static inline bool eventLessThan(const drumstick::SequencerEvent *s1, const drumstick::SequencerEvent *s2)
{
    return s1->getTick() < s2->getTick();
}

Song::Song() :
    QList<drumstick::SequencerEvent *>(),
    m_format(0),
    m_ntrks(0),
    m_division(0),
    m_initialTempo(0)
{
}

Song::~Song()
{
    clear();
}

void Song::sort() 
{
    qStableSort(begin(), end(), eventLessThan);
}

void Song::clear()
{
    while (!isEmpty())
        delete takeFirst();
    m_fileName.clear();
    m_format = 0;
    m_ntrks = 0;
    m_division = 0;
}

void Song::setHeader(int format, int ntrks, int division)
{
    m_format = format;
    m_ntrks = ntrks;
    m_division = division;
}

void Song::setInitialTempo(int initialTempo)
{
    m_initialTempo = initialTempo;
}

void Song::setDivision(int division)
{
    m_division = division;
}

void Song::setFileName(const QString &fileName)
{
    m_fileName = fileName;
}
