//
//  DefaultFullscreenTransition.m
//  AliPlayerKit
//
//  Created by keria on 2024/3/15.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "DefaultFullscreenTransition.h"
#import "FullscreenViewController.h"
#import "AliPlayerView.h"

// 全屏过渡动画时长（对齐官方 Demo 标准）
static const NSTimeInterval kFullscreenAnimationDuration = 0.25;

@interface DefaultFullscreenTransition ()

// 动画防重入标志，避免动画进行中再次触发导致状态错乱
@property (nonatomic, assign) BOOL isAnimating;
// 按来源 scene 懒创建，退出后保留以供复用。
@property (nonatomic, strong, nullable) UIWindow *fullscreenWindow;
// 弱持有来源窗口及原 keyWindow，不延长宿主窗口生命周期。
@property (nonatomic, weak, nullable) UIWindow *sourceWindow;
@property (nonatomic, weak, nullable) UIWindow *sourceKeyWindow;
// 占位视图仅跟随 autoresizing，不保存或恢复宿主 Auto Layout 约束。
@property (nonatomic, strong, nullable) UIView *originalPlaceholderView;
// 全屏容器控制器
@property (nonatomic, strong, nullable) FullscreenViewController *fullscreenViewController;
// 原始父视图（弱引用，避免循环持有）
@property (nonatomic, weak, nullable) UIView *originalSuperview;
// 原始 frame
@property (nonatomic, assign) CGRect originalFrame;
// 原始 subview index
@property (nonatomic, assign) NSInteger originalIndex;
// 原始 autoresizingMask
@property (nonatomic, assign) UIViewAutoresizing originalAutoresizingMask;
// 全屏状态
@property (nonatomic, assign, readwrite) BOOL isInFullscreen;

@end

@implementation DefaultFullscreenTransition

#pragma mark - Lifecycle

- (void)dealloc {
    [self cleanupFullscreenWindow];
}

#pragma mark - FullscreenTransition

- (void)enterFullscreenWithPlayerView:(AliPlayerView *)playerView
                             animated:(BOOL)animated
                           completion:(nullable void(^)(void))completion {
    // 已在全屏状态则直接返回
    if (self.isInFullscreen) {
        if (completion) {
            completion();
        }
        return;
    }
    // 动画进行中则忽略本次调用，避免状态竞争
    if (self.isAnimating) {
        if (completion) {
            completion();
        }
        return;
    }

    UIWindow *sourceWindow = [self sourceWindowForView:playerView];
    if (!sourceWindow || !playerView.superview) {
        // 未挂载时拒绝迁移，不回退到其他 scene 的窗口。
        if (completion) {
            completion();
        }
        return;
    }

    // 提前标记全屏状态与动画状态，防止快速切换时的重入
    self.isInFullscreen = YES;
    self.isAnimating = YES;
    self.sourceWindow = sourceWindow;
    self.sourceKeyWindow = [self keyWindowForSourceWindow:sourceWindow];

    // ========== Phase 1：迁入全屏窗口（保持原始位置，无 transform）==========
    self.originalSuperview = playerView.superview;
    self.originalFrame = playerView.frame;
    self.originalAutoresizingMask = playerView.autoresizingMask;
    self.originalIndex = [playerView.superview.subviews indexOfObject:playerView];

    CGRect rectInSourceWindow = [playerView.superview convertRect:playerView.frame toView:sourceWindow];
    [self ensureFullscreenWindowForSourceWindow:sourceWindow];

    UIView *placeholder = [[UIView alloc] initWithFrame:self.originalFrame];
    placeholder.backgroundColor = [UIColor clearColor];
    placeholder.userInteractionEnabled = NO;
    placeholder.accessibilityElementsHidden = YES;
    placeholder.autoresizingMask = self.originalAutoresizingMask;
    self.originalPlaceholderView = placeholder;

    // 将 playerView 直接迁入 fullscreenWindow（VC 初始支持所有方向，窗口保持竖屏）
    // CATransaction 确保 reparent + 显示窗口在同一帧提交，无视觉闪烁
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self.originalSuperview insertSubview:placeholder atIndex:self.originalIndex];
    playerView.autoresizingMask = UIViewAutoresizingNone;
    [self.fullscreenViewController.view addSubview:playerView];
    self.fullscreenWindow.hidden = NO;
    [self.fullscreenWindow layoutIfNeeded];
    CGRect rectInFullscreenWindow = [self.fullscreenWindow convertRect:rectInSourceWindow fromWindow:sourceWindow];
    playerView.frame = [self.fullscreenViewController.view convertRect:rectInFullscreenWindow
                                                           fromView:self.fullscreenWindow];
    [CATransaction commit];

    // ========== Phase 2：触发系统旋转至横屏，在旋转动画中同步扩展 playerView ==========
    __weak typeof(self) weakSelf = self;
    __block BOOL completed = NO;

    self.fullscreenViewController.rotationHandler = ^(CGSize targetSize,
                                                       id<UIViewControllerTransitionCoordinator> coordinator) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            playerView.frame = CGRectMake(0, 0, targetSize.width, targetSize.height);
            [playerView layoutIfNeeded];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            if (completed) { return; }
            completed = YES;
            playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                strongSelf.fullscreenViewController.rotationHandler = nil;
                strongSelf.isAnimating = NO;
            }
            if (completion) {
                completion();
            }
        }];
    };

    [self.fullscreenWindow makeKeyWindow];
    [self.fullscreenViewController lockToLandscape];
    [self triggerOrientationUpdate];

    // 回退：设备已横屏或系统未触发旋转时，手动扩展至全屏
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (completed) { return; }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.fullscreenViewController.rotationHandler) {
            return;
        }
        completed = YES;
        strongSelf.fullscreenViewController.rotationHandler = nil;
        CGRect bounds = strongSelf.fullscreenViewController.view.bounds;
        NSTimeInterval duration = animated ? kFullscreenAnimationDuration : 0;
        [UIView animateWithDuration:duration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            playerView.frame = bounds;
            [playerView layoutIfNeeded];
        } completion:^(BOOL finished) {
            playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            strongSelf.isAnimating = NO;
            if (completion) {
                completion();
            }
        }];
    });
}

- (void)exitFullscreenWithPlayerView:(AliPlayerView *)playerView
                            animated:(BOOL)animated
                          completion:(nullable void(^)(void))completion {
    NSAssert([NSThread isMainThread], @"exitFullscreen must be called on the main thread");

    // 未在全屏状态则直接返回
    if (!self.isInFullscreen) {
        if (completion) {
            completion();
        }
        return;
    }
    // 动画进行中则忽略本次调用
    if (self.isAnimating) {
        if (completion) {
            completion();
        }
        return;
    }

    // 提前标记退出全屏状态与动画状态
    self.isInFullscreen = NO;
    self.isAnimating = YES;

    UIView *originalSuperview = self.originalSuperview;
    if (!originalSuperview) {
        // 原始父视图已释放，直接清理
        [self cleanupFullscreenWindow];
        self.isAnimating = NO;
        if (completion) {
            completion();
        }
        return;
    }

    // ========== Phase 1：触发系统旋转至竖屏，在旋转动画中同步缩小 playerView ==========
    playerView.autoresizingMask = UIViewAutoresizingNone;

    __weak typeof(self) weakSelf = self;
    __block BOOL completed = NO;

    self.fullscreenViewController.rotationHandler = ^(CGSize targetSize,
                                                       id<UIViewControllerTransitionCoordinator> coordinator) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                playerView.frame = [strongSelf fullscreenTargetFrameForPlayerView:playerView];
            }
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            if (completed) { return; }
            completed = YES;
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                if (completion) {
                    completion();
                }
                return;
            }

            // ========== Phase 2：还原至原始父视图 ==========
            [strongSelf restorePlayerViewToOriginalSuperview:playerView];

            [strongSelf cleanupFullscreenWindow];
            strongSelf.isAnimating = NO;
            if (completion) {
                completion();
            }
        }];
    };

    [self.fullscreenViewController unlockOrientation];
    [self restoreOrientation];

    // 回退：设备已竖屏或系统未触发旋转时，手动缩小至原始位置
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (completed) { return; }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.fullscreenViewController.rotationHandler) {
            return;
        }
        completed = YES;
        strongSelf.fullscreenViewController.rotationHandler = nil;
        NSTimeInterval duration = animated ? kFullscreenAnimationDuration : 0;
        [UIView animateWithDuration:duration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            playerView.frame = [strongSelf fullscreenTargetFrameForPlayerView:playerView];
        } completion:^(BOOL finished) {
            [strongSelf restorePlayerViewToOriginalSuperview:playerView];

            [strongSelf cleanupFullscreenWindow];
            strongSelf.isAnimating = NO;
            if (completion) {
                completion();
            }
        }];
    });
}

#pragma mark - Private

- (BOOL)window:(UIWindow *)window sharesSceneWithWindow:(UIWindow *)otherWindow {
    if (!window || !otherWindow || window.screen != otherWindow.screen) {
        return NO;
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        return window.windowScene == otherWindow.windowScene;
    }
#endif
    return YES;
}

- (void)ensureFullscreenWindowForSourceWindow:(UIWindow *)sourceWindow {
    if (self.fullscreenWindow && ![self window:self.fullscreenWindow sharesSceneWithWindow:sourceWindow]) {
        // 来源 scene 已改变时，不复用旧 scene 的窗口。
        self.fullscreenWindow = nil;
        self.fullscreenViewController = nil;
    }
    if (!self.fullscreenWindow) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
        if (@available(iOS 13.0, *)) {
            if (sourceWindow.windowScene) {
                self.fullscreenWindow = [[UIWindow alloc] initWithWindowScene:sourceWindow.windowScene];
            }
        }
#endif
        if (!self.fullscreenWindow) {
            // iOS 9–12 或未采用 scene 的宿主，仅使用明确来源窗口的屏幕。
            self.fullscreenWindow = [[UIWindow alloc] initWithFrame:sourceWindow.screen.bounds];
            self.fullscreenWindow.screen = sourceWindow.screen;
        }
        self.fullscreenWindow.windowLevel = UIWindowLevelNormal + 1;
        self.fullscreenWindow.backgroundColor = [UIColor blackColor];
        self.fullscreenWindow.hidden = YES;
    }
    if (!self.fullscreenViewController) {
        self.fullscreenViewController = [[FullscreenViewController alloc] init];
        self.fullscreenWindow.rootViewController = self.fullscreenViewController;
    }
}

- (UIWindow *)keyWindowForSourceWindow:(UIWindow *)sourceWindow {
    if (sourceWindow.isKeyWindow) {
        return sourceWindow;
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
        if (sourceWindow.windowScene) {
            for (UIWindow *window in sourceWindow.windowScene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
            return nil;
        }
    }
#endif
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow && [self window:window sharesSceneWithWindow:sourceWindow]) {
            return window;
        }
    }
    return nil;
}

- (CGRect)originalFrameForRestoration {
    UIView *originalSuperview = self.originalSuperview;
    [originalSuperview layoutIfNeeded];
    if (originalSuperview && self.originalPlaceholderView.superview == originalSuperview) {
        return self.originalPlaceholderView.frame;
    }
    return self.originalFrame;
}

- (CGRect)fullscreenTargetFrameForPlayerView:(AliPlayerView *)playerView {
    CGRect frame = [self originalFrameForRestoration];
    UIView *originalSuperview = self.originalSuperview;
    UIWindow *sourceWindow = originalSuperview.window;
    if (![self window:sourceWindow sharesSceneWithWindow:self.fullscreenWindow]) {
        // 宿主已脱离窗口或迁往其他 scene 时，不执行跨 scene 的退出坐标转换。
        return playerView.frame;
    }
    CGRect rectInSourceWindow = [originalSuperview convertRect:frame toView:sourceWindow];
    CGRect rectInFullscreenWindow = [self.fullscreenWindow convertRect:rectInSourceWindow fromWindow:sourceWindow];
    return [self.fullscreenViewController.view convertRect:rectInFullscreenWindow fromView:self.fullscreenWindow];
}

- (void)restorePlayerViewToOriginalSuperview:(AliPlayerView *)playerView {
    UIView *originalSuperview = self.originalSuperview;
    if (!originalSuperview) {
        return;
    }
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    // 原父视图可能已调整尺寸，迁回前重新读取占位 frame。
    CGRect frame = [self originalFrameForRestoration];
    NSInteger index = self.originalIndex;
    if (index >= 0 && index <= (NSInteger)originalSuperview.subviews.count) {
        [originalSuperview insertSubview:playerView atIndex:index];
    } else {
        [originalSuperview addSubview:playerView];
    }
    playerView.frame = frame;
    playerView.autoresizingMask = self.originalAutoresizingMask;
    [self.originalPlaceholderView removeFromSuperview];
    self.originalPlaceholderView = nil;
    // 占位视图不能推导宿主的手动布局，迁回后请求宿主重新布局。
    [originalSuperview setNeedsLayout];
    [originalSuperview layoutIfNeeded];
    [CATransaction commit];
}

// 清理全屏窗口（保留 fullscreenWindow 实例以供同 scene 复用）
- (void)cleanupFullscreenWindow {
    self.fullscreenViewController.rotationHandler = nil;
    if (self.fullscreenViewController) {
        [self restoreOrientation];
    }
    // 仅在全屏窗口仍为 keyWindow 时恢复原窗口，保留宿主主动切换。
    UIWindow *sourceKeyWindow = self.sourceKeyWindow;
    if (self.fullscreenWindow.isKeyWindow && sourceKeyWindow && !sourceKeyWindow.hidden
        && [self window:sourceKeyWindow sharesSceneWithWindow:self.fullscreenWindow]) {
        [sourceKeyWindow makeKeyWindow];
    }
    self.fullscreenWindow.hidden = YES;
    self.fullscreenWindow.rootViewController = nil;
    self.fullscreenViewController = nil;
    [self.originalPlaceholderView removeFromSuperview];
    self.originalPlaceholderView = nil;
    self.originalSuperview = nil;
    self.sourceWindow = nil;
    self.sourceKeyWindow = nil;
}

// 还原系统方向为竖屏，撤销 triggerOrientationUpdate 设置的横屏偏好
- (void)restoreOrientation {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000
    if (@available(iOS 16.0, *)) {
        UIWindowScene *scene = self.fullscreenWindow.windowScene;
        if (scene) {
            UIWindowSceneGeometryPreferencesIOS *prefs = [[UIWindowSceneGeometryPreferencesIOS alloc]
                initWithInterfaceOrientations:UIInterfaceOrientationMaskPortrait];
            [scene requestGeometryUpdateWithPreferences:prefs errorHandler:nil];
        }
        return;
    }
#endif
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
    [UIViewController attemptRotationToDeviceOrientation];
}

// 仅使用视图窗口或已记录的来源窗口，不跨 scene 搜索。
- (UIWindow *)sourceWindowForView:(nullable UIView *)view {
    UIWindow *window = view.window;
    if (window && window != self.fullscreenWindow) {
        return window;
    }
    return self.sourceWindow;
}

// 触发系统旋转更新
- (void)triggerOrientationUpdate {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000
    if (@available(iOS 16.0, *)) {
        UIWindowScene *scene = self.fullscreenWindow.windowScene;
        if (scene) {
            UIWindowSceneGeometryPreferencesIOS *prefs = [[UIWindowSceneGeometryPreferencesIOS alloc]
                initWithInterfaceOrientations:UIInterfaceOrientationMaskLandscape];
            [scene requestGeometryUpdateWithPreferences:prefs errorHandler:nil];
        }
        [self.fullscreenViewController setNeedsUpdateOfSupportedInterfaceOrientations];
        return;
    }
#endif
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeRight) forKey:@"orientation"];
    [UIViewController attemptRotationToDeviceOrientation];
}

@end
