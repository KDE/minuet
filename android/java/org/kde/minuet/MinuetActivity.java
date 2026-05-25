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
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        SplashScreen.installSplashScreen(this);
        super.onCreate(savedInstanceState);
    }
}
