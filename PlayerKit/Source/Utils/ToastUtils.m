//
//  ToastUtils.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "ToastUtils.h"

static const NSTimeInterval kToastDurationDefault = 1.5;

@implementation ToastUtils

+ (void)showToast:(NSString *)message inViewController:(UIViewController *)viewController {
    [self showToast:message inViewController:viewController duration:kToastDurationDefault];
}

+ (void)showToast:(NSString *)message
 inViewController:(UIViewController *)viewController
         duration:(NSTimeInterval)duration {
    if (!message.length || !viewController) return;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [viewController presentViewController:alert animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
