//
//  ToastUtils.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 统一 Toast 提示工具。
 *
 * @discussion 基于 UIAlertController 实现轻量级 toast 弹窗，自动消失，无需用户操作。
 */
@interface ToastUtils : NSObject

/**
 * @brief 显示 toast 提示（默认 1.5s 后自动消失）。
 *
 * @param message        提示文案。
 * @param viewController 展示 toast 的 ViewController。
 */
+ (void)showToast:(NSString *)message
 inViewController:(UIViewController *)viewController;

/**
 * @brief 显示 toast 提示（自定义时长）。
 *
 * @param message        提示文案。
 * @param viewController 展示 toast 的 ViewController。
 * @param duration       显示时长（秒）。
 */
+ (void)showToast:(NSString *)message
 inViewController:(UIViewController *)viewController
         duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
