//
//  ChapterChipCell.h
//  AliPlayerKit
//
//  Created by keria on 2026/8/3.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 章节 Chip 单元格。
 *
 * @discussion 用于横向 UICollectionView 中显示章节导航 Chip。
 *             支持选中/未选中状态切换背景色与文字色。
 */
@interface ChapterChipCell : UICollectionViewCell

/**
 * @brief 配置 Chip 显示文案及选中状态。
 *
 * @param text      Chip 文本（格式：“MM:SS 标题”）。
 * @param isCurrent 是否为当前播放章节。
 */
- (void)configureWithText:(NSString *)text isCurrent:(BOOL)isCurrent;

@end

NS_ASSUME_NONNULL_END
