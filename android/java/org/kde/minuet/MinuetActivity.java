/*
    SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
    SPDX-License-Identifier: BSD-3-Clause
*/

package org.kde.minuet;

import android.os.Bundle;

import androidx.core.splashscreen.SplashScreen;

import org.qtproject.qt.android.bindings.QtActivity;

public class MinuetActivity extends QtActivity
{
    private static volatile boolean s_keepSplashScreenVisible = true;

    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        s_keepSplashScreenVisible = true;
        SplashScreen splashScreen = SplashScreen.installSplashScreen(this);
        splashScreen.setKeepOnScreenCondition(() -> s_keepSplashScreenVisible);
        super.onCreate(savedInstanceState);
    }

    public static void hideSplashScreen()
    {
        s_keepSplashScreenVisible = false;
    }
}
