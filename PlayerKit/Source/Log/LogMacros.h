//
//  LogMacros.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/16.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "LogHub.h"
#import "LogLevel.h"

/**
 * @brief 自动捕获源码位置的结构化日志便捷宏。
 *
 * @discussion 这些宏使用 __FILE_NAME__（Clang 扩展）和 __LINE__ 自动捕获调用处的
 *             源文件名和行号。每个宏对应一个日志级别：SLOGV（Verbose）、SLOGD（Debug）、
 *             SLOGI（Info）、SLOGW（Warn）、SLOGE（Error）。
 *
 * @see LogHub
 * @see LogLevel
 */

/** @brief 记录 Verbose 级别日志，自动捕获源码位置。 */
#define SLOGV(fmt, ...) \
    [[LogHub sharedHub] logLevel:LogLevelVerbose \
                            file:@(__FILE_NAME__) \
                            line:__LINE__ \
                         message:[NSString stringWithFormat:(fmt), ##__VA_ARGS__] \
                           error:nil]

/** @brief 记录 Debug 级别日志，自动捕获源码位置。 */
#define SLOGD(fmt, ...) \
    [[LogHub sharedHub] logLevel:LogLevelDebug \
                            file:@(__FILE_NAME__) \
                            line:__LINE__ \
                         message:[NSString stringWithFormat:(fmt), ##__VA_ARGS__] \
                           error:nil]

/** @brief 记录 Info 级别日志，自动捕获源码位置。 */
#define SLOGI(fmt, ...) \
    [[LogHub sharedHub] logLevel:LogLevelInfo \
                            file:@(__FILE_NAME__) \
                            line:__LINE__ \
                         message:[NSString stringWithFormat:(fmt), ##__VA_ARGS__] \
                           error:nil]

/** @brief 记录 Warn 级别日志，自动捕获源码位置。 */
#define SLOGW(fmt, ...) \
    [[LogHub sharedHub] logLevel:LogLevelWarn \
                            file:@(__FILE_NAME__) \
                            line:__LINE__ \
                         message:[NSString stringWithFormat:(fmt), ##__VA_ARGS__] \
                           error:nil]

/** @brief 记录 Error 级别日志，自动捕获源码位置。 */
#define SLOGE(fmt, ...) \
    [[LogHub sharedHub] logLevel:LogLevelError \
                            file:@(__FILE_NAME__) \
                            line:__LINE__ \
                         message:[NSString stringWithFormat:(fmt), ##__VA_ARGS__] \
                           error:nil]
