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

import QtQuick 2.7

Item {
    property Item initialAnchor

    width: 7 * keyWidth; height: keyHeight - 10
    anchors.left: initialAnchor.right

    WhiteKey { id: whiteKey1 }
    BlackKey { anchor: whiteKey1 }
    WhiteKey { id: whiteKey2; anchor: whiteKey1 }
    BlackKey { anchor: whiteKey2 }
    WhiteKey { id: whiteKey3; anchor: whiteKey2 }
    WhiteKey { id: whiteKey4; anchor: whiteKey3 }
    BlackKey { anchor: whiteKey4 }
    WhiteKey { id: whiteKey5; anchor: whiteKey4 }
    BlackKey { anchor: whiteKey5 }
    WhiteKey { id: whiteKey6; anchor: whiteKey5 }
    BlackKey { anchor: whiteKey6 }
    WhiteKey { anchor: whiteKey6 }
}
