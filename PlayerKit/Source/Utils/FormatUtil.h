//
//  FormatUtil.h
//  AliPlayerKit
//
//  Created by keria on 2026/07/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放时间格式化工具。
 *
 * @discussion 集中提供毫秒时间到显示文本的转换能力，
 *             供 BottomBarSlot、SeekThumbnailSlot 等 UI 组件复用，
 *             避免各插槽重复实现时间格式化逻辑。
 */
@interface FormatUtil : NSObject

/**
 * @brief 将毫秒时间格式化为 mm:ss 或 HH:mm:ss 文本。
 *
 * @param timeMs 时间值，单位毫秒。
 *
 * @return 格式化文本：时长 >= 1 小时时返回 "HH:mm:ss"，否则返回 "mm:ss"。
 */
+ (NSString *)formatTime:(int64_t)timeMs;

/**
 * @brief 按本地化格式串将「当前位置 / 总时长」格式化为组合文本。
 *
 * @param currentMs  当前位置，单位毫秒。
 * @param durationMs 总时长，单位毫秒。
 * @param format     四参数格式串（如 "%02ld:%02ld / %02ld:%02ld"），
 *                   依次接收当前分钟、当前秒、总分钟、总秒。
 *
 * @return 格式化后的组合时间文本。
 *
 * @discussion 与 BottomBarSlot 原有实现行为完全一致：
 *             分钟数不折算小时（可超过 59），由格式串决定最终展示样式。
 */
+ (NSString *)formatTimeString:(NSInteger)currentMs
                      duration:(NSInteger)durationMs
                        format:(NSString *)format;

@end

NS_ASSUME_NONNULL_END
