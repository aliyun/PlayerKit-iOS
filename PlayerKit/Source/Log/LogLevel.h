//
//  LogLevel.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/16.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * @brief 日志级别枚举。
 *
 * @discussion 定义日志消息的严重程度，用于过滤和分类。
 *             级别从低到高：Verbose < Debug < Info < Warn < Error < None。
 *             使用 LogLevelNone 可以抑制所有日志输出。
 */
typedef NS_ENUM(NSInteger, LogLevel) {
    /** Verbose 级别，用于最详细的调试信息。 */
    LogLevelVerbose = 0,

    /** Debug 级别，用于开发阶段的调试信息。 */
    LogLevelDebug   = 1,

    /** Info 级别，用于一般运行时信息（默认级别）。 */
    LogLevelInfo    = 2,

    /** Warn 级别，用于潜在问题警告。 */
    LogLevelWarn    = 3,

    /** Error 级别，用于错误和异常信息。 */
    LogLevelError   = 4,

    /** None 级别，用于抑制所有日志输出。 */
    LogLevelNone    = 100
};

/**
 * @brief 将日志级别转换为简短字符串表示。
 *
 * @param level 日志级别枚举值。
 *
 * @return 级别的缩写字符串：V/D/I/W/E/N。
 */
NS_INLINE NSString *LogLevelToString(LogLevel level) {
    switch (level) {
        case LogLevelVerbose: return @"V";
        case LogLevelDebug:   return @"D";
        case LogLevelInfo:    return @"I";
        case LogLevelWarn:    return @"W";
        case LogLevelError:   return @"E";
        case LogLevelNone:    return @"N";
    }
    return @"?";
}
