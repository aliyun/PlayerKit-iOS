//
//  SafeValueHelper.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#ifndef SafeValueHelper_h
#define SafeValueHelper_h

#import <Foundation/Foundation.h>

/// 类型安全取字符串 — 用于确定为字符串类型的字段（如 title、summary 等）；
/// 非 NSString 返回 nil
static inline NSString * _Nullable SafeString(id _Nullable value) {
    return [value isKindOfClass:[NSString class]] ? (NSString *)value : nil;
}

/// 类型安全取字符串 — 用于可能从 API 返回为数字或字符串的 ID 字段
/// （如 chapterId、segmentId、pointId）；NSNumber 自动转字符串，其他非法类型返回 nil
static inline NSString * _Nullable SafeStringOrNumber(id _Nullable value) {
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value stringValue];
    }
    return nil;
}

/// 类型安全取整数（毫秒时间等）：支持 NSNumber / NSString，其他类型返回默认值
static inline NSInteger SafeInteger(id _Nullable value, NSInteger defaultValue) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value integerValue];
    }
    if ([value isKindOfClass:[NSString class]]) {
        return [(NSString *)value integerValue];
    }
    return defaultValue;
}

/// 类型安全取布尔：非 NSNumber 返回默认值
static inline BOOL SafeBool(id _Nullable value, BOOL defaultValue) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value boolValue];
    }
    return defaultValue;
}

#endif /* SafeValueHelper_h */
