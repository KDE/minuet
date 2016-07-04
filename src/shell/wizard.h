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

#ifndef WIZARD_H
#define WIZARD_H

#include "ui_wizardsystemcheck.h"

#include <QWizard>
#include <QPainter>
#include <QItemDelegate>

class WizardDelegate: public QItemDelegate
{
    Q_OBJECT

public:
    explicit WizardDelegate(QAbstractItemView *parent = 0)
        : QItemDelegate(parent)
    {
    }
    void paint(QPainter *painter, const QStyleOptionViewItem &option, const QModelIndex &index) const
    {
        if (index.column() == 1) {
            painter->save();
            QStyleOptionViewItem opt(option);
            QStyle *style = opt.widget ? opt.widget->style() : QApplication::style();
            const int textMargin = style->pixelMetric(QStyle::PM_FocusFrameHMargin) + 1;
            style->drawPrimitive(QStyle::PE_PanelItemViewItem, &opt, painter, opt.widget);

            QFont font = painter->font();
            font.setBold(true);
            painter->setFont(font);
            QRect r1 = option.rect;
            r1.adjust(0, textMargin, 0, - textMargin);
            int mid = (int)((r1.height() / 2));
            r1.setBottom(r1.y() + mid);
            QRect r2 = option.rect;
            r2.setTop(r2.y() + mid);
            painter->drawText(r1, Qt::AlignLeft | Qt::AlignBottom , index.data().toString());
            font.setBold(false);
            painter->setFont(font);
            QString subText = index.data(Qt::UserRole).toString();
            painter->drawText(r2, Qt::AlignLeft | Qt::AlignVCenter , subText);
            painter->restore();
        } else {
            QItemDelegate::paint(painter, option, index);
        }
    }
};

class Wizard : public QWizard
{
    Q_OBJECT

public:
    explicit Wizard(QWidget * parent = 0, Qt::WindowFlags flags = 0);
    
    bool isOk() const;
    void adjustSettings();

private Q_SLOTS:
    void checkSystem();
    
private:
    QTreeWidgetItem *addTreeWidgetItem(const QString &text, const QString &subText);

private:
    bool m_systemCheckIsOk;
    Ui::WizardSystemCheck m_systemCheck;
    QIcon m_okIcon;
    QIcon m_badIcon;
    QString m_timidityPath;
};

#endif // WIZARD_H
