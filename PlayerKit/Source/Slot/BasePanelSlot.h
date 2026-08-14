//
//  BasePanelSlot.h
//  AliPlayerKit
//
//  Created by keria on 2026/08/11.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "BaseSlot.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 面板滑入方向

/**
 * @brief 面板的滑入/滑出方向。
 *
 * @discussion 基类据此计算面板的屏外位移，并统一用 @c transform 实现滑动动画。
 *             使用 @c transform 而非 @c frame，使得同一套动画既适用于 Auto Layout
 *             约束驱动的面板，也适用于手动设置 frame 的面板。
 *
 * @see BasePanelSlot.panelSlideEdge
 */
typedef NS_ENUM(NSInteger, PanelSlideEdge) {
    /** 不滑动（面板自行实现进出场动画）。 */
    PanelSlideEdgeNone = 0,

    /** 从左侧边缘滑入 / 滑出。 */
    PanelSlideEdgeLeft,

    /** 从右侧边缘滑入 / 滑出。 */
    PanelSlideEdgeRight,

    /** 从顶部边缘滑入 / 滑出。 */
    PanelSlideEdgeTop,

    /** 从底部边缘滑入 / 滑出。 */
    PanelSlideEdgeBottom,
};

/**
 * @brief 面板类插槽的抽象基类。
 *
 * @discussion 以模板方法模式封装弹窗面板的完整呈现流程：显示状态防重入、蒙层的创建与
 *             淡入淡出、面板的滑入滑出、z-order 提升、@c hidden 管理、生命周期收尾回调，
 *             以及分离与数据解绑时的强制关闭。
 *
 *             最简子类只需三步：
 *             1. 在 @c setupContentView 中创建面板视图；
 *             2. 重写 @c panelView 返回该视图；
 *             3. 重写 @c panelSlideEdge 声明滑入方向。
 *             蒙层、动画、状态机、清理均由基类完成，无需重写任何动画方法。
 *
 *             构造时默认置为：@c deferContentCreation = YES 、
 *             @c touchPassthrough = NO 、@c safeAreaEdges = SlotSafeAreaEdgeNone
 *             （面板自行铺满宿主并管理内部避让）。
 *
 * @see SettingMenuSlot
 * @see OptionPanelSlot
 * @see ChapterPanelSlot
 */
@interface BasePanelSlot : BaseSlot

#pragma mark - 显示状态

/**
 * @brief 面板当前是否处于显示状态。
 *
 * @discussion 表示"显示意图"而非"动画已结束"：@c showPanel 在准备成功后立即置为 YES，
 *             @c hidePanel 一进入即为 NO，进出场动画期间该值已是目标态。
 */
@property (nonatomic, assign, readonly) BOOL isPanelShowing;

/**
 * @brief 基类持有的蒙层视图。
 *
 * @discussion 首次访问时按 @c overlayColor / @c overlayAlpha 惰性创建，并自动绑定
 *             点击关闭手势（仅绑定一次，不会重复叠加）。@c showPanel 时由基类插入到
 *             @c panelHostView 的最底层，因此始终位于面板视图之下。
 *             当 @c needsOverlay 返回 NO 时恒为 nil。
 *
 * @see needsOverlay
 * @see onOverlayClicked
 */
@property (nonatomic, strong, readonly, nullable) UIView *overlayView;

#pragma mark - 显示控制

/**
 * @brief 显示面板。
 *
 * @discussion 流程：防重入 → @c ensureContentReady → @c onPrepareForShow （可否决）
 *             → 置 @c isPanelShowing → @c hidden = NO 并提升 z-order → 安装蒙层
 *             → @c onPerformShowAnimation → 动画结束 → @c onPanelShown 。
 *
 *             已在显示中，或 @c onPrepareForShow 返回 NO 时，直接返回且不改变任何状态。
 *             须在主线程调用。
 *
 * @see hidePanel
 * @see onPrepareForShow
 */
- (void)showPanel;

/**
 * @brief 带动画隐藏面板。
 *
 * @discussion 等价于 @c hidePanelAnimated: 传入 YES。
 *
 * @see hidePanelAnimated:
 */
- (void)hidePanel;

/**
 * @brief 隐藏面板，可选是否带动画。
 *
 * @param animated YES 走 @c onPerformHideAnimation ；NO 跳过动画直接回调 @c onPanelHidden 。
 *
 * @discussion 未在显示中时直接返回。进入后台、数据解绑等需要立即收起面板的场景应传 NO，
 *             避免对即将销毁的视图执行动画。须在主线程调用。
 *
 * @see hidePanel
 */
- (void)hidePanelAnimated:(BOOL)animated;

#pragma mark - 子类必须提供

/**
 * @brief 返回执行滑动动画的面板视图。
 *
 * @discussion 默认返回 nil。当 @c panelSlideEdge 不为 @c PanelSlideEdgeNone 时必须重写，
 *             否则基类的默认动画无对象可用（DEBUG 下触发断言，Release 下退化为仅蒙层淡入淡出）。
 *             基类只读取它的尺寸并改写它的 @c transform ，不参与它的创建与布局。
 *
 * @return 面板视图；nil 表示无滑动面板。
 *
 * @see panelSlideEdge
 * @see panelSize
 */
- (nullable UIView *)panelView;

#pragma mark - 呈现配置（子类可选覆写）

/**
 * @brief 面板与蒙层的承载视图。
 *
 * @discussion 默认返回 @c self ，即面板呈现在插槽自身的视图层级内。
 *             仅当面板必须超出播放器视图范围时（如竖屏底部弹窗需要覆盖整个窗口）
 *             才重写为其他容器，此时该容器的创建与销毁由子类负责，
 *             且插槽的 @c safeAreaEdges / @c touchPassthrough 对面板不再生效。
 *
 * @return 承载面板与蒙层的视图，不可为 nil。
 */
- (UIView *)panelHostView;

/**
 * @brief 面板的滑入 / 滑出方向。
 *
 * @discussion 默认 @c PanelSlideEdgeNone （不滑动，仅蒙层淡入淡出）。
 *             子类可根据当前形态动态返回不同方向。
 *
 * @return 滑动方向。
 *
 * @see PanelSlideEdge
 */
- (PanelSlideEdge)panelSlideEdge;

/**
 * @brief 面板的尺寸，用于计算屏外位移。
 *
 * @discussion 默认先对 @c panelView.superview 触发 @c layoutIfNeeded 以确保
 *             Auto Layout 约束或手动 frame 均已生效，再返回 @c panelView.bounds.size 。
 *             通常无需重写。
 *
 * @return 面板尺寸。
 */
- (CGSize)panelSize;

/**
 * @brief 是否需要蒙层。
 *
 * @discussion 默认 YES。返回 NO 时 @c overlayView 恒为 nil，且不会有点击关闭行为。
 *
 * @return 是否需要蒙层。
 *
 * @see overlayView
 */
- (BOOL)needsOverlay;

/**
 * @brief 蒙层颜色。
 *
 * @discussion 默认纯黑。仅在 @c overlayView 首次创建时读取一次。
 *
 * @return 蒙层颜色。
 */
- (UIColor *)overlayColor;

/**
 * @brief 蒙层完全显示时的不透明度。
 *
 * @discussion 默认 0.5。每次进场动画都会读取。
 *
 * @return 不透明度，取值 0 ~ 1。
 */
- (CGFloat)overlayAlpha;

/**
 * @brief 进出场动画时长（秒）。
 *
 * @discussion 基类的所有动画方法均使用此值。默认 0.3 秒。
 *
 * @return 动画时长（秒）。
 */
- (NSTimeInterval)animationDuration;

/**
 * @brief 进场动画选项。
 *
 * @discussion 默认 @c UIViewAnimationOptionCurveEaseOut 与
 *             @c UIViewAnimationOptionBeginFromCurrentState 。后者保证在退场动画
 *             进行中再次显示时，从当前可见位置继续，而不是从上一段动画的目标值起跳。
 *             子类重写时应以 @c [super showAnimationOptions] 为基础按位或附加选项。
 *
 * @return 动画选项。
 */
- (UIViewAnimationOptions)showAnimationOptions;

/**
 * @brief 退场动画选项。
 *
 * @discussion 默认 @c UIViewAnimationOptionCurveEaseIn 与
 *             @c UIViewAnimationOptionBeginFromCurrentState 。后者保证在进场动画
 *             进行中收起时，从当前可见位置继续，而不是从上一段动画的目标值起跳。
 *             子类重写时应以 @c [super hideAnimationOptions] 为基础按位或附加选项。
 *
 * @return 动画选项。
 */
- (UIViewAnimationOptions)hideAnimationOptions;

#pragma mark - 布局辅助（子类复用）

/**
 * @brief 把面板视图布局到它"完全显示"时应处的位置。
 *
 * @discussion 手动摆放面板（而非用 Auto Layout 约束）的子类，必须在
 *             @c layoutSubviews 中通过本方法设置面板位置，不可直接赋值
 *             @c panel.frame 。
 *
 *             原因：@c UIView.frame 在 @c transform 非 identity 时是未定义的——
 *             对它赋值会使 UIKit 反推 @c center ，令"变换后"的 frame 等于所赋矩形。
 *             滑出动画进行中面板的 transform 正处于屏外位移，此时若有一次布局
 *             （旋转、bounds 变化、@c layoutIfNeeded 等）直接赋值 frame，
 *             面板会被瞬间拽回显示位置，产生跳变。
 *
 *             本方法改为设置 @c bounds 与 @c center ——两者描述的都是未经变换的
 *             几何，因此不会干扰在途的 transform 动画。
 *             （Auto Layout 驱动的面板天然安全，约束求解的目标同样是未变换的 frame。）
 *
 * @param panel 面板视图，传 nil 时不做任何事。
 * @param frame 面板完全显示时在其父视图坐标系中的目标矩形。
 *
 * @see panelView
 * @see panelSlideEdge
 */
- (void)layoutPanelView:(nullable UIView *)panel toShownFrame:(CGRect)frame;

#pragma mark - 生命周期钩子（子类可选覆写）

/**
 * @brief 显示前的准备工作，并决定本次显示是否继续。
 *
 * @discussion 由 @c showPanel 在 @c ensureContentReady 之后、置 @c isPanelShowing 之前调用。
 *             子类在此刷新数据、重建列表、构建（或校验）承载容器。
 *             返回 NO 表示本次不具备显示条件（如无数据、无可用窗口），
 *             @c showPanel 将原样返回，不会进入显示状态，也不会触发任何动画或回调。
 *
 *             默认实现返回 YES。
 *
 *             之所以由此处否决而非在调用方拦截：显示条件属于面板自身的职责，
 *             且在置位显示状态之前否决，可避免子类从进场路径反向调用 @c hidePanel
 *             造成的状态机重入。
 *
 * @return YES 继续显示；NO 取消本次显示。
 *
 * @see showPanel
 */
- (BOOL)onPrepareForShow;

/**
 * @brief 面板完全显示后的回调。
 *
 * @discussion 由基类在进场动画结束后自动调用，无需子类手动触发。默认为空实现。
 *             若动画期间已转为隐藏意图（@c isPanelShowing 变为 NO），本回调不会触发。
 *
 * @see showPanel
 */
- (void)onPanelShown;

/**
 * @brief 面板完全隐藏后的回调。
 *
 * @discussion 由基类在退场动画结束后（或 @c hidePanelAnimated: 传 NO 时立即）自动调用。
 *             默认实现置 @c hidden = YES ；子类重写时须调用 super，
 *             并在此释放回调块、销毁临时容器等。
 *             若动画期间面板已被重新显示（@c isPanelShowing 变回 YES），本回调不会触发，
 *             以免刚显示的面板被上一次退场的收尾逻辑破坏。
 *
 * @see hidePanelAnimated:
 */
- (void)onPanelHidden;

/**
 * @brief 蒙层被点击时的回调。
 *
 * @discussion 默认实现调用 @c hidePanel 。
 *
 * @see overlayView
 */
- (void)onOverlayClicked;

#pragma mark - 动画（子类可选覆写 / 复用）

/**
 * @brief 执行面板进场动画。
 *
 * @discussion 默认实现：把 @c panelView 按 @c panelSlideEdge 与 @c panelSize 预置到屏外，
 *             再通过 @c animateShow: 滑回原位。
 *             仅当默认的滑动动画无法满足需求时才重写；重写实现应通过 @c animateShow:
 *             执行动画，以便自动获得蒙层淡入与 @c onPanelShown 回调。
 *
 * @see animateShow:
 */
- (void)onPerformShowAnimation;

/**
 * @brief 执行面板退场动画。
 *
 * @discussion 默认实现：通过 @c animateHide: 把 @c panelView 滑出到屏外。
 *             重写实现应通过 @c animateHide: 执行动画，以便自动获得蒙层淡出与
 *             @c onPanelHidden 回调。
 *
 * @see animateHide:
 */
- (void)onPerformHideAnimation;

/**
 * @brief 以进场参数执行一段动画，并在结束后回调 @c onPanelShown 。
 *
 * @param animations 附加的动画内容，可为 nil。
 *
 * @discussion 使用 @c animationDuration 与 @c showAnimationOptions ，
 *             并自动把蒙层从 0 淡入到 @c overlayAlpha 。
 *
 * @see onPerformShowAnimation
 */
- (void)animateShow:(nullable void (^)(void))animations;

/**
 * @brief 以退场参数执行一段动画，并在结束后回调 @c onPanelHidden 。
 *
 * @param animations 附加的动画内容，可为 nil。
 *
 * @discussion 使用 @c animationDuration 与 @c hideAnimationOptions ，
 *             并自动把蒙层淡出到 0。
 *
 * @see onPerformHideAnimation
 */
- (void)animateHide:(nullable void (^)(void))animations;

@end

NS_ASSUME_NONNULL_END
