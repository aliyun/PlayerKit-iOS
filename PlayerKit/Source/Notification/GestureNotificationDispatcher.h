//
//  GestureNotificationDispatcher.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GestureNotificationDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 线程安全的手势事件通知分发器。
 *
 * @discussion 管理一组遵循 GestureNotificationDelegate 协议的弱引用观察者集合。
 *             使用串行分派队列确保对观察者列表的线程安全访问。
 *             通知始终在主线程上分派。
 *
 * @see GestureNotificationDelegate
 * @see GestureControlSlot
 */
@interface GestureNotificationDispatcher : NSObject

/**
 * @brief 添加通知观察者。
 *
 * @param observer 遵循 GestureNotificationDelegate 协议的对象，不可为 nil。
 *
 * @discussion 观察者通过 NSHashTable 以弱引用方式存储。
 *             重复添加同一观察者不会产生效果。
 *
 * @see removeObserver:
 */
- (void)addObserver:(id<GestureNotificationDelegate>)observer;

/**
 * @brief 移除通知观察者。
 *
 * @param observer 要移除的观察者。
 *
 * @discussion 如果观察者未注册，此方法不会产生任何效果。
 *
 * @see addObserver:
 */
- (void)removeObserver:(id<GestureNotificationDelegate>)observer;

/**
 * @brief 移除所有已注册的观察者。
 *
 * @discussion 清空整个观察者列表。通常在清理或释放时调用。
 */
- (void)removeAllObservers;

/**
 * @brief 向所有已注册的观察者分发通知 Block。
 *
 * @param block 接收每个观察者作为参数的 Block。
 *
 * @discussion 先以线程安全方式获取当前观察者的快照，然后在主线程上对每个观察者
 *             调用该 Block。每次调用均用 @try/@catch 包裹，以防止某个观察者的
 *             异常影响其他观察者。
 */
- (void)notifyObservers:(void(^)(id<GestureNotificationDelegate> observer))block;

/**
 * @brief 返回当前已注册的观察者数量。
 *
 * @return 活跃观察者的数量。
 *
 * @discussion 此数量反映调用时刻的活跃（未被释放）观察者数。
 */
- (NSUInteger)observerCount;

@end

NS_ASSUME_NONNULL_END
