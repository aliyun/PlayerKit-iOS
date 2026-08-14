//
//  BaseSlot.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlotProtocol.h"
#import "SlotHost.h"
#import "SlotType.h"
#import "SceneType.h"

@class SlotActionNotificationDispatcher;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Slot 通用时序常量

/**
 * @brief 控制栏自动隐藏延迟时间（秒）。
 *
 * @discussion BottomBar / TopBar 等自动隐藏类 slot 在无交互后的隐藏延迟。
 */
FOUNDATION_EXPORT const NSTimeInterval SlotAutoHideDelay;

/**
 * @brief 插槽需要避让的安全区域边缘。
 *
 * @discussion SlotHostLayout 在 layoutSubviews 中根据此标志收缩对应边的 frame，
 *             使得插槽内部布局直接使用自身锚点即可避开刘海、Home Indicator 等区域。
 *             未声明的边保持与 SlotHostLayout.bounds 齐平。
 */
typedef NS_OPTIONS(NSUInteger, SlotSafeAreaEdge) {
    SlotSafeAreaEdgeNone   = 0,
    SlotSafeAreaEdgeTop    = 1 << 0,
    SlotSafeAreaEdgeLeft   = 1 << 1,
    SlotSafeAreaEdgeBottom = 1 << 2,
    SlotSafeAreaEdgeRight  = 1 << 3,
    SlotSafeAreaEdgeAll    = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3),
};

/**
 * @brief 播放器视图插槽系统中所有插槽视图的基类。
 *
 * @discussion 提供 SlotProtocol 协议生命周期方法的默认实现。
 *             子类应重写 @c setupContentView 添加自定义 UI 元素，
 *             并根据需要重写生命周期方法。
 *
 * @see SlotProtocol
 * @see SlotHost
 */
@interface BaseSlot : UIView <SlotProtocol>

/** @brief 当前插槽所附属的宿主（弱引用）。 */
@property (nonatomic, weak, readonly, nullable) id<SlotHost> host;

/**
 * @brief 当前插槽的类型标识符。
 *
 * @discussion 此属性由 SlotHostLayout 在 @c rebuildSlots 构建插槽时注入。
 *             外部代码不应修改此值。
 */
@property (nonatomic, assign) SlotType slotType;

/**
 * @brief 需要避让的安全区域边缘。
 *
 * @discussion 默认为 @c SlotSafeAreaEdgeAll（frame 在所有边避让安全区域）。
 *             子类可在 @c initWithFrame: 中设置此属性，
 *             SlotHostLayout 会在 @c layoutSubviews 中据此收缩 frame。
 *
 * @see SlotSafeAreaEdge
 */
@property (nonatomic, assign) SlotSafeAreaEdge safeAreaEdges;

/**
 * @brief 延迟内容创建。
 *
 * @discussion 设为 YES 时，@c onAttach: 不会调用 @c setupContentView，
 *             内容将在首次调用 @c show / @c ensureContentReady 时创建。
 *             子类应在 @c initWithFrame: 中设置此属性。
 */
@property (nonatomic, assign) BOOL deferContentCreation;

/**
 * @brief 内容是否已就绪。
 *
 * @discussion 当 @c setupContentView 已被执行后返回 YES。
 *             对于 @c deferContentCreation = NO 的插槽，在 @c onAttach: 后即为 YES。
 */
@property (nonatomic, assign, readonly) BOOL contentReady;

/**
 * @brief 触摸穿透开关。
 *
 * @discussion 默认为 YES。当触摸未命中任何子视图时，返回 nil 使触摸穿透到下层插槽。
 *             设为 NO 时使用 UIView 默认行为（捕获所有触摸）。
 *             通常只有 GestureControlSlot 需要设为 NO。
 */
@property (nonatomic, assign) BOOL touchPassthrough;

/**
 * @brief Slot 操作事件分发器（由宿主注入）。
 *
 * @discussion 由 SlotHostLayout.wireSlotActionNotifications 在所有插槽挂载后注入，
 *             用于插槽之间的横向通信（如 BottomBar 请求打开章节面板）。
 *
 *             赋值时会自动从旧 dispatcher 注销观察者；若插槽自身遵循
 *             @c SlotActionNotificationDelegate ，则同时向新 dispatcher 注册观察者。
 *             仅作为事件生产者的插槽（如 TopBar、BottomBar）无需遵循该协议，
 *             直接通过此属性发送事件即可。观察者会在 @c onDetach 中自动注销。
 *
 * @see SlotActionNotificationDispatcher
 * @see SlotActionNotificationDelegate
 */
@property (nonatomic, weak, nullable) SlotActionNotificationDispatcher *slotActionDispatcher;

/**
 * @brief 确保内容已创建。
 *
 * @discussion 当 @c deferContentCreation = YES 且内容尚未创建时，
 *             调用 @c setupContentView 并回放 @c onBindData: 。
 *             此方法是幂等的，可安全多次调用。
 */
- (void)ensureContentReady;

/**
 * @brief 子类重写以声明支持的元素及其默认可见性。
 *
 * @discussion 返回的位掩码表示默认可见的元素组合。
 *             未包含的位对应的元素默认不可见。
 *             外部可通过 SlotManager 的 showElements:forSlot: 覆盖默认隐藏的元素，
 *             或通过 hideElements:forSlot: 覆盖默认可见的元素。
 *
 * @return 默认可见元素的位掩码。
 *
 * @see isElementVisible:
 * @see SlotElements
 */
- (NSUInteger)onRegisterElements;

/**
 * @brief 查询指定元素的最终可见性。
 *
 * @param element 要查询的元素位（来自 SlotElements.h 中对应 Slot 的 NS_OPTIONS）。
 *
 * @discussion 合并逻辑：
 *             1. 外部 hideElements → 强制隐藏
 *             2. 外部 showElements → 强制显示
 *             3. 无外部覆盖 → 使用 onRegisterElements 声明的默认值
 *
 * @return 元素是否可见。
 *
 * @see onRegisterElements
 * @see SlotManager
 */
- (BOOL)isElementVisible:(NSUInteger)element;

/**
 * @brief 安全读取当前场景类型。
 *
 * @discussion 在 @c onAttach: 之后调用始终返回 host 上的 sceneType，
 *             整个 slot 生命周期内稳定可读，避免链式访问 model 时 nil 透传降级为 SceneTypeVOD。
 *             子类应优先使用此方法替代 self.host.model.sceneType。
 *
 * @return 当前场景类型。在 onAttach: 之前调用会触发断言（DEBUG）并返回 SceneTypeVOD（Release）。
 */
- (SceneType)currentSceneType;

/**
 * @brief 子类设置内容视图的钩子方法。
 *
 * @discussion 在 @c onAttach: 保存宿主引用后调用（除非 @c deferContentCreation = YES）。
 *             默认实现为空操作。子类应重写此方法以创建和添加 UI 元素。
 */
- (void)setupContentView;

/**
 * @brief 显示插槽视图。
 *
 * @discussion 将视图的 hidden 属性设置为 NO。
 *
 * @see hide
 * @see isShowing
 */
- (void)show;

/**
 * @brief 隐藏插槽视图。
 *
 * @discussion 将视图的 hidden 属性设置为 YES。
 *
 * @see show
 * @see isShowing
 */
- (void)hide;

/**
 * @brief 返回插槽视图当前是否可见。
 *
 * @return 如果视图未隐藏则返回 YES。
 *
 * @see show
 * @see hide
 */
- (BOOL)isShowing;

/**
 * @brief 通过委托宿主进行正确的生命周期管理来移除插槽。
 *
 * @discussion 如果插槽已附属到宿主，宿主将负责解除附属、从内部跟踪列表中移除，
 *             并从视图层级中移除。如果没有宿主，则直接执行清理作为兜底方案。
 *             子类应重写此方法执行自定义清理（如使定时器失效），然后调用 super。
 *
 * @see onDetach
 */
- (void)dismiss;

/**
 * @brief 显示插槽视图，可选是否带动画。
 * @param animated 是否使用动画过渡。
 * @discussion 子类可重写此方法自定义显示动画。
 *             默认实现在 animated 为 NO 时直接设置 hidden = NO，
 *             在 animated 为 YES 时通过 alpha 淡入动画显示。
 */
- (void)showWithAnimation:(BOOL)animated;

/**
 * @brief 隐藏插槽视图，可选是否带动画。
 * @param animated 是否使用动画过渡。
 * @discussion 子类可重写此方法自定义隐藏动画。
 *             默认实现在 animated 为 NO 时直接设置 hidden = YES，
 *             在 animated 为 YES 时通过 alpha 淡出动画隐藏。
 */
- (void)hideWithAnimation:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
