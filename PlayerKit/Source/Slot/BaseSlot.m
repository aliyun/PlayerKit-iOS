//
//  BaseSlot.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseSlot.h"
#import "AliPlayerController.h"
#import "PlayerNotificationDelegate.h"
#import "SlotActionNotificationDispatcher.h"
#import "SlotActionNotificationDelegate.h"
#import "SlotManager.h"
#import "Log.h"

#pragma mark - Slot Debug Log

#define SLOT_LOG_ENABLED 0  // ← 改为 1 开启插槽调试日志

#if SLOT_LOG_ENABLED
#define SLOT_LOG(fmt, ...) SLOGI(fmt, ##__VA_ARGS__)
#else
#define SLOT_LOG(fmt, ...) ((void)0)
#endif

#pragma mark - Slot 通用时序常量

const NSTimeInterval SlotAutoHideDelay = 3.0;

#pragma mark - Animation Defaults

static const NSTimeInterval kAnimationDuration = 0.25;
static const UIViewAnimationOptions kAnimationOptions = UIViewAnimationOptionCurveEaseInOut;
static const CGFloat kAlphaVisible = 1.0;
static const CGFloat kAlphaHidden = 0.0;

@interface BaseSlot ()

@property (nonatomic, weak, readwrite, nullable) id<SlotHost> host;
@property (nonatomic, assign, readwrite) BOOL contentReady;

@end

@implementation BaseSlot

// ==================== 插槽生命周期 ====================
//
// 标准流程：
//   init → onAttach: → setupContentView → onBindData: → ... → onUnbindData → onDetach → dealloc
//
// 延迟创建（deferContentCreation = YES）：
//   init → onAttach:(hidden) → ... → show/ensureContentReady → setupContentView → onBindData:(回放) → ... → onUnbindData → onDetach → dealloc
//
// 契约：子类的 onBindData: / onUnbindData 被回调时 contentReady 必然为 YES。
//   - 数据驱动路径：SlotHostLayout.bindData: 对 deferContentCreation && !contentReady 的 slot 做外层 continue 守卫。
//   - 显示驱动路径：ensureContentReady 在 self.contentReady = YES 之后才回放 onBindData:。
// 因此子类无需在 onBindData: 内再做 contentReady 兜底，直接处理数据即可。
//
// 资源管理：
//   onAttach:  — 保存 host（weak），注册 PlayerNotificationDelegate
//   onDetach   — 注销 PlayerNotificationDelegate 与 SlotActionNotificationDelegate，置空 host
//   dismiss    — 委托 host 统一管理解除挂载和视图移除；无 host 时直接执行清理
//
// ==================== End ====================

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        _touchPassthrough = YES;
        _safeAreaEdges = SlotSafeAreaEdgeAll;
        SLOT_LOG(@"[LC][init] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
    }
    return self;
}

- (void)dealloc {
    SLOT_LOG(@"[LC][dealloc] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
}

#pragma mark - Slot Protocol

/// 挂载到宿主：保存引用 → 注册通知 → 创建内容（或延迟）
- (void)onAttach:(id<SlotHost>)host {
    self.host = host;
    if ([self conformsToProtocol:@protocol(PlayerNotificationDelegate)]) {
        AliPlayerController *controller = host.controller;
        if (controller) {
            [controller addNotificationDelegate:(id<PlayerNotificationDelegate>)self];
        }
    }
    if (self.deferContentCreation) {
        self.hidden = YES;
    } else {
        [self setupContentView];
        self.contentReady = YES;
    }
    SLOT_LOG(@"[onAttach] <%@: %p> defer=%@", NSStringFromClass([self class]), self, self.deferContentCreation ? @"YES" : @"NO");
}

/// 从宿主分离：注销通知 → 置空引用（子类重写时须调用 super）
- (void)onDetach {
    SLOT_LOG(@"[onDetach] <%@: %p>", NSStringFromClass([self class]), self);
    if ([self conformsToProtocol:@protocol(PlayerNotificationDelegate)]) {
        AliPlayerController *controller = self.host.controller;
        if (controller) {
            [controller removeNotificationDelegate:(id<PlayerNotificationDelegate>)self];
        }
    }
    // 置空即触发下面的 setter，完成 SlotActionNotificationDelegate 注销
    self.slotActionDispatcher = nil;
    self.host = nil;
}

#pragma mark - Slot Action Notification

/// 切换分发器：从旧的注销 → 保存 → 向新的注册（仅当自身遵循 delegate 协议）
- (void)setSlotActionDispatcher:(SlotActionNotificationDispatcher *)slotActionDispatcher {
    if (_slotActionDispatcher == slotActionDispatcher) {
        return;
    }
    BOOL isObserver = [self conformsToProtocol:@protocol(SlotActionNotificationDelegate)];
    if (_slotActionDispatcher && isObserver) {
        [_slotActionDispatcher removeObserver:(id<SlotActionNotificationDelegate>)self];
    }
    _slotActionDispatcher = slotActionDispatcher;
    if (_slotActionDispatcher && isObserver) {
        [_slotActionDispatcher addObserver:(id<SlotActionNotificationDelegate>)self];
        SLOT_LOG(@"[setSlotActionDispatcher] <%@: %p> registered as observer", NSStringFromClass([self class]), self);
    }
}

- (void)onBindData:(AliPlayerModel *)model {
    // 子类重写以响应数据绑定
    SLOT_LOG(@"[onBindData] <%@: %p>", NSStringFromClass([self class]), self);
}

- (void)onUnbindData {
    // 子类重写以响应数据解绑，将 UI 重置为默认状态
    SLOT_LOG(@"[onUnbindData] <%@: %p>", NSStringFromClass([self class]), self);
}

#pragma mark - Public Methods

- (void)setupContentView {
    // Default empty implementation for subclasses to override
}

- (NSUInteger)onRegisterElements {
    return 0;
}

- (BOOL)isElementVisible:(NSUInteger)element {
    NSUInteger hidden = [self.host.slotManager hiddenElementMaskForSlot:self.slotType];
    NSUInteger shown = [self.host.slotManager shownElementMaskForSlot:self.slotType];
    if (hidden & element) return NO;
    if (shown & element) return YES;
    return ([self onRegisterElements] & element) != 0;
}

- (SceneType)currentSceneType {
    NSAssert(self.host != nil, @"[%@] currentSceneType called before onAttach:", NSStringFromClass([self class]));
    if (!self.host) {
        SLOGW(@"[%@] currentSceneType called before onAttach:, returning SceneTypeVOD as fallback", NSStringFromClass([self class]));
        return SceneTypeVOD;
    }
    return self.host.sceneType;
}

/// 延迟创建的触发点：首次调用时执行 setupContentView 并回放 onBindData:（幂等）
- (void)ensureContentReady {
    if (self.contentReady) {
        return;
    }
    SLOT_LOG(@"[ensureContentReady] <%@: %p>", NSStringFromClass([self class]), self);
    self.contentReady = YES;
    [self setupContentView];

    id<SlotHost> host = self.host;
    if (host && host.model) {
        [self onBindData:host.model];
    }
}

- (void)show {
    [self ensureContentReady];
    self.hidden = NO;
}

- (void)hide {
    self.hidden = YES;
}

- (BOOL)isShowing {
    return !self.hidden;
}

/// 移除插槽：优先委托 host 统一管理（onDetach + removeFromSuperview），无 host 时直接兜底清理
- (void)dismiss {
    SLOT_LOG(@"[dismiss] <%@: %p> host=%@", NSStringFromClass([self class]), self, self.host ? @"YES" : @"nil");
    id<SlotHost> host = self.host;
    if (host) {
        // Delegate to host for unified management (ensures slotViews dict stays in sync)
        [host dismissSlotView:self];
    } else {
        // No host fallback: direct cleanup
        [self onDetach];
        [self removeFromSuperview];
    }
}

- (void)showWithAnimation:(BOOL)animated {
    if (!animated) {
        [self show];
        return;
    }
    [self ensureContentReady];
    self.alpha = kAlphaHidden;
    self.hidden = NO;
    [UIView animateWithDuration:kAnimationDuration
                          delay:0
                        options:kAnimationOptions
                     animations:^{
        self.alpha = kAlphaVisible;
    } completion:nil];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.touchPassthrough) {
        return [super hitTest:point withEvent:event];
    }
    UIView *hitView = [super hitTest:point withEvent:event];
    return (hitView == self) ? nil : hitView;
}

- (void)hideWithAnimation:(BOOL)animated {
    if (!animated) {
        [self hide];
        return;
    }
    [UIView animateWithDuration:kAnimationDuration
                          delay:0
                        options:kAnimationOptions
                     animations:^{
        self.alpha = kAlphaHidden;
    } completion:^(BOOL finished) {
        if (finished) {
            self.hidden = YES;
            self.alpha = kAlphaVisible;
        }
    }];
}

@end
