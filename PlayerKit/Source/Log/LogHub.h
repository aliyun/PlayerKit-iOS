//
//  LogHub.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/16.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LogLevel.h"

@protocol LogObserver;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 日志管理中心单例。
 *
 * @discussion 统一管理日志输出和观察者注册。
 *             所有日志操作均通过此单例进行，支持多级别日志过滤。
 *             采用混合线程模型：控制台输出在调用线程同步执行，
 *             观察者通知则异步分派。
 *
 * @warning 日志观察者回调在后台串行队列执行，请勿直接更新 UI。
 * @see LogObserver
 */
@interface LogHub : NSObject

/**
 * @brief 获取 LogHub 共享单例实例。
 *
 * @return LogHub 单例对象。
 */
+ (instancetype)sharedHub;

/**
 * @brief 是否启用日志输出。
 * @discussion 默认为 YES。设置为 NO 时，所有日志请求将被忽略。
 */
@property (nonatomic, assign) BOOL logEnabled;

/**
 * @brief 最低日志输出级别。
 * @discussion 低于此级别的日志将被过滤。默认为 LogLevelInfo。
 */
@property (nonatomic, assign) LogLevel logLevel;

/**
 * @brief 是否启用控制台（NSLog）输出。
 * @discussion 默认为 YES。设置为 NO 时，NSLog 输出被抑制，
 *             但监听者仍会收到日志事件。
 */
@property (nonatomic, assign) BOOL consoleLogEnabled;

#pragma mark - Observer Management

/**
 * @brief 添加日志观察者。
 *
 * @param observer 遵循 LogObserver 协议的观察者对象，不可为 nil。
 *
 * @discussion 观察者被强引用直到通过 removeObserver: 移除。
 *             重复添加同一观察者不会产生效果。
 *
 * @see removeObserver:
 */
- (void)addObserver:(id<LogObserver>)observer;

/**
 * @brief 移除日志观察者。
 *
 * @param observer 要移除的观察者。
 *
 * @see addObserver:
 */
- (void)removeObserver:(id<LogObserver>)observer;

#pragma mark - Log Output

/**
 * @brief 输出 Verbose 级别日志。
 *
 * @param tag     日志标签，标识来源。
 * @param message 日志消息内容。
 */
- (void)v:(NSString *)tag msg:(NSString *)message;

/**
 * @brief 输出 Debug 级别日志。
 *
 * @param tag     日志标签，标识来源。
 * @param message 日志消息内容。
 */
- (void)d:(NSString *)tag msg:(NSString *)message;

/**
 * @brief 输出 Info 级别日志。
 *
 * @param tag     日志标签，标识来源。
 * @param message 日志消息内容。
 */
- (void)i:(NSString *)tag msg:(NSString *)message;

/**
 * @brief 输出 Warn 级别日志。
 *
 * @param tag     日志标签，标识来源。
 * @param message 日志消息内容。
 */
- (void)w:(NSString *)tag msg:(NSString *)message;

/**
 * @brief 输出 Error 级别日志。
 *
 * @param tag     日志标签，标识来源。
 * @param message 日志消息内容。
 */
- (void)e:(NSString *)tag msg:(NSString *)message;

/**
 * @brief 输出 Error 级别日志，附带关联的错误对象。
 *
 * @param tag     日志标签，标识来源。
 * @param message 日志消息内容。
 * @param error   可选的错误对象，提供额外上下文信息。
 */
- (void)e:(NSString *)tag msg:(NSString *)message error:(nullable NSError *)error;

#pragma mark - Core Log Method

/**
 * @brief 带完整源码上下文的核心日志方法（供 SLOG 宏使用）。
 *
 * @param level    日志级别。
 * @param fileName 源文件名（如来自 __FILE_NAME__）。
 * @param line     源代码行号（如来自 __LINE__）。
 * @param message  日志消息内容。
 * @param error    可选的错误对象，可为 nil。
 *
 * @discussion 此方法实现混合线程模型：
 *             1. 检查是否可记录（logEnabled && level >= logLevel）。
 *             2. 在调用线程同步捕获线程名和时间戳。
 *             3. 如果 consoleLogEnabled 为 YES，通过 NSLog 同步输出。
 *             4. 异步分派 LogInfo 构造和监听者通知。
 *
 * @see LogMacros.h
 */
- (void)logLevel:(LogLevel)level
            file:(NSString *)fileName
            line:(NSInteger)line
         message:(NSString *)message
           error:(nullable NSError *)error;

#pragma mark - Common Method

/**
 * @brief 按指定级别输出日志。
 *
 * @param level   日志级别。
 * @param tag     日志标签，标识来源。
 * @param message 日志消息内容。
 *
 * @discussion 这是所有日志输出的旧版通用入口。
 *             处理前会检查 logEnabled 和 logLevel。
 */
- (void)log:(LogLevel)level tag:(NSString *)tag msg:(NSString *)message;

#pragma mark - Level Utility

/**
 * @brief 将日志级别转换为显示字符串。
 *
 * @param level 要转换的日志级别。
 *
 * @return 缩写字符串表示（V/D/I/W/E/N）。
 */
+ (NSString *)levelToString:(LogLevel)level;

/**
 * @brief 将级别名称字符串转换回 LogLevel 枚举值。
 *
 * @param levelName 级别名称字符串（不区分大小写），如 "verbose"、"debug"、"info" 等。
 *
 * @return 对应的 LogLevel 枚举值。如果名称无法识别则返回 LogLevelInfo。
 */
+ (LogLevel)stringToLevel:(NSString *)levelName;

@end

NS_ASSUME_NONNULL_END
