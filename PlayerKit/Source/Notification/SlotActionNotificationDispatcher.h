//
//  SlotActionNotificationDispatcher.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/24.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SlotActionNotificationDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 线程安全的 Slot 插槽操作事件通知分发器。
 *
 * @discussion 管理一组遵循 SlotActionNotificationDelegate 协议的弱引用观察者集合。
 *             使用串行分派队列确保对观察者列表的线程安全访问。
 *             与 GestureNotificationDispatcher 不同，此分发器始终通过
 *             dispatch_async(dispatch_get_main_queue(), ...) 异步分发通知，
 *             以避免在按钮事件处理链中同步执行重量级 UI 操作（如 toggleMenu）
 *             导致的 UI 卡死。
 *
 * @see SlotActionNotificationDelegate
 */
@interface SlotActionNotificationDispatcher : NSObject

/**
 * @brief 添加通知观察者。
 *
 * @param observer 遵循 SlotActionNotificationDelegate 协议的对象，不可为 nil。
 *
 * @discussion 观察者通过 NSHashTable 以弱引用方式存储。
 *             重复添加同一观察者不会产生效果。
 *
 * @see removeObserver:
 */
- (void)addObserver:(id<SlotActionNotificationDelegate>)observer;

/**
 * @brief 移除通知观察者。
 *
 * @param observer 要移除的观察者。
 *
 * @discussion 如果观察者未注册，此方法不会产生任何效果。
 *
 * @see addObserver:
 */
- (void)removeObserver:(id<SlotActionNotificationDelegate>)observer;

/**
 * @brief 移除所有已注册的观察者。
 *
 * @discussion 清空整个观察者列表。通常在清理或释放时调用。
 */
- (void)removeAllObservers;

/**
 * @brief 向所有已注册的观察者异步分发通知 Block。
 *
 * @param block 接收每个观察者作为参数的 Block。
 *
 * @discussion 先以线程安全方式获取当前观察者快照，然后无论调用方是否在主线程，
 *             始终通过 dispatch_async(dispatch_get_main_queue(), ...) 在下一个
 *             RunLoop 主线程上分发。每次调用均用 @try/@catch 包裹，以防止某个观察者
 *             的异常影响其他观察者。
 */
- (void)notifyObservers:(void(^)(id<SlotActionNotificationDelegate> observer))block;

/**
 * @brief 返回当前已注册的观察者数量。
 *
 * @return 活跃观察者的数量。
 */
- (NSUInteger)observerCount;

/**
 * @brief 向所有已注册的观察者异步分发显示章节内容面板通知。
 */
- (void)dispatchShowChapterPanel;

@end

NS_ASSUME_NONNULL_END
