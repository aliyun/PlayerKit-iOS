//
//  GestureControlSlot.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "GestureControlSlot.h"
#import "GestureNotificationDispatcher.h"
#import "GestureNotificationDelegate.h"
#import "AliPlayerModel.h"
#import "AliPlayerController.h"
#import "PlayerStateStore.h"
#import "PlayerViewState.h"
#import "SceneType.h"
#import "SlotElements.h"
#import "Log.h"
#import <MediaPlayer/MediaPlayer.h>

#pragma mark - GestureControlSlotConfig

@implementation GestureControlSlotConfig

+ (instancetype)defaultConfig {
    GestureControlSlotConfig *config = [[GestureControlSlotConfig alloc] init];
    config.singleTapEnabled = YES;
    config.doubleTapEnabled = YES;
    config.longPressEnabled = YES;
    config.horizontalDragEnabled = YES;
    config.leftVerticalDragEnabled = YES;
    config.rightVerticalDragEnabled = YES;
    return config;
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    GestureControlSlotConfig *copy = [[GestureControlSlotConfig alloc] init];
    copy.singleTapEnabled = self.singleTapEnabled;
    copy.doubleTapEnabled = self.doubleTapEnabled;
    copy.longPressEnabled = self.longPressEnabled;
    copy.horizontalDragEnabled = self.horizontalDragEnabled;
    copy.leftVerticalDragEnabled = self.leftVerticalDragEnabled;
    copy.rightVerticalDragEnabled = self.rightVerticalDragEnabled;
    return copy;
}

@end

#pragma mark - Constants

static const CGFloat kMinHorizontalDistance = 20.0;
static const CGFloat kMinVerticalDistance = 20.0;
static const CGFloat kMinUpdatePercent = 0.01;
static const CGFloat kBrightnessSensitivity = 2.0;
static const CGFloat kVolumeSensitivity = 2.0;
static const float kLongPressSpeed = 2.0f;
static const float kNormalSpeed = 1.0f;

#pragma mark - Gesture State

typedef NS_ENUM(NSInteger, GestureState) {
    GestureStateNone = 0,
    GestureStateHorizontal,
    GestureStateVerticalLeft,
    GestureStateVerticalRight,
    GestureStateLongPressing,
};

#pragma mark - DragTracker

@interface DragTracker : NSObject

- (void)startWithPosition:(CGFloat)startPos;
- (CGFloat)updateWithPosition:(CGFloat)currentPos totalSize:(CGFloat)totalSize;

@end

@implementation DragTracker {
    CGFloat _lastPos;
    CGFloat _accumulatedDelta;
}

- (void)startWithPosition:(CGFloat)startPos {
    _lastPos = startPos;
    _accumulatedDelta = 0;
}

- (CGFloat)updateWithPosition:(CGFloat)currentPos totalSize:(CGFloat)totalSize {
    if (totalSize <= 0) return 0;

    CGFloat delta = currentPos - _lastPos;
    _lastPos = currentPos;
    _accumulatedDelta += delta;

    CGFloat percent = _accumulatedDelta / totalSize;
    if (fabs(percent) >= kMinUpdatePercent) {
        _accumulatedDelta = 0;
        return percent;
    }
    return 0;
}

@end

#pragma mark - GestureControlSlot

@interface GestureControlSlot () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UITapGestureRecognizer *singleTapRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *edgePanRecognizer;

@property (nonatomic, assign) GestureState gestureState;
@property (nonatomic, assign) CGPoint dragStartPoint;

@property (nonatomic, strong) DragTracker *horizontalTracker;
@property (nonatomic, strong) DragTracker *verticalTracker;

@property (nonatomic, assign) CGFloat currentBrightness;
@property (nonatomic, assign) CGFloat currentVolumePercent;

// 长按前的播放速度，松手后恢复
@property (nonatomic, assign) float speedBeforeLongPress;

// Seek 跟踪
@property (nonatomic, assign) NSInteger seekBasePosition;
@property (nonatomic, assign) CGFloat accumulatedSeekPercent;

// 系统音量滑块（通过隐藏的 MPVolumeView 获取）
@property (nonatomic, weak) UISlider *systemVolumeSlider;

@property (nonatomic, strong) UIImpactFeedbackGenerator *lightFeedback API_AVAILABLE(ios(10.0));
@property (nonatomic, strong) UIImpactFeedbackGenerator *mediumFeedback API_AVAILABLE(ios(10.0));

@end

#pragma mark - Haptic Feedback

static inline void TriggerLightFeedback(GestureControlSlot *slot) {
    if (@available(iOS 10.0, *)) {
        [slot.lightFeedback impactOccurred];
    }
}

static inline void TriggerMediumFeedback(GestureControlSlot *slot) {
    if (@available(iOS 10.0, *)) {
        [slot.mediumFeedback impactOccurred];
    }
}

@implementation GestureControlSlot

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _config = [GestureControlSlotConfig defaultConfig];
        _gestureState = GestureStateNone;
        _horizontalTracker = [[DragTracker alloc] init];
        _verticalTracker = [[DragTracker alloc] init];
        _gestureDispatcher = [[GestureNotificationDispatcher alloc] init];
    }
    return self;
}

#pragma mark - Config

- (void)setConfig:(GestureControlSlotConfig *)config {
    _config = config ? [config copy] : [GestureControlSlotConfig defaultConfig];
}

#pragma mark - Slot Lifecycle

- (NSUInteger)onRegisterElements {
    return GestureElementSingleTap | GestureElementDoubleTap | GestureElementLongPress
         | GestureElementHorizontalDrag | GestureElementLeftVerticalDrag | GestureElementRightVerticalDrag;
}

- (void)setupContentView {
    self.touchPassthrough = NO;

    if (![self isElementVisible:GestureElementSingleTap]) {
        self.config.singleTapEnabled = NO;
    }
    if (![self isElementVisible:GestureElementDoubleTap]) {
        self.config.doubleTapEnabled = NO;
    }
    if (![self isElementVisible:GestureElementLongPress]) {
        self.config.longPressEnabled = NO;
    }
    if (![self isElementVisible:GestureElementHorizontalDrag]) {
        self.config.horizontalDragEnabled = NO;
    }
    if (![self isElementVisible:GestureElementLeftVerticalDrag]) {
        self.config.leftVerticalDragEnabled = NO;
    }
    if (![self isElementVisible:GestureElementRightVerticalDrag]) {
        self.config.rightVerticalDragEnabled = NO;
    }

    [self setupGestureRecognizers];
    [self setupVolumeControl];
    if (@available(iOS 10.0, *)) {
        self.lightFeedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        self.mediumFeedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    }
    SLOGI(@"Gesture recognizers configured");
}

- (void)onBindData:(AliPlayerModel *)model {
    [super onBindData:model];
}

- (void)onUnbindData {
    self.gestureState = GestureStateNone;
    self.currentBrightness = 0;
    self.currentVolumePercent = 0;
    self.seekBasePosition = 0;
    self.accumulatedSeekPercent = 0;
    [super onUnbindData];
}

- (void)onDetach {
    [self removeGestureRecognizers];
    [super onDetach];
}

#pragma mark - Private Methods

#pragma mark - Volume Control Setup

- (void)setupVolumeControl {
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-1000, -1000, 1, 1)];
    volumeView.clipsToBounds = YES;
    [self addSubview:volumeView];

    for (UIView *subview in volumeView.subviews) {
        if ([subview isKindOfClass:[UISlider class]]) {
            self.systemVolumeSlider = (UISlider *)subview;
            break;
        }
    }

    if (!self.systemVolumeSlider) {
        SLOGW(@"System volume slider not found in MPVolumeView, volume gesture will be unavailable");
    }
}

#pragma mark - Gesture Recognizer Setup

- (void)setupGestureRecognizers {
    // 双击（需在单击之前添加，以建立依赖关系）
    self.doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    self.doubleTapRecognizer.numberOfTapsRequired = 2;
    self.doubleTapRecognizer.delegate = self;
    [self addGestureRecognizer:self.doubleTapRecognizer];

    // 单击（需要双击失败后才触发）
    self.singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    self.singleTapRecognizer.numberOfTapsRequired = 1;
    self.singleTapRecognizer.delegate = self;
    [self.singleTapRecognizer requireGestureRecognizerToFail:self.doubleTapRecognizer];
    [self addGestureRecognizer:self.singleTapRecognizer];

    // 长按
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    self.longPressRecognizer.delegate = self;
    [self addGestureRecognizer:self.longPressRecognizer];

    // 左边缘滑动（返回）
    self.edgePanRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleEdgePan:)];
    self.edgePanRecognizer.edges = UIRectEdgeLeft;
    self.edgePanRecognizer.delegate = self;
    [self addGestureRecognizer:self.edgePanRecognizer];

    // 拖动（水平和垂直方向）
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.panRecognizer.delegate = self;
    [self.panRecognizer requireGestureRecognizerToFail:self.edgePanRecognizer];
    [self addGestureRecognizer:self.panRecognizer];
}

- (void)removeGestureRecognizers {
    if (self.singleTapRecognizer) {
        [self removeGestureRecognizer:self.singleTapRecognizer];
        self.singleTapRecognizer = nil;
    }
    if (self.doubleTapRecognizer) {
        [self removeGestureRecognizer:self.doubleTapRecognizer];
        self.doubleTapRecognizer = nil;
    }
    if (self.longPressRecognizer) {
        [self removeGestureRecognizer:self.longPressRecognizer];
        self.longPressRecognizer = nil;
    }
    if (self.edgePanRecognizer) {
        [self removeGestureRecognizer:self.edgePanRecognizer];
        self.edgePanRecognizer = nil;
    }
    if (self.panRecognizer) {
        [self removeGestureRecognizer:self.panRecognizer];
        self.panRecognizer = nil;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    // 对 pan / singleTap / doubleTap 手势做让步判断，避免与其他 Slot 的 UIControl 或带手势的视图争夺触摸事件
    if (gestureRecognizer == self.panRecognizer ||
        gestureRecognizer == self.singleTapRecognizer ||
        gestureRecognizer == self.doubleTapRecognizer) {
        CGPoint point = [gestureRecognizer locationInView:self];
        UIView *superview = self.superview;
        if (superview) {
            CGPoint pointInSuper = [self convertPoint:point toView:superview];
            UIView *hitView = [superview hitTest:pointInSuper withEvent:nil];
            if (hitView && hitView != self) {
                // UIControl（UIButton / UISlider 等）优先响应
                if ([hitView isKindOfClass:[UIControl class]]) {
                    return NO;
                }
                // 带有 gestureRecognizers 且允许交互的视图优先响应
                if (hitView.userInteractionEnabled && hitView.gestureRecognizers.count > 0) {
                    return NO;
                }
            }
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer == self.edgePanRecognizer && otherGestureRecognizer == self.panRecognizer) {
        return YES;
    }
    return NO;
}

#pragma mark - Single Tap (Toggle Control Panel)

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    if ([self currentSceneType] == SceneTypeMinimal) return;
    if (!self.config.singleTapEnabled) return;

    CGPoint point = [recognizer locationInView:self];
    SLOGI(@"Single tap at (%.0f, %.0f)", point.x, point.y);

    id<GestureControlSlotDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(gestureControlSlot:didDetectSingleTapAtPoint:)]) {
        [delegate gestureControlSlot:self didDetectSingleTapAtPoint:point];
    }

    AliPlayerController *controller = self.host.controller;
    BOOL newVisible = !self.host.viewState.controlsVisible;
    [controller setControlsVisible:newVisible];

    [self.gestureDispatcher notifyObservers:^(id<GestureNotificationDelegate> observer) {
        if (observer && [observer respondsToSelector:@selector(gestureDidSingleTap)]) {
            [observer gestureDidSingleTap];
        }
    }];
}

#pragma mark - Double Tap (Play/Pause Toggle)

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    if ([self currentSceneType] == SceneTypeMinimal) return;
    if (!self.config.doubleTapEnabled) return;

    CGPoint point = [recognizer locationInView:self];
    SLOGI(@"Double tap at (%.0f, %.0f)", point.x, point.y);

    // 默认行为：切换播放/暂停
    AliPlayerController *controller = self.host.controller;
    if (controller) {
        [controller toggle];
    }

    id<GestureControlSlotDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(gestureControlSlot:didDetectDoubleTapAtPoint:)]) {
        [delegate gestureControlSlot:self didDetectDoubleTapAtPoint:point];
    }
}

#pragma mark - Long Press (Speed Playback)

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if ([self currentSceneType] == SceneTypeMinimal) return;
    if ([self currentSceneType] == SceneTypeLive || [self currentSceneType] == SceneTypeRestricted) return;
    if (!self.config.longPressEnabled) return;

    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            if (self.gestureState != GestureStateNone) return;

            self.gestureState = GestureStateLongPressing;
            TriggerMediumFeedback(self);
            CGPoint point = [recognizer locationInView:self];
            SLOGI(@"Long press began at (%.0f, %.0f)", point.x, point.y);

            // 默认行为：保存当前速度并切换至快速播放
            AliPlayerController *controller = self.host.controller;
            if (controller) {
                self.speedBeforeLongPress = controller.stateStore.speed;
                [controller setRate:kLongPressSpeed];
                SLOGI(@"Long press -> speed %.1fx (was %.1fx)", kLongPressSpeed, self.speedBeforeLongPress);
            }

            id<GestureControlSlotDelegate> delegate = self.delegate;
            if (delegate && [delegate respondsToSelector:@selector(gestureControlSlot:didBeginLongPressAtPoint:)]) {
                [delegate gestureControlSlot:self didBeginLongPressAtPoint:point];
            }

            [self.gestureDispatcher notifyObservers:^(id<GestureNotificationDelegate> observer) {
                if (observer && [observer respondsToSelector:@selector(gestureDidBeginLongPress)]) {
                    [observer gestureDidBeginLongPress];
                }
            }];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (self.gestureState != GestureStateLongPressing) return;

            self.gestureState = GestureStateNone;
            TriggerLightFeedback(self);
            SLOGI(@"Long press ended");

            // 默认行为：恢复长按前的速度
            AliPlayerController *controller = self.host.controller;
            if (controller) {
                float restoreSpeed = self.speedBeforeLongPress > 0 ? self.speedBeforeLongPress : kNormalSpeed;
                [controller setRate:restoreSpeed];
                SLOGI(@"Long press end -> speed %.1fx", restoreSpeed);
            }

            id<GestureControlSlotDelegate> delegate = self.delegate;
            if (delegate && [delegate respondsToSelector:@selector(gestureControlSlotDidEndLongPress:)]) {
                [delegate gestureControlSlotDidEndLongPress:self];
            }

            [self.gestureDispatcher notifyObservers:^(id<GestureNotificationDelegate> observer) {
                if (observer && [observer respondsToSelector:@selector(gestureDidEndLongPress)]) {
                    [observer gestureDidEndLongPress];
                }
            }];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Edge Pan (Back)

- (void)handleEdgePan:(UIScreenEdgePanGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateEnded) return;

    AliPlayerController *controller = self.host.controller;
    if (self.host.viewState.isFullscreen) {
        [controller setFullscreen:NO animated:YES];
        SLOGI(@"Edge pan -> exit fullscreen");
        return;
    }

    // 通过 SlotHost 协议通知宿主处理返回事件
    [self.host notifyBackPressed];
    SLOGI(@"Edge pan -> notified host");
}

#pragma mark - Pan (Drag)

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if ([self currentSceneType] == SceneTypeMinimal) return;

    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self handlePanBegan:recognizer];
            break;
        case UIGestureRecognizerStateChanged:
            [self handlePanChanged:recognizer];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            [self handlePanEnded:recognizer];
            break;
        default:
            break;
    }
}

- (void)handlePanBegan:(UIPanGestureRecognizer *)recognizer {
    self.dragStartPoint = [recognizer locationInView:self];
    [self.horizontalTracker startWithPosition:self.dragStartPoint.x];
    [self.verticalTracker startWithPosition:self.dragStartPoint.y];
    self.gestureState = GestureStateNone;
}

- (void)handlePanChanged:(UIPanGestureRecognizer *)recognizer {
    CGPoint currentPoint = [recognizer locationInView:self];

    if (self.gestureState == GestureStateNone) {
        [self tryStartDragWithCurrentPoint:currentPoint];
    }

    switch (self.gestureState) {
        case GestureStateHorizontal:
            [self processHorizontalDragAtX:currentPoint.x];
            break;
        case GestureStateVerticalLeft:
        case GestureStateVerticalRight:
            [self processVerticalDragAtY:currentPoint.y];
            break;
        default:
            break;
    }
}

- (void)handlePanEnded:(UIPanGestureRecognizer *)recognizer {
    id<GestureControlSlotDelegate> delegate = self.delegate;

    switch (self.gestureState) {
        case GestureStateHorizontal: {
            SLOGI(@"Horizontal drag ended");

            // 默认行为：提交 Seek 操作
            AliPlayerController *controller = self.host.controller;
            if (controller && controller.duration > 0) {
                NSInteger seekPosition = self.seekBasePosition + (NSInteger)(self.accumulatedSeekPercent * controller.duration);
                seekPosition = MAX(0, MIN(seekPosition, controller.duration));
                [controller seekTo:seekPosition];
                SLOGI(@"Seek to: %ld ms", (long)seekPosition);
            }

            if (delegate && [delegate respondsToSelector:@selector(gestureControlSlotDidEndHorizontalDrag:)]) {
                [delegate gestureControlSlotDidEndHorizontalDrag:self];
            }
            break;
        }
        case GestureStateVerticalLeft:
            SLOGI(@"Left vertical drag ended");
            if (delegate && [delegate respondsToSelector:@selector(gestureControlSlotDidEndLeftVerticalDrag:)]) {
                [delegate gestureControlSlotDidEndLeftVerticalDrag:self];
            }
            [self.gestureDispatcher notifyObservers:^(id<GestureNotificationDelegate> observer) {
                if (observer && [observer respondsToSelector:@selector(gestureDidEndBrightnessAdjust)]) {
                    [observer gestureDidEndBrightnessAdjust];
                }
            }];
            break;
        case GestureStateVerticalRight:
            SLOGI(@"Right vertical drag ended");
            if (delegate && [delegate respondsToSelector:@selector(gestureControlSlotDidEndRightVerticalDrag:)]) {
                [delegate gestureControlSlotDidEndRightVerticalDrag:self];
            }
            [self.gestureDispatcher notifyObservers:^(id<GestureNotificationDelegate> observer) {
                if (observer && [observer respondsToSelector:@selector(gestureDidEndVolumeAdjust)]) {
                    [observer gestureDidEndVolumeAdjust];
                }
            }];
            break;
        default:
            break;
    }

    self.gestureState = GestureStateNone;
    self.accumulatedSeekPercent = 0;
}

#pragma mark - Drag Direction Detection

- (void)tryStartDragWithCurrentPoint:(CGPoint)currentPoint {
    CGFloat deltaX = currentPoint.x - self.dragStartPoint.x;
    CGFloat deltaY = currentPoint.y - self.dragStartPoint.y;
    CGFloat absDeltaX = fabs(deltaX);
    CGFloat absDeltaY = fabs(deltaY);

    if (absDeltaX > kMinHorizontalDistance && absDeltaX > absDeltaY) {
        if ([self currentSceneType] == SceneTypeLive || [self currentSceneType] == SceneTypeRestricted) return;
        if (!self.config.horizontalDragEnabled) return;

        self.gestureState = GestureStateHorizontal;
        TriggerLightFeedback(self);
        self.seekBasePosition = self.host.controller.currentPosition;
        self.accumulatedSeekPercent = 0;
        SLOGI(@"Horizontal drag started (base position: %ld ms)", (long)self.seekBasePosition);

        id<GestureControlSlotDelegate> delegate = self.delegate;
        if (delegate && [delegate respondsToSelector:@selector(gestureControlSlot:didBeginHorizontalDragAtPoint:)]) {
            [delegate gestureControlSlot:self didBeginHorizontalDragAtPoint:self.dragStartPoint];
        }
    } else if (absDeltaY > kMinVerticalDistance && absDeltaY > absDeltaX) {
        if ([self currentSceneType] == SceneTypeVideoList) return;

        BOOL isLeftSide = self.dragStartPoint.x < CGRectGetWidth(self.bounds) / 2.0;

        if (isLeftSide) {
            if (!self.config.leftVerticalDragEnabled) return;

            self.gestureState = GestureStateVerticalLeft;
            TriggerLightFeedback(self);
            self.currentBrightness = [UIScreen mainScreen].brightness;
            SLOGI(@"Left vertical drag started (brightness: %.2f)", self.currentBrightness);

            id<GestureControlSlotDelegate> delegate = self.delegate;
            if (delegate && [delegate respondsToSelector:@selector(gestureControlSlot:didBeginLeftVerticalDragAtPoint:)]) {
                [delegate gestureControlSlot:self didBeginLeftVerticalDragAtPoint:self.dragStartPoint];
            }
        } else {
            if (!self.config.rightVerticalDragEnabled) return;

            self.gestureState = GestureStateVerticalRight;
            TriggerLightFeedback(self);
            self.currentVolumePercent = self.systemVolumeSlider ? self.systemVolumeSlider.value : 0.5;
            SLOGI(@"Right vertical drag started (volume: %.2f)", self.currentVolumePercent);

            id<GestureControlSlotDelegate> delegate = self.delegate;
            if (delegate && [delegate respondsToSelector:@selector(gestureControlSlot:didBeginRightVerticalDragAtPoint:)]) {
                [delegate gestureControlSlot:self didBeginRightVerticalDragAtPoint:self.dragStartPoint];
            }
        }
    }
}

#pragma mark - Horizontal Drag Processing (Seek)

- (void)processHorizontalDragAtX:(CGFloat)currentX {
    CGFloat deltaPercent = [self.horizontalTracker updateWithPosition:currentX
                                                            totalSize:CGRectGetWidth(self.bounds)];
    if (deltaPercent == 0) return;

    self.accumulatedSeekPercent += deltaPercent;

    id<GestureControlSlotDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(gestureControlSlot:didUpdateHorizontalDragWithDelta:)]) {
        [delegate gestureControlSlot:self didUpdateHorizontalDragWithDelta:deltaPercent];
    }
}

#pragma mark - Vertical Drag Processing (Brightness / Volume)

- (void)processVerticalDragAtY:(CGFloat)currentY {
    CGFloat deltaPercent = [self.verticalTracker updateWithPosition:currentY
                                                          totalSize:CGRectGetHeight(self.bounds)];
    if (deltaPercent == 0) return;

    id<GestureControlSlotDelegate> delegate = self.delegate;

    if (self.gestureState == GestureStateVerticalLeft) {
        CGFloat change = -deltaPercent * kBrightnessSensitivity;
        self.currentBrightness = MAX(0.0, MIN(1.0, self.currentBrightness + change));

        // 默认行为：调节屏幕亮度
        [UIScreen mainScreen].brightness = self.currentBrightness;

        if (delegate && [delegate respondsToSelector:@selector(gestureControlSlot:didUpdateLeftVerticalDragWithDelta:currentPercent:)]) {
            [delegate gestureControlSlot:self
    didUpdateLeftVerticalDragWithDelta:deltaPercent
                        currentPercent:self.currentBrightness];
        }

        CGFloat brightness = self.currentBrightness;
        [self.gestureDispatcher notifyObservers:^(id<GestureNotificationDelegate> observer) {
            if (observer && [observer respondsToSelector:@selector(gestureDidUpdateBrightnessWithPercent:)]) {
                [observer gestureDidUpdateBrightnessWithPercent:brightness];
            }
        }];
    } else if (self.gestureState == GestureStateVerticalRight) {
        CGFloat change = -deltaPercent * kVolumeSensitivity;
        self.currentVolumePercent = MAX(0.0, MIN(1.0, self.currentVolumePercent + change));

        // 默认行为：调节系统音量
        if (self.systemVolumeSlider) {
            self.systemVolumeSlider.value = (float)self.currentVolumePercent;
        }

        if (delegate && [delegate respondsToSelector:@selector(gestureControlSlot:didUpdateRightVerticalDragWithDelta:currentPercent:)]) {
            [delegate gestureControlSlot:self
    didUpdateRightVerticalDragWithDelta:deltaPercent
                         currentPercent:self.currentVolumePercent];
        }

        CGFloat volume = self.currentVolumePercent;
        [self.gestureDispatcher notifyObservers:^(id<GestureNotificationDelegate> observer) {
            if (observer && [observer respondsToSelector:@selector(gestureDidUpdateVolumeWithPercent:)]) {
                [observer gestureDidUpdateVolumeWithPercent:volume];
            }
        }];
    }
}

@end
