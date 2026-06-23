//
//  LogHub.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/16.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "LogHub.h"
#import "LogInfo.h"
#import "LogObserver.h"
#import "AliPlayerKit.h"
#import <pthread.h>

/// 播放组件名称
static NSString * const kComponentName = @"AliPlayerKit";

@interface LogHub ()

@property (nonatomic, strong) NSHashTable<id<LogObserver>> *observers;
@property (nonatomic, strong) dispatch_queue_t logQueue;

@end

@implementation LogHub

static LogHub *_sharedInstance = nil;

#pragma mark - Thread Helper

/// 获取当前线程的显示名称。
/// 优先级：
/// 1. 如果是主线程，返回固定名称 "main"
/// 2. 如果当前线程设置了 name，返回线程 name
/// 3. 如果线程没有 name，则返回当前线程的 pthread / mach thread id
static inline NSString *CurrentThreadNameOrID(void) {
    if ([NSThread isMainThread]) {
        return @"main";
    }

    NSString *name = NSThread.currentThread.name;
    if (name.length > 0) {
        return name;
    }

    mach_port_t tid = pthread_mach_thread_np(pthread_self());
    return [NSString stringWithFormat:@"tid:%u", tid];
}

#pragma mark - Lifecycle

+ (instancetype)sharedHub {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[LogHub alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logEnabled = YES;
        _logLevel = LogLevelInfo;
        _consoleLogEnabled = YES;
        _observers = [NSHashTable weakObjectsHashTable];
        _logQueue = dispatch_queue_create("com.aliyun.playerkit.log", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Observer Management

- (void)addObserver:(id<LogObserver>)observer {
    if (!observer) return;
    // dispatch_sync on serial logQueue guarantees thread-safe access;
    // NSHashTable naturally prevents duplicate entries.
    dispatch_sync(self.logQueue, ^{
        [self.observers addObject:observer];
    });
}

- (void)removeObserver:(id<LogObserver>)observer {
    if (!observer) return;
    dispatch_sync(self.logQueue, ^{
        [self.observers removeObject:observer];
    });
}

#pragma mark - Log Output

- (void)v:(NSString *)tag msg:(NSString *)message {
    [self log:LogLevelVerbose tag:tag msg:message];
}

- (void)d:(NSString *)tag msg:(NSString *)message {
    [self log:LogLevelDebug tag:tag msg:message];
}

- (void)i:(NSString *)tag msg:(NSString *)message {
    [self log:LogLevelInfo tag:tag msg:message];
}

- (void)w:(NSString *)tag msg:(NSString *)message {
    [self log:LogLevelWarn tag:tag msg:message];
}

- (void)e:(NSString *)tag msg:(NSString *)message {
    [self log:LogLevelError tag:tag msg:message];
}

- (void)e:(NSString *)tag msg:(NSString *)message error:(nullable NSError *)error {
    [self logLevel:LogLevelError file:tag line:0 message:message error:error];
}

#pragma mark - Core Log Method

- (void)logLevel:(LogLevel)level
            file:(NSString *)fileName
            line:(NSInteger)line
         message:(NSString *)message
           error:(nullable NSError *)error {
    // 检查是否可记录
    if (![self isLoggable:level]) return;
    
    // 同步区域 - 在调用线程上捕获
    NSString *threadName = CurrentThreadNameOrID();
    NSDate *timestamp = [NSDate date];
    
    // 同步控制台输出
    if (self.consoleLogEnabled) {
        NSString *levelStr = LogLevelToString(level);
        NSString *version = [AliPlayerKit getPlayerKitVersion] ?: @"unknown";
        NSString *fileNameWithoutExt = [self stripExtension:fileName];
        NSLog(@"%@/%@ [%@] [%@:%ld] : %@", levelStr, kComponentName, version, fileNameWithoutExt, (long)line, message);
        if (error) {
            NSLog(@"Error: domain=%@ code=%ld userInfo=%@", error.domain, (long)error.code, error.userInfo);
        }
    }
    
    // 异步区域 - 构建 LogInfo 并通知观察者
    dispatch_async(self.logQueue, ^{
        LogInfo *logInfo = [[LogInfo alloc] initWithLevel:level
                                                 fileName:fileName
                                                     line:line
                                                  message:message
                                                    error:error
                                               threadName:threadName
                                                timestamp:timestamp];
        
        NSArray<id<LogObserver>> *snapshot = [self.observers allObjects];
        NSMutableArray<id<LogObserver>> *faultyObservers = nil;
        for (id<LogObserver> observer in snapshot) {
            @try {
                [observer onLog:logInfo];
            } @catch (NSException *exception) {
                NSLog(@"LogObserver error: %@, removing observer: %@", exception, observer);
                if (!faultyObservers) {
                    faultyObservers = [NSMutableArray array];
                }
                [faultyObservers addObject:observer];
            }
        }
        if (faultyObservers.count > 0) {
            for (id<LogObserver> faulty in faultyObservers) {
                [self.observers removeObject:faulty];
            }
        }
    });
}

#pragma mark - Common Method

- (void)log:(LogLevel)level tag:(NSString *)tag msg:(NSString *)message {
    [self logLevel:level file:tag line:0 message:message error:nil];
}

#pragma mark - Level Utility

+ (NSString *)levelToString:(LogLevel)level {
    return LogLevelToString(level);
}

+ (LogLevel)stringToLevel:(NSString *)levelName {
    NSString *lower = [levelName lowercaseString];
    if ([lower isEqualToString:@"verbose"] || [lower isEqualToString:@"v"]) return LogLevelVerbose;
    if ([lower isEqualToString:@"debug"] || [lower isEqualToString:@"d"]) return LogLevelDebug;
    if ([lower isEqualToString:@"info"] || [lower isEqualToString:@"i"]) return LogLevelInfo;
    if ([lower isEqualToString:@"warn"] || [lower isEqualToString:@"w"]) return LogLevelWarn;
    if ([lower isEqualToString:@"error"] || [lower isEqualToString:@"e"]) return LogLevelError;
    if ([lower isEqualToString:@"none"] || [lower isEqualToString:@"n"]) return LogLevelNone;
    return LogLevelInfo;
}

#pragma mark - Private Methods

- (BOOL)isLoggable:(LogLevel)level {
    return self.logEnabled && level >= self.logLevel;
}

- (NSString *)stripExtension:(NSString *)fileName {
    // 移除 .m / .mm / .h 扩展名
    NSString *ext = [fileName pathExtension];
    if ([ext isEqualToString:@"m"] || [ext isEqualToString:@"mm"] || [ext isEqualToString:@"h"]) {
        return [fileName stringByDeletingPathExtension];
    }
    return fileName;
}

@end
