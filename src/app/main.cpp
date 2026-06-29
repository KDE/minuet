// SPDX-FileCopyrightText: 2016 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "core.h"
#include <app/minuet_version.h>

#include <KAboutData>

#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
#include <KCrash>
#if defined(Q_OS_MACOS)
#include <KIconTheme>
#endif
#else
#include <KColorSchemeManager>
#endif
#include <KLocalizedString>

#include <QByteArray>
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QIcon>
#include <QLocale>
#include <QQuickStyle>
#include <QSet>
#include <QStandardPaths>
#include <QStringList>

#include <QDebug>

#if defined(Q_OS_MACOS) || defined(Q_OS_IOS)
#include <CoreFoundation/CoreFoundation.h>
#endif

using namespace Qt::StringLiterals;

#if defined(Q_OS_MACOS) || defined(Q_OS_IOS)
static QString stringFromCFString(CFStringRef string)
{
    const CFIndex length = CFStringGetLength(string);
    const CFIndex maxSize = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8) + 1;
    QByteArray buffer(maxSize, Qt::Uninitialized);
    if (!CFStringGetCString(string, buffer.data(), buffer.size(), kCFStringEncodingUTF8)) {
        return {};
    }
    return QString::fromUtf8(buffer.constData());
}

static QString appleLanguageToKdeLanguage(const QString &language)
{
    if (language == u"ca-ES-valencia"_s) {
        return u"ca@valencia"_s;
    }
    if (language.startsWith(u"zh-Hans"_s)) {
        return u"zh_CN"_s;
    }
    if (language.startsWith(u"zh-Hant"_s)) {
        return u"zh_TW"_s;
    }

    return QString(language).replace(u'-', u'_');
}

static QStringList preferredAppleLanguages()
{
    QStringList languages;
    CFPropertyListRef value = CFPreferencesCopyAppValue(CFSTR("AppleLanguages"), kCFPreferencesCurrentApplication);
    if (value) {
        if (CFGetTypeID(value) == CFArrayGetTypeID()) {
            CFArrayRef languageArray = static_cast<CFArrayRef>(value);
            const CFIndex count = CFArrayGetCount(languageArray);
            for (CFIndex i = 0; i < count; ++i) {
                CFTypeRef item = CFArrayGetValueAtIndex(languageArray, i);
                if (item && CFGetTypeID(item) == CFStringGetTypeID()) {
                    const QString language = stringFromCFString(static_cast<CFStringRef>(item));
                    if (!language.isEmpty() && !languages.contains(language)) {
                        languages.append(language);
                    }
                }
            }
        }
        CFRelease(value);
    }

    const QStringList systemLanguages = QLocale::system().uiLanguages();
    for (const QString &systemLanguage : systemLanguages) {
        if (!languages.contains(systemLanguage)) {
            languages.append(systemLanguage);
        }
    }
    return languages;
}

static void applyAppleApplicationLanguages()
{
    const QSet<QString> availableTranslations = KLocalizedString::availableApplicationTranslations();
    QStringList languages;

    const QStringList uiLanguages = preferredAppleLanguages();
    for (const QString &uiLanguage : uiLanguages) {
        const QString kdeLanguage = appleLanguageToKdeLanguage(uiLanguage);
        const QString genericLanguage = kdeLanguage.section(u'_', 0, 0);
        const QStringList candidates = kdeLanguage == genericLanguage ? QStringList{kdeLanguage} : QStringList{kdeLanguage, genericLanguage};

        for (const QString &candidate : candidates) {
            if (!languages.contains(candidate) && availableTranslations.contains(candidate)) {
                languages.append(candidate);
            }
        }

        if (genericLanguage == u"en"_s && languages.isEmpty()) {
            return;
        }
    }

    if (!languages.isEmpty()) {
        KLocalizedString::setLanguages(languages);
    }
}
#endif

int main(int argc, char *argv[])
{
#if defined(Q_OS_MACOS)
    KIconTheme::initTheme();
#endif

#if defined(Q_OS_IOS)
    // Direct Qt to search for icon assets inside our compiled virtual resource bundle (qrc)
    QIcon::setThemeSearchPaths(QStringList() << QStringLiteral(":/icons"));
    // Force the active fallback theme name to match our virtual prefix directory layout
    QIcon::setThemeName(QStringLiteral("breeze"));
#endif

    QGuiApplication application(argc, argv);

#if defined(Q_OS_MACOS)
    QCoreApplication::addLibraryPath(QDir(QCoreApplication::applicationDirPath()).absoluteFilePath(u"../PlugIns"_s));
#endif

#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
    KCrash::initialize();
#endif

    KLocalizedString::setApplicationDomain("minuet");
#if defined(Q_OS_IOS)
    KLocalizedString::addDomainLocaleDir("minuet", QDir(QCoreApplication::applicationDirPath()).absoluteFilePath(u"locale"_s));
#endif
#if defined(Q_OS_MACOS) || defined(Q_OS_IOS)
    applyAppleApplicationLanguages();
#endif

    KAboutData aboutData(u"minuet"_s,
                         i18n("Minuet"),
                         QString::fromUtf8(MINUET_VERSION_STRING),
                         i18n("A KDE application for music education"),
                         KAboutLicense::GPL,
                         i18n("(c) 2016, Sandro S. Andrade (sandroandrade@kde.org)"));
    aboutData.setHomepage(u"https://minuet.kde.org"_s);
    aboutData.setBugAddress("submit@bugs.kde.org");
    aboutData.setProductName("minuet");
    aboutData.setDesktopFileName(u"org.kde.minuet"_s);
    aboutData.addAuthor(u"Sandro S. Andrade"_s, i18n("Developer"), u"sandroandrade@kde.org"_s);
    aboutData.addAuthor(u"Ayush Shah"_s, i18n("Developer"), u"1595ayush@gmail.com"_s);
    aboutData.addAuthor(u"Alessandro Longo"_s, i18n("Minuet icon designer"), u"alessandro.longo@kdemail.net"_s);
    aboutData.addComponent(i18nc("@info:credit", "Fluidsynth"),
                           i18nc("@info:credit", "Software synthesizer based on the SoundFont 2 specifications. © 2003 Peter Hanappe and others."),
                           {},
                           u"https://github.com/FluidSynth/fluidsynth"_s,
                           KAboutLicense::LGPL_V2_1);
    aboutData.addComponent(i18nc("@info:credit", "Aubio"),
                           i18nc("@info:credit", "A library for audio and music analysis. © 2003-2015 Paul Brossier."),
                           {},
                           u"https://github.com/aubio/aubio"_s,
                           KAboutLicense::GPL_V3);
    aboutData.setTranslator(i18nc("NAME OF TRANSLATORS", "Your names"), i18nc("EMAIL OF TRANSLATORS", "Your emails"));

#if defined(Q_OS_ANDROID)
    QQuickStyle::setStyle(u"org.kde.breeze"_s);
    KColorSchemeManager::instance();
#elif defined(Q_OS_IOS)
    QQuickStyle::setStyle(u"iOS"_s);
    KColorSchemeManager::instance();
#else
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(u"org.kde.desktop"_s);
    }
#endif

    QGuiApplication::setWindowIcon(QIcon(u":/icons/64-apps-minuet.png"_s));

    QCommandLineParser parser;
    KAboutData::setApplicationData(aboutData);
#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
    aboutData.setupCommandLine(&parser);
#else
    parser.addHelpOption();
    parser.addVersionOption();
#endif
    parser.process(application);
#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
    aboutData.processCommandLine(&parser);
#endif

#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
    const QDir writableDataDir(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
    const QString soundfontDirPath = writableDataDir.absoluteFilePath(u"soundfonts"_s);
    const QString soundfontPath = QDir(soundfontDirPath).absoluteFilePath(u"GeneralUser-v1.47.sf2"_s);
    if (!QFile::exists(soundfontPath)) {
        QDir().mkpath(soundfontDirPath);
        const QStringList assetPaths = {
            u"assets:/share/minuet/soundfonts/GeneralUser-v1.47.sf2"_s,
            u"assets:/data/soundfonts/GeneralUser-v1.47.sf2"_s,
            u"assets:/share/GeneralUser-v1.47.sf2"_s,
            u":/src/plugins/fluidsynthsoundcontroller/GeneralUser-v1.47.sf2"_s,
        };
        for (const QString &assetPath : assetPaths) {
            QFile assetFile(assetPath);
            if (assetFile.exists() && assetFile.copy(soundfontPath)) {
                qDebug() << "Copied" << QFileInfo(soundfontPath).size() << "b soundfont file to" << soundfontPath;
                break;
            }
        }
    }
#endif
    Minuet::Core::initialize();

    return QGuiApplication::exec();
}
