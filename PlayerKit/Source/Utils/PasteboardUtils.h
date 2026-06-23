//
//  PasteboardUtils.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 统一剪贴板工具。
 *
 * @discussion 封装系统 UIPasteboard，提供便捷的文本复制能力。
 */
@interface PasteboardUtils : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 * @brief 将文本复制到系统剪贴板。
 *
 * @param text 要复制的文本，如果为 nil 或空字符串则不处理。
 *
 * @return YES 表示复制成功，NO 表示复制失败（text 为空）。
 */
+ (BOOL)copyText:(nullable NSString *)text;

@end

NS_ASSUME_NONNULL_END
