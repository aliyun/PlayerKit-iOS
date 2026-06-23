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
