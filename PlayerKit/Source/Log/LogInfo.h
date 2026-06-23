//
//  LogInfo.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/16.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LogLevel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 日志信息数据模型。
 *
 * @discussion 封装单条日志条目的所有属性，包括级别、标签、消息、时间戳、
 *             源文件、行号、线程名称和可选错误。
 *             用于日志输出和观察者回调。
 *
 * @see LogHub
 * @see LogObserver
 */
@interface LogInfo : NSObject

/**
 * @brief 日志级别。
 * @discussion 表示此日志条目的严重程度。
 */
@property (nonatomic, assign, readonly) LogLevel level;

/**
 * @brief 日志标签。
 * @discussion 标识日志来源，通常为类名或模块名。
 */
@property (nonatomic, copy, readonly) NSString *tag;

/**
 * @brief 日志消息内容。
 */
@property (nonatomic, copy, readonly) NSString *message;

/**
 * @brief 日志生成时间戳。
 * @discussion 在 LogInfo 对象创建时记录。
 */
@property (nonatomic, strong, readonly) NSDate *timestamp;

/**
 * @brief 生成日志的线程名称。
 * @discussion 捕获调用线程的名称。如果线程没有名称，可能为空。
 */
@property (nonatomic, copy, readonly) NSString *threadName;

/**
 * @brief 生成日志的源文件名。
 * @discussion 通常为不含路径的文件名，例如 @"MyClass.m"。
 */
@property (nonatomic, copy, readonly) NSString *fileName;

/**
 * @brief 生成日志的源代码行号。
 * @discussion 源文件中的行号。如果不可用则为 0。
 */
@property (nonatomic, assign, readonly) NSInteger line;

/**
 * @brief 与此日志条目关联的可选错误。
 * @discussion 当日志记录错误条件时为非 nil。包含 domain、code 和 userInfo。
 */
@property (nonatomic, strong, readonly, nullable) NSError *error;

/**
 * @brief 包含完整日志上下文的指定初始化方法。
 *
 * @param level     日志级别。
 * @param fileName  生成日志的源文件名。
 * @param line      源代码行号。
 * @param message   日志消息内容。
 * @param error     可选的错误对象，可为 nil。
 * @param threadName 生成日志的线程名称。
 * @param timestamp 日志生成的时间戳。
 *
 * @return 已初始化的 LogInfo 实例。
 */
- (instancetype)initWithLevel:(LogLevel)level
                     fileName:(NSString *)fileName
                         line:(NSInteger)line
                      message:(NSString *)message
                        error:(nullable NSError *)error
                   threadName:(NSString *)threadName
                    timestamp:(NSDate *)timestamp;

/**
 * @brief 便捷初始化方法（向后兼容）。
 *
 * @param level   日志级别。
 * @param tag     日志标签，用于标识日志来源。
 * @param message 日志消息内容。
 *
 * @return 自动捕获时间戳和线程名称的已初始化 LogInfo 实例。
 *
 * @discussion 内部调用指定初始化方法。tag 用作 fileName，
 *             line 默认为 0，error 默认为 nil，threadName 和 timestamp
 *             自动捕获。
 */
- (instancetype)initWithLevel:(LogLevel)level
                          tag:(NSString *)tag
                      message:(NSString *)message;

/**
 * @brief 获取格式化的日志字符串。
 *
 * @return 格式化字符串，形式为：
 *         "2024-04-22 10:30:00.123 I/AliPlayerKit [version] [FileName:line] [threadName] : message"
 *
 * @discussion 用于控制台输出或日志文件写入。
 *             如果存在错误，将附加额外一行：
 *             "Error: domain=xxx code=xxx userInfo=xxx"
 */
- (NSString *)formattedString;

@end

NS_ASSUME_NONNULL_END
