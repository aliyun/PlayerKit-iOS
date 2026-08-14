//
//  AliPlayerView.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "AliPlayerView.h"
#import "AliPlayerController.h"
#import "AliPlayerController+Private.h"
#import "AliPlayerModel.h"
#import "DefaultFullscreenTransition.h"
#import "SlotManager.h"
#import "SlotManager+Private.h"
#import "SlotHostLayout.h"
#import "PlayerViewState.h"
#import "Log.h"

@interface AliPlayerView ()

@property (nonatomic, weak, readwrite, nullable) AliPlayerController *controller;
@property (nonatomic, strong, nullable) SlotHostLayout *slotHostLayout;
@property (nonatomic, strong, readwrite) SlotManager *slotManager;
@property (nonatomic, strong, readwrite) PlayerViewState *viewState;
@property (nonatomic, assign) BOOL screenshotDisabled;
@property (nonatomic, strong, nullable) UIView *screenshotOverlay;
@property (nonatomic, assign) BOOL originalIdleTimerDisabled;
@property (nonatomic, assign) BOOL originalIdleTimerSaved;

@end

@implementation AliPlayerView

@synthesize fullscreenTransition = _fullscreenTransition;
@synthesize onBackPressed = _onBackPressed;

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _slotManager = [[SlotManager alloc] initInternal];
        _viewState = [[PlayerViewState alloc] init];

        SLOGI(@"[LC][init] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
    }
    return self;
}

- (void)dealloc {
    [self detach];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SLOGI(@"[LC][dealloc] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.slotHostLayout.frame = self.bounds;
}

#pragma mark - Public Methods

- (id<FullscreenTransition>)fullscreenTransition {
    if (!_fullscreenTransition) {
        _fullscreenTransition = [[DefaultFullscreenTransition alloc] init];
    }
    return _fullscreenTransition;
}

- (void)setFullscreenTransition:(id<FullscreenTransition>)fullscreenTransition {
    _fullscreenTransition = fullscreenTransition;
}

- (void)setOnBackPressed:(void (^)(void))onBackPressed {
    _onBackPressed = [onBackPressed copy];
    [self syncBackPressedHandler];
}

- (void)attach:(AliPlayerController *)controller {
    [self detach];
    self.controller = controller;

    controller.playerView = self;

    AliPlayerModel *model = controller.playerModel;

    if (model) {
        if (!self.slotHostLayout) {
            self.slotHostLayout = [[SlotHostLayout alloc] initWithFrame:self.bounds];
            self.slotHostLayout.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:self.slotHostLayout];
        }

        // 先配置 sceneType（此时 slotManager 尚为 nil，setter 不触发 rebuild）
        self.slotHostLayout.sceneType = model.sceneType;

        [self.slotHostLayout bindSlotManager:self.slotManager];

        // 如果外部已设置 onBackPressed，同步到 SlotHostLayout
        [self syncBackPressedHandler];

        [self.slotHostLayout bindController:controller];

        [self.slotHostLayout rebuildSlots];
        [self.slotHostLayout bindData:model];

        [self updateIdleTimerState:model];
        [self updateScreenshotDisabledState:model.disableScreenshot];
    }
}

- (void)detach {
    [self updateScreenshotDisabledState:NO];

    if (self.controller) {
        self.controller.playerView = nil;
    }

    if (self.slotHostLayout) {
        [self.slotHostLayout unbind];
    }
    self.controller = nil;

    [UIApplication sharedApplication].idleTimerDisabled = self.originalIdleTimerDisabled;
    self.originalIdleTimerSaved = NO;
}

#pragma mark - Private Methods

// 同步 onBackPressed 状态到 SlotHostLayout
- (void)syncBackPressedHandler {
    if (!self.slotHostLayout) return;
    if (self.onBackPressed) {
        __weak typeof(self) weakSelf = self;
        self.slotHostLayout.backPressedHandler = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.onBackPressed) {
                strongSelf.onBackPressed();
            }
        };
    } else {
        self.slotHostLayout.backPressedHandler = nil;
    }
}

- (void)updateIdleTimerState:(AliPlayerModel *)model {
    if (!self.originalIdleTimerSaved) {
        self.originalIdleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
        self.originalIdleTimerSaved = YES;
    }
    BOOL disableIdle = !model.allowScreenSleep;
    [UIApplication sharedApplication].idleTimerDisabled = disableIdle;
    SLOGI(@"Idle timer disabled: %@ (allowScreenSleep=%@)",
          disableIdle ? @"YES" : @"NO",
          model.allowScreenSleep ? @"YES" : @"NO");
}

// 监听录屏状态变化，录屏/投屏时覆盖黑色遮罩
- (void)updateScreenshotDisabledState:(BOOL)enabled {
    if (enabled == self.screenshotDisabled) return;
    self.screenshotDisabled = enabled;

    if (enabled) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(screenCapturedDidChange)
                                                     name:UIScreenCapturedDidChangeNotification
                                                   object:nil];
        [self updateScreenshotOverlay];
        SLOGI(@"Screenshot protection enabled");
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIScreenCapturedDidChangeNotification
                                                      object:nil];
        [self removeScreenshotOverlay];
        SLOGI(@"Screenshot protection disabled");
    }
}

- (void)screenCapturedDidChange {
    [self updateScreenshotOverlay];
}

// 录屏/投屏进行中时覆盖黑色遮罩，结束后移除
- (void)updateScreenshotOverlay {
    if (UIScreen.mainScreen.isCaptured) {
        if (!self.screenshotOverlay) {
            self.screenshotOverlay = [[UIView alloc] initWithFrame:self.bounds];
            self.screenshotOverlay.backgroundColor = [UIColor blackColor];
            self.screenshotOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.screenshotOverlay.userInteractionEnabled = NO;
            [self addSubview:self.screenshotOverlay];
        }
        [self bringSubviewToFront:self.screenshotOverlay];
        SLOGI(@"Screen is being captured, overlay shown");
    } else {
        [self removeScreenshotOverlay];
    }
}

- (void)removeScreenshotOverlay {
    if (self.screenshotOverlay) {
        [self.screenshotOverlay removeFromSuperview];
        self.screenshotOverlay = nil;
        SLOGI(@"Screen capture ended, overlay removed");
    }
}

@end
