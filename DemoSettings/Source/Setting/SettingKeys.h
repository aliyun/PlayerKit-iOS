//
//  SettingKeys.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 设置项持久化存储键名常量。
 *
 * @discussion 集中定义所有设置项使用的 UserDefaultsManager 存储键名，确保模块内引用一致。
 *             对标 Android 端 SettingKeys。
 *
 * @see UserDefaultsManager
 */
@interface SettingKeys : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/** 日志面板开关 */
extern NSString * const SettingKeyEnableLogPanel;

/** 日志等级 */
extern NSString * const SettingKeyLogLevel;

/** Debug 模式开关 */
extern NSString * const SettingKeyDebugMode;

@end

NS_ASSUME_NONNULL_END
