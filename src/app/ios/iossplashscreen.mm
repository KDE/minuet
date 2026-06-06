// SPDX-FileCopyrightText: 2026 Sandro Andrade <sandroandrade@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "iossplashscreen.h"

#import <UIKit/UIKit.h>

namespace
{
UIViewController *s_splashViewController = nil;

UIWindowScene *activeWindowScene()
{
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        if (scene.activationState == UISceneActivationStateForegroundActive
            || scene.activationState == UISceneActivationStateForegroundInactive) {
            return static_cast<UIWindowScene *>(scene);
        }
    }
    return nil;
}

UIWindow *currentKeyWindow(UIWindowScene *windowScene)
{
    for (UIWindow *window in windowScene.windows) {
        if (window.isKeyWindow) {
            return window;
        }
    }
    return nil;
}
}

namespace Minuet
{
void showIosSplashScreen()
{
    if (s_splashViewController) {
        return;
    }

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LaunchScreen" bundle:nil];
    UIViewController *viewController = [storyboard instantiateInitialViewController];
    if (!viewController) {
        return;
    }

    UIWindowScene *windowScene = activeWindowScene();
    UIWindow *window = windowScene ? currentKeyWindow(windowScene) : nil;
    UIViewController *parentViewController = window.rootViewController;
    if (!parentViewController) {
        return;
    }

    viewController.view.frame = parentViewController.view.bounds;
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [parentViewController addChildViewController:viewController];
    [parentViewController.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:parentViewController];
    s_splashViewController = viewController;
}

void hideIosSplashScreen()
{
    if (!s_splashViewController) {
        return;
    }

    UIViewController *viewController = s_splashViewController;
    s_splashViewController = nil;
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}
}
