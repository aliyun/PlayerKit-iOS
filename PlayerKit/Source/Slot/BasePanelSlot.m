//
//  BasePanelSlot.m
//  AliPlayerKit
//
//  Created by keria on 2026/08/11.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "BasePanelSlot.h"
#import "Log.h"
#import "../Utils/PlayerLayout+Private.h"

#pragma mark - Defaults

static const NSTimeInterval kDefaultAnimationDuration = 0.3;
static const CGFloat kDefaultOverlayAlpha = 0.5;

// 外部承载视图的几何变化需通知插槽重新布局。
@interface PanelLayoutObserverView : UIView
@property (nonatomic, weak) BasePanelSlot *owner;
@property (nonatomic, assign) BOOL hasSnapshot;
@property (nonatomic, assign) CGRect previousBounds;
@property (nonatomic, assign) CGRect previousReadableBounds;
@property (nonatomic, assign) UIEdgeInsets previousInsets;
@property (nonatomic, weak) UIWindow *previousWindow;
@end

@implementation PanelLayoutObserverView

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints {
    PlayerLayoutReadableRect(self, self.bounds, YES);
    [self setNeedsLayout];
    [super updateConstraints];
}

- (void)safeAreaInsetsDidChange {
    [super safeAreaInsetsDidChange];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIView *host = self.superview;
    if (!host) return;
    CGRect readable = PlayerLayoutReadableRect(self, self.bounds, YES);
    UIEdgeInsets insets = UIEdgeInsetsZero;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
    if (@available(iOS 11.0, *)) insets = host.safeAreaInsets;
#endif
    BOOL changed = !self.hasSnapshot || !CGRectEqualToRect(host.bounds, self.previousBounds) ||
        !CGRectEqualToRect(readable, self.previousReadableBounds) ||
        !UIEdgeInsetsEqualToEdgeInsets(insets, self.previousInsets) || self.window != self.previousWindow;
    self.hasSnapshot = YES;
    self.previousBounds = host.bounds;
    self.previousReadableBounds = readable;
    self.previousInsets = insets;
    self.previousWindow = self.window;
    if (changed) {
        [self.owner setNeedsLayout];
        [self.owner layoutIfNeeded];
    }
}

@end

// 容器空白区域不拦截触摸，以保留蒙层点击关闭行为。
@interface PanelContentHostView : UIView
@end

@implementation PanelContentHostView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return hit == self ? nil : hit;
}
@end

@interface BasePanelSlot ()

@property (nonatomic, assign) BOOL isPanelShowing;
@property (nonatomic, strong) PanelLayoutObserverView *panelLayoutObserver;
@property (nonatomic, strong) UIView *panelContentContainer;
@property (nonatomic, assign) NSUInteger panelAnimationGeneration;
@property (nonatomic, assign) BOOL slideOutAnimating;

@end

@implementation BasePanelSlot

@synthesize overlayView = _overlayView;

// ==================== 面板呈现状态机 ====================
//
// 显示：showPanel
//         → 防重入（isPanelShowing）
//         → ensureContentReady（触发延迟内容创建 + 回放 onBindData:）
//         → onPrepareForShow（子类刷新数据 / 构建容器，可否决）
//         → 置 isPanelShowing = YES
//         → hidden = NO + 提升 z-order
//         → 安装蒙层到 panelHostView（alpha 归零）
//         → onPerformShowAnimation → animateShow: → onPanelShown
//
// 隐藏：hidePanelAnimated:
//         → 防重入
//         → 置 isPanelShowing = NO
//         → animated ? onPerformHideAnimation → animateHide: : 立即收尾
//         → onPanelHidden（默认置 hidden = YES）
//
// 契约一：isPanelShowing 表示"显示意图"而非"动画已结束"，在动画开始前即为目标态。
//
// 契约二：动画结束回调按"意图是否仍然成立"派发——进场动画结束时若已不再是显示意图，
//   不回调 onPanelShown；退场动画结束时若已重新进入显示，不回调 onPanelHidden。
//   这样"快速 hide → show"不会在新面板显示后被旧的退场收尾（hidden = YES、
//   销毁临时视图）打断。
//
// 契约三：显示条件由 onPrepareForShow 在置位显示状态之前否决，因此子类不必也不应
//   从进场路径反向调用 hidePanel——那会造成状态机重入并对尚未建立的视图执行退场动画。
//
// 清理：onDetach 直接复位状态并清除蒙层与面板的残留动画，不走退场动画、不回调
//   onPanelHidden；onUnbindData 则以无动画方式强制收起面板。
//
// ==================== End ====================

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.deferContentCreation = YES;
        self.touchPassthrough = NO;
        self.safeAreaEdges = SlotSafeAreaEdgeNone;
    }

    return self;
}

- (void)updateConstraints {
    [self panelLayoutBounds];
    [self setNeedsLayout];
    [super updateConstraints];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.panelContentContainer.superview == [self panelHostView]) {
        self.panelContentContainer.frame = [self panelLayoutBounds];
    }
}

/// 从宿主分离：复位显示状态并清除蒙层 / 面板的残留动画（子类重写时须调用 super）
- (void)onDetach {
    _isPanelShowing = NO;
    self.panelAnimationGeneration++;
    self.slideOutAnimating = NO;

    // 直接访问 ivar，避免在销毁路径上惰性创建蒙层
    if (_overlayView) {
        [_overlayView.layer removeAllAnimations];
        _overlayView.alpha = 0;
        // 从旧宿主的视图层级中摘除：插槽可能被复用并重新 attach 到另一个宿主，
        // 届时 installOverlayIfNeeded 会重新插入，不摘除会在旧层级里留下悬挂视图
        [_overlayView removeFromSuperview];
    }

    UIView *panel = [self panelView];

    if (panel) {
        [panel.layer removeAllAnimations];
    }

    [self.panelLayoutObserver removeFromSuperview];
    self.panelLayoutObserver = nil;
    // 内容就绪状态不随分离重置，需保留容器内的内容供再次显示。
    [self.panelContentContainer removeFromSuperview];
    [super onDetach];
}

/// 数据解绑：面板内容已失效，立即（无动画）收起，避免残留在屏幕上
- (void)onUnbindData {
    if (_isPanelShowing) {
        [self hidePanelAnimated:NO];
    }

    [super onUnbindData];
}

#pragma mark - Panel Show/Hide

- (void)showPanel {
    [self assertMainThreadForMethod:@"showPanel"];

    if (_isPanelShowing) {
        return;
    }

    // 先触发延迟内容创建，确保 onPrepareForShow 中的视图与数据均已就绪
    [self ensureContentReady];

    if (![self onPrepareForShow]) {
        SLOGI(@"[%@] show request cancelled by onPrepareForShow", NSStringFromClass([self class]));
        return;
    }

    _isPanelShowing = YES;
    self.hidden = NO;
    [self.superview bringSubviewToFront:self];

    // 仅恢复基类容器，不迁移子类自行挂载的面板。
    if (self.panelContentContainer) {
        [self panelContentHostView];
    }
    [self installPanelLayoutObserver];
    [self installOverlayIfNeeded];
    // 承载视图可能已变更，需重新追踪其保留区变化。
    [self setNeedsUpdateConstraints];

    if (_overlayView) {
        _overlayView.alpha = 0;
    }

    // 先把面板的布局结算到位，再开始动画：延迟创建的内容此刻可能尚未走过一次
    // layoutSubviews，若不结算，进场动画会从零尺寸的位置起跳
    [self setNeedsLayout];
    [self layoutIfNeeded];
    UIView *panelToLayout = [self panelView];

    if (panelToLayout) {
        [panelToLayout.superview layoutIfNeeded];
    }

    [self onPerformShowAnimation];
}

- (void)hidePanel {
    [self hidePanelAnimated:YES];
}

- (void)hidePanelAnimated:(BOOL)animated {
    [self assertMainThreadForMethod:@"hidePanelAnimated:"];

    if (!_isPanelShowing) {
        return;
    }

    _isPanelShowing = NO;

    if (animated) {
        [self onPerformHideAnimation];
        return;
    }

    // 无动画路径：清除在途动画并直接落到终态，随后收尾
    self.panelAnimationGeneration++;
    self.slideOutAnimating = NO;
    if (_overlayView) {
        [_overlayView.layer removeAllAnimations];
        _overlayView.alpha = 0;
    }

    UIView *panel = [self panelView];

    if (panel) {
        [panel.layer removeAllAnimations];
        panel.transform = [self panelOffscreenTransform];
    }

    [self onPanelHidden];
}

#pragma mark - Subclass Hooks (Required)

/// 默认无滑动面板；panelSlideEdge 不为 None 时子类必须重写
- (nullable UIView *)panelView {
    return nil;
}

#pragma mark - Subclass Hooks (Presentation)

- (UIView *)panelHostView {
    return self;
}

- (PanelSlideEdge)panelSlideEdge {
    return PanelSlideEdgeNone;
}

- (CGSize)panelSize {
    UIView *panel = [self panelView];

    if (!panel) {
        return CGSizeZero;
    }

    // 先结算一次布局，使 Auto Layout 约束与手动 frame 两种方式都能给出真实尺寸
    [panel.superview layoutIfNeeded];
    return panel.bounds.size;
}

- (BOOL)needsOverlay {
    return YES;
}

- (UIColor *)overlayColor {
    return [UIColor blackColor];
}

- (CGFloat)overlayAlpha {
    return kDefaultOverlayAlpha;
}

- (NSTimeInterval)animationDuration {
    return kDefaultAnimationDuration;
}

/// BeginFromCurrentState：显示 / 隐藏快速反转时从当前可见位置续接，避免从上一段动画的目标值起跳
- (UIViewAnimationOptions)showAnimationOptions {
    return UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState;
}

- (UIViewAnimationOptions)hideAnimationOptions {
    return UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState;
}

#pragma mark - Layout Helper

- (CGRect)panelLayoutBounds {
    UIView *host = [self panelHostView];
    return PlayerLayoutReadableRect(host, host.bounds, YES);
}

- (UIView *)panelContentHostView {
    UIView *host = [self panelHostView];
    if (!self.panelContentContainer) {
        UIView *container = [[PanelContentHostView alloc] init];
        container.backgroundColor = [UIColor clearColor];
        container.layoutMargins = UIEdgeInsetsZero;
        container.clipsToBounds = YES;
        self.panelContentContainer = container;
    }
    if (self.panelContentContainer.superview != host) {
        [host addSubview:self.panelContentContainer];
    }
    self.panelContentContainer.frame = [self panelLayoutBounds];
    return self.panelContentContainer;
}

- (CGRect)panelFrameForSize:(CGSize)preferredSize {
    CGRect bounds = [self panelLayoutBounds];
    CGFloat width = MIN(MAX(0, preferredSize.width), MAX(0, CGRectGetWidth(bounds)));
    CGFloat height = MIN(MAX(0, preferredSize.height), MAX(0, CGRectGetHeight(bounds)));
    return CGRectMake(CGRectGetMaxX(bounds) - width, CGRectGetMaxY(bounds) - height, width, height);
}

- (void)layoutPanelView:(nullable UIView *)panel toShownFrame:(CGRect)frame {
    if (!panel) {
        return;
    }
    if (self.panelContentContainer && panel.superview == self.panelContentContainer) {
        self.panelContentContainer.frame = [self panelLayoutBounds];
        frame = [self.panelContentContainer convertRect:frame fromView:[self panelHostView]];
    }

    // 只写 bounds 与 center（两者均为未变换几何），不写 frame——
    // frame 在 transform 非 identity 时是未定义的，赋值会把正在滑出的面板拽回显示位置
    BOOL sizeChanged = !CGSizeEqualToSize(panel.bounds.size, frame.size);
    CGRect bounds = panel.bounds;
    bounds.size = frame.size;
    panel.bounds = bounds;
    panel.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    if (sizeChanged && self.slideOutAnimating && !self.isPanelShowing &&
        self.panelContentContainer && panel.superview == self.panelContentContainer) {
        // 尺寸变化后需更新退场位移，动画代次检查可避免旧回调重复收尾。
        CGAffineTransform offscreen = [self panelOffscreenTransformForSize:frame.size];
        [self animateHide:^{ panel.transform = offscreen; }];
    }
}

#pragma mark - Subclass Hooks (Lifecycle)

- (BOOL)onPrepareForShow {
    return YES;
}

- (void)onPanelShown {
    // 默认空实现，子类按需重写
}

/// 默认在完全隐藏后置 hidden = YES（子类重写时须调用 super）
- (void)onPanelHidden {
    self.hidden = YES;
    [self.panelLayoutObserver removeFromSuperview];
    self.panelLayoutObserver = nil;
    if (self.panelContentContainer.superview != self) {
        [self.panelContentContainer removeFromSuperview];
    }
}

/// 默认点击蒙层即关闭面板
- (void)onOverlayClicked {
    [self hidePanel];
}

#pragma mark - Overlay

- (nullable UIView *)overlayView {
    if (![self needsOverlay]) {
        return nil;
    }

    if (!_overlayView) {
        _overlayView = [[UIView alloc] init];
        _overlayView.backgroundColor = [self overlayColor];
        _overlayView.alpha = 0;
        _overlayView.userInteractionEnabled = YES;
        _overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        // 手势在创建时一次性绑定，不存在重复叠加的可能
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(handleOverlayTap:)];
        [_overlayView addGestureRecognizer:tap];
    }

    return _overlayView;
}

/// 把蒙层安装到当前的 panelHostView 最底层；重复调用是幂等的
- (void)installOverlayIfNeeded {
    UIView *overlay = self.overlayView;

    if (!overlay) {
        return;
    }

    UIView *host = [self panelHostView];

    if (!host) {
        return;
    }

    if (overlay.superview != host) {
        [host insertSubview:overlay atIndex:0];
    } else {
        [host sendSubviewToBack:overlay];
    }

    overlay.frame = host.bounds;
}

- (void)handleOverlayTap:(UITapGestureRecognizer *)gesture {
    [self onOverlayClicked];
}

#pragma mark - Animation

- (void)onPerformShowAnimation {
    UIView *panel = [self panelView];
    PanelSlideEdge edge = [self panelSlideEdge];

    if (edge != PanelSlideEdgeNone && !panel) {
        NSAssert(NO, @"[%@] panelView must be overridden when panelSlideEdge is not PanelSlideEdgeNone",
                 NSStringFromClass([self class]));
        SLOGW(@"[%@] panelSlideEdge is set but panelView is nil, falling back to overlay-only animation",
              NSStringFromClass([self class]));
    }

    // 无面板视图时退化为仅蒙层淡入：仍须走 animateShow:，否则蒙层不会显现，
    // 且 onPanelShown 永远不会派发，状态机会停在"显示中但无收尾"的悬挂态
    if (!panel) {
        [self animateShow:nil];
        return;
    }

    panel.transform = [self panelOffscreenTransform];
    [self animateShow:^{
        panel.transform = CGAffineTransformIdentity;
    }];
}

- (void)onPerformHideAnimation {
    UIView *panel = [self panelView];

    // 同上，退化为仅蒙层淡出，onPanelHidden 仍需被派发以完成收尾
    if (!panel) {
        [self animateHide:nil];
        return;
    }

    CGAffineTransform offscreen = [self panelOffscreenTransform];
    self.slideOutAnimating = YES;
    [self animateHide:^{
        panel.transform = offscreen;
    }];
}

- (void)animateShow:(nullable void (^)(void))animations {
    NSUInteger generation = ++self.panelAnimationGeneration;
    self.slideOutAnimating = NO;
    UIView *overlay = self.overlayView;
    CGFloat targetAlpha = [self overlayAlpha];

    [UIView animateWithDuration:[self animationDuration]
                          delay:0
                        options:[self showAnimationOptions]
                     animations:^{
        overlay.alpha = targetAlpha;
        if (animations) {
            animations();
        }
    } completion:^(BOOL finished) {
        // 仅当前动画且显示意图仍成立时收尾，避免过期回调干扰新状态。
        if (generation == self.panelAnimationGeneration && self.isPanelShowing) {
            [self onPanelShown];
        }
    }];
}

- (void)animateHide:(nullable void (^)(void))animations {
    NSUInteger generation = ++self.panelAnimationGeneration;
    UIView *overlay = self.overlayView;

    [UIView animateWithDuration:[self animationDuration]
                          delay:0
                        options:[self hideAnimationOptions]
                     animations:^{
        overlay.alpha = 0;
        if (animations) {
            animations();
        }
    } completion:^(BOOL finished) {
        // 仅当前动画且隐藏意图仍成立时收尾，避免过期回调移除面板。
        if (generation == self.panelAnimationGeneration && !self.isPanelShowing) {
            self.slideOutAnimating = NO;
            [self onPanelHidden];
        }
    }];
}

#pragma mark - Private

- (void)installPanelLayoutObserver {
    UIView *host = [self panelHostView];
    if (host == self) return;
    if (self.panelLayoutObserver.superview == host) return;
    [self.panelLayoutObserver removeFromSuperview];
    PanelLayoutObserverView *observer = [[PanelLayoutObserverView alloc] init];
    observer.owner = self;
    observer.userInteractionEnabled = NO;
    observer.accessibilityElementsHidden = YES;
    observer.translatesAutoresizingMaskIntoConstraints = NO;
    [host insertSubview:observer atIndex:0];
    [NSLayoutConstraint activateConstraints:@[
        [observer.leadingAnchor constraintEqualToAnchor:host.leadingAnchor],
        [observer.trailingAnchor constraintEqualToAnchor:host.trailingAnchor],
        [observer.topAnchor constraintEqualToAnchor:host.topAnchor],
        [observer.bottomAnchor constraintEqualToAnchor:host.bottomAnchor],
    ]];
    self.panelLayoutObserver = observer;
}

/// 按 panelSlideEdge 与 panelSize 计算面板的屏外位移
- (CGAffineTransform)panelOffscreenTransform {
    PanelSlideEdge edge = [self panelSlideEdge];

    if (edge == PanelSlideEdgeNone) {
        return CGAffineTransformIdentity;
    }

    return [self panelOffscreenTransformForSize:[self panelSize]];
}

- (CGAffineTransform)panelOffscreenTransformForSize:(CGSize)size {
    switch ([self panelSlideEdge]) {
        case PanelSlideEdgeLeft:
            return CGAffineTransformMakeTranslation(-size.width, 0);

        case PanelSlideEdgeRight:
            return CGAffineTransformMakeTranslation(size.width, 0);

        case PanelSlideEdgeTop:
            return CGAffineTransformMakeTranslation(0, -size.height);

        case PanelSlideEdgeBottom:
            return CGAffineTransformMakeTranslation(0, size.height);

        case PanelSlideEdgeNone:
            break;
    }
    return CGAffineTransformIdentity;
}

/// 主线程契约：DEBUG 下断言，Release 下告警但继续执行（与 BaseSlot 的处理方式一致）
- (void)assertMainThreadForMethod:(NSString *)method {
    if ([NSThread isMainThread]) {
        return;
    }

    NSAssert(NO, @"[%@] %@ must be called on the main thread", NSStringFromClass([self class]), method);
    SLOGW(@"[%@] %@ called off the main thread", NSStringFromClass([self class]), method);
}

@end
