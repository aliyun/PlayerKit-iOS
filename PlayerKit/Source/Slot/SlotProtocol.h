//
//  SlotProtocol.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SlotHost;
@class AliPlayerModel;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 插槽根视图需要避让的宿主安全区域边缘。
 *
 * @discussion 支持按位或组合；由支持该策略的宿主在布局时读取。
 *             仅指定安全区边缘，不决定折叠区避让；内部遮挡由 @c avoidsOcclusion 决定。
 *
 * @see SlotProtocol.safeAreaEdges
 * @see SlotProtocol.avoidsOcclusion
 */
typedef NS_OPTIONS(NSUInteger, SlotSafeAreaEdge) {
    /** @brief 不收缩安全区边缘，不表示取消折叠区或内部遮挡避让。 */
    SlotSafeAreaEdgeNone   = 0,
    /** @brief 避让顶部安全区。 */
    SlotSafeAreaEdgeTop    = 1 << 0,
    /** @brief 避让左侧安全区。 */
    SlotSafeAreaEdgeLeft   = 1 << 1,
    /** @brief 避让底部安全区。 */
    SlotSafeAreaEdgeBottom = 1 << 2,
    /** @brief 避让右侧安全区。 */
    SlotSafeAreaEdgeRight  = 1 << 3,
    /** @brief 避让全部四个安全区边缘。 */
    SlotSafeAreaEdgeAll    = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3),
};

/**
 * @brief 定义播放器视图中插槽生命周期的协议。
 *
 * @discussion 插槽是参与播放器视图插槽系统的 UI 组件。
 *             每个插槽在挂载到宿主或从宿主分离时，以及数据绑定或解绑时，
 *             都会收到相应的生命周期回调。
 *
 * @see SlotHost
 * @see BaseSlot
 */
@protocol SlotProtocol <NSObject>

/**
 * @brief 插槽挂载到宿主时调用。
 *
 * @param host 该插槽所挂载的插槽宿主。
 *
 * @discussion 实现方应保存宿主引用，并执行需要访问宿主的初始化操作。
 *
 * @see onDetach
 */
- (void)onAttach:(id<SlotHost>)host;

/**
 * @brief 插槽从宿主分离时调用。
 *
 * @discussion 实现方应释放宿主引用，并清理与宿主相关的资源。
 *
 * @see onAttach:
 */
- (void)onDetach;

/**
 * @brief 播放数据绑定到插槽时调用。
 *
 * @param model 包含播放信息的播放器模型。
 *
 * @discussion 实现方应根据模型数据更新其 UI。
 *
 * @see onUnbindData
 */
- (void)onBindData:(AliPlayerModel *)model;

/**
 * @brief 播放数据从插槽解绑时调用。
 *
 * @discussion 实现方应将其 UI 重置为默认状态。
 *
 * @see onBindData:
 */
- (void)onUnbindData;

@optional

/**
 * @brief 插槽根视图的安全区边缘避让策略。
 *
 * @discussion 由支持此策略的宿主布局时读取，无需继承 BaseSlot。
 *             SlotHostLayout 在未实现此属性时按 @c SlotSafeAreaEdgeNone 处理，
 *             根视图仍受共同折叠分区限制。挂载后策略变化时，实现方应请求宿主重新布局。
 *
 * @warning 必须在主线程读取或更新策略。
 * @see SlotSafeAreaEdge
 * @see avoidsOcclusion
 * @see SlotHost.hostView
 */
@property (nonatomic, assign, readonly) SlotSafeAreaEdge safeAreaEdges;

/**
 * @brief 插槽根视图是否额外避让摄像头等内部遮挡。
 *
 * @discussion 可独立于 @c safeAreaEdges 声明。SlotHostLayout 在未实现此属性时，
 *             按安全区策略是否为非 @c SlotSafeAreaEdgeNone 决定是否避让。
 *             NO 不取消折叠区避让；交互内容可另用宿主区域查询布局。
 *             挂载后策略变化时，实现方应请求宿主重新布局。
 *
 * @warning 必须在主线程读取或更新策略。
 * @see safeAreaEdges
 * @see SlotHost.hostView
 * @see SlotHost.readableContentBoundsForSlot:
 */
@property (nonatomic, assign, readonly) BOOL avoidsOcclusion;

@end

/**
 * @brief 构建插槽视图的 Block 类型。
 *
 * @discussion SlotProvider 根据给定的父视图创建并返回一个插槽视图。
 *             如果在当前上下文中不应创建该插槽，则返回 nil。
 *
 * @param parentView 插槽将被添加到的父视图。
 *
 * @return 配置好的插槽视图，如果不需要创建则返回 nil。
 */
typedef UIView<SlotProtocol> * _Nullable (^SlotProvider)(UIView *parentView);

NS_ASSUME_NONNULL_END
