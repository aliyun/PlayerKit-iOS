//
//  LogInfo.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/16.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "LogInfo.h"
#import "AliPlayerKit.h"

@implementation LogInfo

#pragma mark - Lifecycle

- (instancetype)initWithLevel:(LogLevel)level
                     fileName:(NSString *)fileName
                         line:(NSInteger)line
                      message:(NSString *)message
                        error:(nullable NSError *)error
                   threadName:(NSString *)threadName
                    timestamp:(NSDate *)timestamp {
    self = [super init];
    if (self) {
        _level = level;
        _tag = @"AliPlayerKit";
        _fileName = [fileName copy];
        _line = line;
        _message = [message copy];
        _error = error;
        _threadName = [threadName copy];
        _timestamp = timestamp;
    }
    return self;
}

- (instancetype)initWithLevel:(LogLevel)level
                          tag:(NSString *)tag
                      message:(NSString *)message {
    // Capture thread name and timestamp on the calling thread
    NSString *threadName = NSThread.currentThread.name ?: @"";
    NSDate *timestamp = [NSDate date];
    
    self = [self initWithLevel:level
                      fileName:tag
                          line:0
                       message:message
                         error:nil
                    threadName:threadName
                     timestamp:timestamp];
    if (self) {
        _tag = [tag copy];
    }
    return self;
}

#pragma mark - Public Methods

- (NSString *)formattedString {
    // Date formatter
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    
    NSString *timeStr = [formatter stringFromDate:self.timestamp];
    NSString *levelStr = LogLevelToString(self.level);
    
    // Get version string
    NSString *version = [AliPlayerKit getPlayerKitVersion];
    if (!version) {
        version = @"unknown";
    }
    
    // Build formatted string
    NSMutableString *result = [NSMutableString stringWithFormat:@"%@ %@/%@ [%@] [%@:%ld] [%@] : %@",
                               timeStr,
                               levelStr,
                               self.tag,
                               version,
                               self.fileName,
                               (long)self.line,
                               self.threadName,
                               self.message];
    
    // Append error info if present
    if (self.error) {
        [result appendFormat:@"\nError: domain=%@ code=%ld userInfo=%@",
         self.error.domain,
         (long)self.error.code,
         self.error.userInfo];
    }
    
    return [result copy];
}

#pragma mark - NSObject

- (NSString *)description {
    return [self formattedString];
}

@end
