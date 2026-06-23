//
//  LogLevelFormatter.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ValueFormatter.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 日志等级格式化器。
 *
 * @discussion 负责 LogLevel（NSNumber 包装 NSInteger）与显示字符串之间的双向转换。
 *             对标 Android 端 LogLevelFormatter。
 *
 * @see ValueFormatter
 * @see LogLevel
 */
@interface LogLevelFormatter : NSObject <ValueFormatter>

@end

NS_ASSUME_NONNULL_END
