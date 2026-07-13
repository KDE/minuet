// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include <utils/rhythmtoken.h>

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSet>
#include <QTest>

#include <utility>

using namespace Qt::StringLiterals;

namespace
{
QJsonArray loadArray(const QString &relativePath, const QString &arrayName)
{
    QFile file(u"%1/%2"_s.arg(QStringLiteral(MINUET_SOURCE_DIR), relativePath));
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }
    return QJsonDocument::fromJson(file.readAll()).object().value(arrayName).toArray();
}

bool hasTag(const QJsonObject &definition, const QString &tag)
{
    return definition.value(u"tags"_s).toArray().contains(tag);
}

QJsonArray definitionsWithTags(const QJsonArray &definitions, const QStringList &tags)
{
    QJsonArray filtered;
    for (const QJsonValue &value : definitions) {
        const QJsonObject definition = value.toObject();
        bool matches = true;
        for (const QString &tag : tags) {
            if (!hasTag(definition, tag)) {
                matches = false;
                break;
            }
        }
        if (matches) {
            filtered.append(definition);
        }
    }
    return filtered;
}

QStringList stringList(const QJsonArray &values)
{
    QStringList strings;
    for (const QJsonValue &value : values) {
        strings.append(value.toString());
    }
    return strings;
}

QJsonObject restCategory(const QString &relativePath)
{
    const QJsonArray exercises = loadArray(relativePath, u"exercises"_s);
    if (exercises.isEmpty()) {
        return {};
    }
    const QJsonArray children = exercises.first().toObject().value(u"children"_s).toArray();
    for (const QJsonValue &value : children) {
        const QJsonObject category = value.toObject();
        if (category.value(u"name"_s).toString().endsWith(u"with rests"_s)) {
            return category;
        }
    }
    return {};
}

QString nameForSequence(const QJsonArray &definitions, const QString &sequence)
{
    for (const QJsonValue &value : definitions) {
        const QJsonObject definition = value.toObject();
        if (definition.value(u"sequence"_s).toString() == sequence) {
            return definition.value(u"name"_s).toString();
        }
    }
    return {};
}

QString onsetSignature(const QString &sequence)
{
    QStringList onsets;
    double cursor = 0.0;
    for (const QString &text : sequence.split(u' ', Qt::SkipEmptyParts)) {
        const Minuet::RhythmToken token = Minuet::parseRhythmToken(text);
        if (!token.rest) {
            onsets.append(QString::number(cursor, 'f', 2));
        }
        cursor += token.quarterNoteBeats();
    }
    return onsets.join(u',');
}

QSet<QString> expectedRestVariants(const QJsonArray &baseDefinitions)
{
    QSet<QString> variants;
    for (const QJsonValue &value : baseDefinitions) {
        const QStringList tokens = value.toObject().value(u"sequence"_s).toString().split(u' ', Qt::SkipEmptyParts);
        const int allRestMask = (1 << tokens.size()) - 1;
        for (int mask = 1; mask < allRestMask; ++mask) {
            QStringList variant = tokens;
            for (int tokenIndex = 0; tokenIndex < variant.size(); ++tokenIndex) {
                if (mask & (1 << tokenIndex)) {
                    variant[tokenIndex].prepend(u'r');
                }
            }
            variants.insert(variant.join(u' '));
        }
    }
    return variants;
}
}

class RhythmRestTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase();
    void parsesRhythmTokens();
    void containsEveryMixedRestVariant();
    void categoryCountsAreStable();
    void categoryFiltersMatchPracticeModes();
    void consecutiveSixteenthsUseBeams();
    void listeningPatternsHaveUniqueOnsets();
    void everyPatternFillsOneBeat();

private:
    QJsonArray m_baseDefinitions;
    QJsonArray m_restDefinitions;
    QJsonArray m_allDefinitions;
};

void RhythmRestTest::initTestCase()
{
    m_baseDefinitions = loadArray(u"data/definitions/rhythm-definitions.json"_s, u"definitions"_s);
    m_restDefinitions = loadArray(u"data/definitions/rhythm-rest-definitions.json"_s, u"definitions"_s);
    QVERIFY(!m_baseDefinitions.isEmpty());
    QVERIFY(!m_restDefinitions.isEmpty());

    m_allDefinitions = m_baseDefinitions;
    for (const QJsonValue &definition : std::as_const(m_restDefinitions)) {
        m_allDefinitions.append(definition);
    }
}

void RhythmRestTest::parsesRhythmTokens()
{
    const Minuet::RhythmToken note = Minuet::parseRhythmToken(u"16");
    QVERIFY(note.valid);
    QVERIFY(!note.rest);
    QVERIFY(!note.dotted);
    QCOMPARE(note.denominator, 16);
    QCOMPARE(note.quarterNoteBeats(), 0.25);

    const Minuet::RhythmToken rest = Minuet::parseRhythmToken(u"r8.");
    QVERIFY(rest.valid);
    QVERIFY(rest.rest);
    QVERIFY(rest.dotted);
    QCOMPARE(rest.denominator, 8);
    QCOMPARE(rest.quarterNoteBeats(), 0.75);

    QVERIFY(!Minuet::parseRhythmToken(u"r").valid);
    QVERIFY(!Minuet::parseRhythmToken(u"r8..").valid);
    QVERIFY(!Minuet::parseRhythmToken(u"0").valid);
}

void RhythmRestTest::containsEveryMixedRestVariant()
{
    QCOMPARE(m_restDefinitions.size(), 38);

    QSet<QString> actualSequences;
    for (const QJsonValue &value : std::as_const(m_restDefinitions)) {
        const QJsonObject definition = value.toObject();
        const QString sequence = definition.value(u"sequence"_s).toString();
        QVERIFY2(!actualSequences.contains(sequence), qPrintable(sequence));
        actualSequences.insert(sequence);

        bool containsNote = false;
        bool containsRest = false;
        for (const QString &text : sequence.split(u' ', Qt::SkipEmptyParts)) {
            const Minuet::RhythmToken token = Minuet::parseRhythmToken(text);
            QVERIFY2(token.valid, qPrintable(text));
            containsRest |= token.rest;
            containsNote |= !token.rest;
        }
        QVERIFY(containsRest);
        QVERIFY(containsNote);
        QVERIFY(!definition.value(u"name"_s).toString().isEmpty());
    }

    const QJsonArray mediumBases = definitionsWithTags(m_baseDefinitions, {u"rhythm"_s, u"medium"_s});
    QCOMPARE(actualSequences, expectedRestVariants(mediumBases));

    const QJsonArray easyBases = definitionsWithTags(m_baseDefinitions, {u"rhythm"_s, u"easy"_s});
    const QSet<QString> easyVariants = expectedRestVariants(easyBases);
    QSet<QString> taggedEasyVariants;
    for (const QJsonValue &value : std::as_const(m_restDefinitions)) {
        const QJsonObject definition = value.toObject();
        if (hasTag(definition, u"easy-with-rests"_s)) {
            taggedEasyVariants.insert(definition.value(u"sequence"_s).toString());
        }
    }
    QCOMPARE(taggedEasyVariants, easyVariants);
}

void RhythmRestTest::categoryCountsAreStable()
{
    QCOMPARE(definitionsWithTags(m_allDefinitions, {u"rhythm"_s, u"easy-with-rests"_s}).size(), 10);
    QCOMPARE(definitionsWithTags(m_allDefinitions, {u"rhythm"_s, u"easy-with-rests"_s, u"rest-listening"_s}).size(), 7);
    QCOMPARE(definitionsWithTags(m_allDefinitions, {u"rhythm"_s, u"medium-with-rests"_s}).size(), 46);
    QCOMPARE(definitionsWithTags(m_allDefinitions, {u"rhythm"_s, u"medium-with-rests"_s, u"rest-listening"_s}).size(), 15);
}

void RhythmRestTest::categoryFiltersMatchPracticeModes()
{
    const QJsonObject easy = restCategory(u"data/exercises/rhythm-easy-rests.json"_s);
    const QJsonObject medium = restCategory(u"data/exercises/rhythm-medium-rests.json"_s);
    QVERIFY(!easy.isEmpty());
    QVERIFY(!medium.isEmpty());

    QCOMPARE(definitionsWithTags(m_allDefinitions, stringList(easy.value(u"and-tags"_s).toArray())).size(), 7);
    QCOMPARE(definitionsWithTags(m_allDefinitions, stringList(easy.value(u"clapping-and-tags"_s).toArray())).size(), 10);
    QCOMPARE(definitionsWithTags(m_allDefinitions, stringList(medium.value(u"and-tags"_s).toArray())).size(), 15);
    QCOMPARE(definitionsWithTags(m_allDefinitions, stringList(medium.value(u"clapping-and-tags"_s).toArray())).size(), 46);
}

void RhythmRestTest::consecutiveSixteenthsUseBeams()
{
    const QString pair = u"\uE1F0\uE1F9\uE1F4"_s;
    const QString triple = u"\uE1F0\uE1F9\uE1F4\uE1F9\uE1F4"_s;
    const QString sixteenthRest = u"\uE4E7"_s;
    const QString eighthRest = u"\uE4E6"_s;
    const QString isolatedSixteenth = u"\uE1D9"_s;

    QCOMPARE(nameForSequence(m_restDefinitions, u"r16 16 16 16"_s), sixteenthRest + u' ' + triple);
    QCOMPARE(nameForSequence(m_restDefinitions, u"16 r16 16 16"_s), isolatedSixteenth + u' ' + sixteenthRest + u' ' + pair);
    QCOMPARE(nameForSequence(m_restDefinitions, u"r16 r16 16 16"_s), sixteenthRest + u' ' + sixteenthRest + u' ' + pair);
    QCOMPARE(nameForSequence(m_restDefinitions, u"16 16 r16 16"_s), pair + u' ' + sixteenthRest + u' ' + isolatedSixteenth);
    QCOMPARE(nameForSequence(m_restDefinitions, u"16 16 16 r16"_s), triple + u' ' + sixteenthRest);
    QCOMPARE(nameForSequence(m_restDefinitions, u"r16 16 16 r16"_s), sixteenthRest + u' ' + pair + u' ' + sixteenthRest);
    QCOMPARE(nameForSequence(m_restDefinitions, u"16 16 r16 r16"_s), pair + u' ' + sixteenthRest + u' ' + sixteenthRest);
    QCOMPARE(nameForSequence(m_restDefinitions, u"r8 16 16"_s), eighthRest + u' ' + pair);
    QCOMPARE(nameForSequence(m_restDefinitions, u"16 16 r8"_s), pair + u' ' + eighthRest);
}

void RhythmRestTest::listeningPatternsHaveUniqueOnsets()
{
    for (const QString &category : {u"easy-with-rests"_s, u"medium-with-rests"_s}) {
        const QJsonArray definitions = definitionsWithTags(m_allDefinitions, {u"rhythm"_s, category, u"rest-listening"_s});
        QSet<QString> signatures;
        for (const QJsonValue &value : definitions) {
            const QString signature = onsetSignature(value.toObject().value(u"sequence"_s).toString());
            QVERIFY2(!signatures.contains(signature), qPrintable(signature));
            signatures.insert(signature);
        }
        QCOMPARE(signatures.size(), definitions.size());
    }
}

void RhythmRestTest::everyPatternFillsOneBeat()
{
    for (const QJsonValue &value : std::as_const(m_allDefinitions)) {
        const QString sequence = value.toObject().value(u"sequence"_s).toString();
        double duration = 0.0;
        for (const QString &text : sequence.split(u' ', Qt::SkipEmptyParts)) {
            const Minuet::RhythmToken token = Minuet::parseRhythmToken(text);
            QVERIFY2(token.valid, qPrintable(text));
            duration += token.quarterNoteBeats();
        }
        QVERIFY2(qAbs(duration - 1.0) < 0.0001, qPrintable(sequence));
    }
}

QTEST_GUILESS_MAIN(RhythmRestTest)

#include "rhythmresttest.moc"
