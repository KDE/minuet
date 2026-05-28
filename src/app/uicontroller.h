// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef MINUET_UICONTROLLER_H
#define MINUET_UICONTROLLER_H

#include <QObject>
#include <QString>

namespace Minuet
{
class Core;

class UiController : public QObject
{
    Q_OBJECT

public:
    ~UiController() override = default;

    bool initialize(Core *core);
    QString errorString() const;

private:
    friend class Core;

    explicit UiController(QObject *parent = nullptr);

    QString m_errorString;
};

}

#endif
