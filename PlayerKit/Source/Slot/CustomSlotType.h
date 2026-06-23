//
//  CustomSlotType.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 自定义插槽类型，用于在内置插槽之间插入业务自定义插槽。
 *
 * @discussion 内置 SlotType 枚举值按间隔 10 排列（0, 10, 20...100）。
 *             CustomSlotType 通过 @c order 字段指定插入位置，
 *             在 rebuildSlots 时与内置插槽按 order 统一排序。
 *
 *             相等判断仅基于 @c key，同一 key 不可重复注册。
 *
 * @code
 * // 在 TopBar(80) 和 BottomBar(90) 之间插入自定义插槽
 * CustomSlotType *type = [CustomSlotType typeWithKey:@"myCustomSlot" order:85];
 * [playerView.slotManager registerCustomSlotType:type provider:^UIView<SlotProtocol> *(UIView *parentView) {
 *     return [[MyCustomSlotView alloc] initWithFrame:parentView.bounds];
 * }];
 * @endcode
 *
 * @see SlotManager
 * @see SlotType
 */
@interface CustomSlotType : NSObject <NSCopying>

/** @brief 唯一标识 key，用于注册、查找和相等判断。 */
@property (nonatomic, copy, readonly) NSString *key;

/** @brief 排序值，决定插槽在 Z 轴上的位置。值越小越靠下。 */
@property (nonatomic, assign, readonly) NSInteger order;

/**
 * @brief 创建自定义插槽类型实例。
 *
 * @param key   唯一标识 key，不可为空。
 * @param order 排序值，决定与内置插槽的相对位置。
 *
 * @return 自定义插槽类型实例。
 */
+ (instancetype)typeWithKey:(NSString *)key order:(NSInteger)order;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
