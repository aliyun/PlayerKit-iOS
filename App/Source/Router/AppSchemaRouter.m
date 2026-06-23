//
//  AppSchemaRouter.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "AppSchemaRouter.h"
#import "AppModuleManager.h"

@implementation AppSchemaRouter

#pragma mark - Public Methods

+ (void)navigateToSchema:(NSString *)schema fromViewController:(UIViewController *)viewController {
    if (!schema || schema.length == 0) {
        return;
    }
    
    if (!viewController) {
        NSLog(@"[AppSchemaRouter] Error: viewController is nil for schema: %@", schema);
        return;
    }
    
    // 首先尝试内部模块路由
    BOOL handled = [[AppModuleManager sharedManager] handleURL:schema fromViewController:viewController];
    if (handled) {
        return;
    }
    
    // 尝试作为外部 URL 打开
    NSURL *url = [NSURL URLWithString:schema];
    if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        return;
    }
    
    // 所有路由尝试失败时显示错误提示
    [self showRouteErrorForSchema:schema fromViewController:viewController];
}

#pragma mark - Private Methods

// 显示错误提示，表明该 schema 无法解析
+ (void)showRouteErrorForSchema:(NSString *)schema fromViewController:(UIViewController *)viewController {
    if (!viewController) {
        NSLog(@"[AppSchemaRouter] Error: Unable to navigate to: %@", schema);
        return;
    }
    
    NSString *title = @"Navigation Error";
    NSString *message = [NSString stringWithFormat:@"Unable to navigate to: %@", schema];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil];
    [alert addAction:okAction];
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

@end
