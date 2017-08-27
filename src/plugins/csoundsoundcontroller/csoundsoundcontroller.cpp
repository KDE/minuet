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

#include "csoundsoundcontroller.h"
#include "csengine.h"

#include <QtMath>
#include <QLoggingCategory>
#include <QtQml>

Q_DECLARE_LOGGING_CATEGORY(MINUETANDROID)

CsoundSoundController::CsoundSoundController(QObject *parent):
    Minuet::ISoundController(parent),
    m_csoundEngine(new CsEngine)
{
    qmlRegisterType<CsoundSoundController>("org.kde.minuet", 1, 0, "CsoundSoundController");
    openExerciseFile();
//    setQuestionLabel("new question");
}

void CsoundSoundController::openExerciseFile()
{
    QStringList templateList;
    templateList.append(QStringLiteral("assets:/share/template.csd"));
    templateList.append(QStringLiteral("assets:/share/template_rhythm.csd"));

    foreach (const QString &templateString, templateList) {
        QFile sfile(templateString);
        if (!sfile.open(QIODevice::ReadOnly | QIODevice::Text))
            return;

        QTextStream in(&sfile);
        QString lineData;
        QString tempBeginLine;
        QString tempEndLine;

        while (!in.atEnd()) {
            lineData = in.readLine();
            tempBeginLine = tempBeginLine + lineData + "\n";
            if (lineData.contains("<CsScore>")) {
                m_begLine.append(tempBeginLine);
                break;
            }
        }

        while (!in.atEnd()) {
            lineData = in.readLine();
            tempEndLine += lineData + "\n";
        }
        m_endLine.append(tempEndLine);
    }
}

void CsoundSoundController::appendEvent(QList<unsigned int> midiNotes, QList<float> barStartInfo, QString playMode)
{
    //TODO : use grantlee processing or any other text template library
    int templateNumber = playMode == "rhythm" ? 1:0;
    QString content;
    QString fifthParam = QStringLiteral("100");
    QFile m_csdFileOpen(QStringLiteral("./template.csd"));

    if(!m_csdFileOpen.isOpen()) {
        m_csdFileOpen.open(QIODevice::ReadWrite | QIODevice::Text);
    }
    m_csdFileOpen.resize(0);

    if (playMode == "rhythm") {
        QString wave = QStringLiteral("f 1 0 16384 10 1\n\n");
        content += wave;
        fifthParam = QStringLiteral("");
    }

    for(int i=0; i<midiNotes.count(); i++) {
        QString initScore = QString("i 1 %1 %2 %3 %4\n").arg(QString::number(barStartInfo.at(i))).arg(QString::number(1)).arg(QString::number(midiNotes.at(i))).arg(fifthParam);
        content += initScore;
    }

    if (playMode != "rhythm") {
        QString instrInit = "i 99 0 " + QString::number(barStartInfo.at(barStartInfo.count()-1)+1) + "\ne\n";//instrument will be active till the end of the notes +1 second
        content += instrInit;
    }

    QString templateContent = m_begLine[templateNumber] + content + m_endLine[templateNumber];
    m_csdFileOpen.seek(0);
    QByteArray contentByte = templateContent.toUtf8();
    m_csdFileOpen.write(contentByte);
}

CsoundSoundController::~CsoundSoundController()
{
    delete m_csoundEngine;
}

void CsoundSoundController::prepareFromExerciseOptions(QJsonArray selectedExerciseOptions)
{
    float barStart = 0;
    QList<unsigned int> midiNotes;
    QList<float> barStartInfo;

    if (m_playMode == "rhythm") {
        for(int k = 0; k < 4; ++k) {
            midiNotes.append(80);
            barStartInfo.append(barStart++);
        }
    }

    int exerciseOptionsSize = selectedExerciseOptions.size();

    for (int i = 0; i < exerciseOptionsSize; ++i) {
        QString sequence = selectedExerciseOptions[i].toObject()[QStringLiteral("sequence")].toArray()[0].toString();
        unsigned int chosenRootNote = selectedExerciseOptions[i].toObject()[QStringLiteral("rootNote")].toString().toInt();
        if (m_playMode != "rhythm") {
            midiNotes.append(chosenRootNote);
            barStartInfo.append(barStart);

            unsigned int j = 1;
            foreach(const QString &additionalNote, sequence.split(' ')) {
                midiNotes.append(chosenRootNote+additionalNote.toInt());
                barStartInfo.append((m_playMode == "scale") ? barStart+j:barStart);
                ++j;
            }
            barStart++;
        }
        else {
            midiNotes.append(80);
            barStartInfo.append(barStart);
            foreach(QString additionalNote, sequence.split(' ')) { // krazy:exclude=foreach
                midiNotes.append(37);
                barStartInfo.append(barStart);
                float dotted = 1;
                if (additionalNote.endsWith('.')) {
                    dotted = 1.5;
                    additionalNote.chop(1);
                }
                barStart += dotted*1*(4.0/additionalNote.toInt());
            }
        }
    }


    if (m_playMode == "rhythm") {
        midiNotes.append(80);
        barStartInfo.append(barStart);
    }
    appendEvent(midiNotes, barStartInfo, m_playMode);
}

void CsoundSoundController::prepareFromMidiFile(const QString &fileName)
{
    Q_UNUSED(fileName)
}

void CsoundSoundController::play()
{
    m_csoundEngine->start();
    setState(PlayingState);
}

void CsoundSoundController::pause()
{

}

void CsoundSoundController::stop()
{
    m_csoundEngine->stop();
    setState(StoppedState);
}

void CsoundSoundController::reset()
{
}

void CsoundSoundController::setPitch (qint8 pitch)
{
    Q_UNUSED(pitch)
}


void CsoundSoundController::setVolume (quint8 volume)
{
    Q_UNUSED(volume)
}


void CsoundSoundController::setTempo (quint8 tempo)
{
    Q_UNUSED(tempo)
}

//#include "moc_csoundsoundcontroller.cpp"
