//
//  SlotBehavior.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SlotHost;
@protocol PlayerNotificationDelegate;
@class AliPlayerController;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 插槽行为委托类（组合模式）。
 *
 * @discussion 封装插槽的核心逻辑（生命周期管理、事件订阅），采用组合模式设计。
 *             通过组合此行为类，任何对象都可以获得插槽能力，而无需继承 BaseSlot（UIView 子类）。
 *             适用于纯逻辑组件需要监听播放器事件的场景。
 *
 *             核心功能：
 *             - attach/detach 生命周期管理。
 *             - PlayerNotificationDelegate 自动订阅管理（detach 时自动取消所有订阅）。
 *             - 弱引用宿主，避免循环引用。
 *
 * @see BaseSlot
 * @see SlotHost
 * @see PlayerNotificationDelegate
 */
@interface SlotBehavior : NSObject

/** @brief 当前附属的宿主（弱引用）。 */
@property (nonatomic, weak, readonly, nullable) id<SlotHost> host;

/**
 * @brief 附加到宿主。
 *
 * @param host 插槽宿主。
 *
 * @discussion 保存宿主引用，供后续访问控制器和状态存储使用。
 */
- (void)attachToHost:(id<SlotHost>)host;

/**
 * @brief 从宿主分离。
 *
 * @discussion 自动取消所有通过 addNotificationDelegate:toController: 注册的事件订阅，
 *             确保不会造成内存泄漏。分离后 host 属性将返回 nil。
 */
- (void)detach;

/**
 * @brief 向控制器注册通知代理并跟踪订阅。
 *
 * @param delegate   遵循 PlayerNotificationDelegate 协议的对象。
 * @param controller 要注册到的播放器控制器。
 *
 * @discussion 所有通过此方法注册的代理将在 detach 时自动取消注册。
 *             这是使用 SlotBehavior 的核心优势——避免手动管理订阅生命周期。
 *
 * @see removeNotificationDelegate:fromController:
 */
- (void)addNotificationDelegate:(id<PlayerNotificationDelegate>)delegate
                   toController:(AliPlayerController *)controller;

/**
 * @brief 手动取消单个通知代理的注册。
 *
 * @param delegate   要取消注册的代理对象。
 * @param controller 之前注册到的播放器控制器。
 *
 * @discussion 通常不需要手动调用，detach 会自动清理所有订阅。
 *             仅在需要在 detach 之前提前取消特定订阅时使用。
 */
- (void)removeNotificationDelegate:(id<PlayerNotificationDelegate>)delegate
                     fromController:(AliPlayerController *)controller;

@end

NS_ASSUME_NONNULL_END
