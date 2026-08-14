//
//  ChapterMarkerView.h
//  AliPlayerKit
//
//  Created by keria on 2026/8/3.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 章节标记 View。
 *
 * @discussion 在进度条轨道上绘制章节分割标记竖线。
 *             每个标记点表示一个章节的起始位置，以竖线形式绘制。
 *             作为 UISlider 的兄弟 View 叠加显示，不拦截触摸手势。
 */
@interface ChapterMarkerView : UIView

/**
 * @brief 设置章节标记归一化位置。
 *
 * @discussion 传入归一化 0.0~1.0 的位置数组，内部自动过滤 <= 0 或 >= 1 的无效值。
 *             调用后触发重绘。
 *
 * @param positions 归一化位置数组（float 值封装为 NSNumber）。
 */
- (void)setMarkerPositions:(NSArray<NSNumber *> *)positions;

@end

NS_ASSUME_NONNULL_END
