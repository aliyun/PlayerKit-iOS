//
//  SceneDelegate.m
//  Example
//
//  Created by keria on 2026/10/30.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "SceneDelegate.h"
#import <App/App.h>

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    AppHomeViewController *homeVC = [[AppHomeViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:homeVC];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
}

@end
