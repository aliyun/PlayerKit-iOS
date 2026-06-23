//
//  LogLevelFormatter.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "LogLevelFormatter.h"

#if __has_include(<PlayerKit/LogLevel.h>)
#import <PlayerKit/LogLevel.h>
#import <PlayerKit/AliPlayerKit.h>
#else
#import "LogLevel.h"
#import "AliPlayerKit.h"
#endif

@implementation LogLevelFormatter

#pragma mark - ValueFormatter

- (NSString *)formatValue:(nullable id)value {
    if (!value) {
        return [self displayStringForLevel:[[self defaultValue] integerValue]];
    }
    return [self displayStringForLevel:[value integerValue]];
}

- (nullable id)parseDisplayString:(NSString *)displayString {
    NSString *lower = [displayString lowercaseString];
    if ([lower isEqualToString:@"verbose"]) return @(LogLevelVerbose);
    if ([lower isEqualToString:@"debug"])   return @(LogLevelDebug);
    if ([lower isEqualToString:@"info"])    return @(LogLevelInfo);
    if ([lower isEqualToString:@"warn"])    return @(LogLevelWarn);
    if ([lower isEqualToString:@"error"])   return @(LogLevelError);
    if ([lower isEqualToString:@"none"])    return @(LogLevelNone);
    return [self defaultValue];
}

- (id)defaultValue {
    return @([AliPlayerKit logLevel]);
}

#pragma mark - Private Methods

- (NSString *)displayStringForLevel:(NSInteger)level {
    switch ((LogLevel)level) {
        case LogLevelVerbose: return @"Verbose";
        case LogLevelDebug:   return @"Debug";
        case LogLevelInfo:    return @"Info";
        case LogLevelWarn:    return @"Warn";
        case LogLevelError:   return @"Error";
        case LogLevelNone:    return @"None";
    }
    return @"Info";
}

@end
