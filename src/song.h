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

#ifndef SONG_H
#define SONG_H

#include <QtCore/QList>

namespace drumstick {
    class SequencerEvent;
}

class Song : public QList<drumstick::SequencerEvent *>
{
public:
    Song();
    virtual ~Song();
    
    void clear();
    void sort();
    void setHeader(int format, int ntrks, int division);
    void setInitialTempo(int initialTempo);
    void setDivision(int division);
    void setFileName(const QString &fileName);
    
    int format() const { return m_format; }
    int tracks() const { return m_ntrks; }
    int division() const { return m_division; }
    int initialTempo() const { return m_initialTempo; }
    QString fileName() const { return m_fileName; }

private:    
    int m_format;
    int m_ntrks;
    int m_division;   
    int m_initialTempo;
    QString m_fileName;
};

#endif // SONG_H
