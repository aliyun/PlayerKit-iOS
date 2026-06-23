//
//  FullscreenViewController.h
//  AliPlayerKit
//
//  Created by keria on 2024/3/15.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 全屏容器视图控制器。
 *
 * @discussion 作为全屏窗口的 rootViewController，负责控制屏幕旋转方向、
 *             状态栏隐藏及 Home Indicator 自动隐藏等系统级行为。
 *             支持动态切换方向锁定，初始支持所有方向（跟随设备方向），
 *             调用 lockToLandscape 后锁定为横屏。
 */
@interface FullscreenViewController : UIViewController

/// 系统旋转时的回调，由 DefaultFullscreenTransition 设置，用于在系统旋转动画中
/// 同步重置 playerView 的 transform 和 frame
@property (nonatomic, copy, nullable) void (^rotationHandler)(CGSize targetSize,
                                                               id<UIViewControllerTransitionCoordinator> coordinator);

- (void)lockToLandscape;
- (void)unlockOrientation;

@end

NS_ASSUME_NONNULL_END
