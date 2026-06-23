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
// 全屏窗口（懒创建，预先初始化但保持隐藏，避免每次进全屏时的创建开销）
@property (nonatomic, strong, nullable) UIWindow *fullscreenWindow;
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

- (instancetype)init {
    self = [super init];
    if (self) {
        // 预创建全屏窗口（隐藏状态），避免首次进全屏时的创建开销
        [self ensureFullscreenWindow];
    }
    return self;
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

    // 提前标记全屏状态与动画状态，防止快速切换时的重入
    self.isInFullscreen = YES;
    self.isAnimating = YES;

    // ========== Phase 1：迁入全屏窗口（保持原始位置，无 transform）==========
    self.originalSuperview = playerView.superview;
    self.originalFrame = playerView.frame;
    self.originalAutoresizingMask = playerView.autoresizingMask;
    self.originalIndex = [playerView.superview.subviews indexOfObject:playerView];

    CGRect rectInScreen = [playerView.superview convertRect:playerView.frame toView:nil];

    [self ensureFullscreenWindow];

    // 将 playerView 直接迁入 fullscreenWindow（VC 初始支持所有方向，窗口保持竖屏）
    // CATransaction 确保 reparent + 显示窗口在同一帧提交，无视觉闪烁
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    playerView.autoresizingMask = UIViewAutoresizingNone;
    [self.fullscreenViewController.view addSubview:playerView];
    playerView.frame = rectInScreen;
    self.fullscreenWindow.hidden = NO;
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
    CGRect targetRectInScreen = [originalSuperview convertRect:self.originalFrame toView:nil];

    playerView.autoresizingMask = UIViewAutoresizingNone;

    __weak typeof(self) weakSelf = self;
    __block BOOL completed = NO;

    self.fullscreenViewController.rotationHandler = ^(CGSize targetSize,
                                                       id<UIViewControllerTransitionCoordinator> coordinator) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            playerView.frame = targetRectInScreen;
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
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            NSInteger index = strongSelf.originalIndex;
            if (index >= 0 && index <= (NSInteger)originalSuperview.subviews.count) {
                [originalSuperview insertSubview:playerView atIndex:(NSInteger)index];
            } else {
                [originalSuperview addSubview:playerView];
            }
            playerView.frame = strongSelf.originalFrame;
            playerView.autoresizingMask = strongSelf.originalAutoresizingMask;
            [CATransaction commit];

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
            playerView.frame = targetRectInScreen;
        } completion:^(BOOL finished) {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            NSInteger index = strongSelf.originalIndex;
            if (index >= 0 && index <= (NSInteger)originalSuperview.subviews.count) {
                [originalSuperview insertSubview:playerView atIndex:(NSInteger)index];
            } else {
                [originalSuperview addSubview:playerView];
            }
            playerView.frame = strongSelf.originalFrame;
            playerView.autoresizingMask = strongSelf.originalAutoresizingMask;
            [CATransaction commit];

            [strongSelf cleanupFullscreenWindow];
            strongSelf.isAnimating = NO;
            if (completion) {
                completion();
            }
        }];
    });
}

#pragma mark - Private

- (void)ensureFullscreenWindow {
    if (!self.fullscreenWindow) {
        if (@available(iOS 13.0, *)) {
            UIWindowScene *scene = [self activeWindowScene];
            if (scene) {
                self.fullscreenWindow = [[UIWindow alloc] initWithWindowScene:scene];
            } else {
                self.fullscreenWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            }
        } else {
            self.fullscreenWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
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

- (UIWindowScene *)activeWindowScene API_AVAILABLE(ios(13.0)) {
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            return scene;
        }
    }
    return nil;
}

// 清理全屏窗口（保留 fullscreenWindow 实例以供复用）
- (void)cleanupFullscreenWindow {
    self.fullscreenViewController.rotationHandler = nil;
    [self restoreOrientation];
    self.fullscreenWindow.hidden = YES;
    self.fullscreenWindow.rootViewController = nil;
    self.fullscreenViewController = nil;
}

// 还原系统方向为竖屏，撤销 triggerOrientationUpdate 设置的横屏偏好
- (void)restoreOrientation {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000
    if (@available(iOS 16.0, *)) {
        UIWindowScene *scene = self.fullscreenWindow.windowScene;
        if (!scene) {
            scene = [self activeWindowScene];
        }
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

// 获取 view 所在的 sourceWindow，优先使用 view.window，回退到 App 主窗口
- (UIWindow *)sourceWindowForView:(nullable UIView *)view {
    UIWindow *window = view.window;
    if (window && window != self.fullscreenWindow) {
        return window;
    }
    // 回退：通过 AppDelegate 获取主窗口
    id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
    if (appDelegate && [appDelegate respondsToSelector:@selector(window)]) {
        UIWindow *appWindow = [appDelegate window];
        if (appWindow) {
            return appWindow;
        }
    }
    // 再回退：遍历 application.windows 取第一个非全屏窗口
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w != self.fullscreenWindow && !w.hidden) {
            return w;
        }
    }
    return [UIApplication sharedApplication].keyWindow;
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
