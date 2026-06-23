//
//  LinkItem.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 链接配置项数据模型。
 *
 * @discussion 用于存储单个链接配置项的数据，包括显示名称、存储键名以及链接内容。
 *             支持视频 URL、Vid、PlayAuth、直播地址等多种类型的链接配置。
 *             对标 Android 端的 LinkItem。
 *
 * @see LinkConstants
 * @see LinkViewController
 */
@interface LinkItem : NSObject

/** @brief 配置项显示名称。 */
@property (nonatomic, copy, readonly) NSString *name;

/** @brief 存储键名，对应 UserDefaultsManager 中的 Key。 */
@property (nonatomic, copy, readonly) NSString *key;

/** @brief 当前配置的链接或 ID 内容。 */
@property (nonatomic, copy, nullable) NSString *link;

/**
 * @brief 创建链接配置项。
 *
 * @param name 配置项显示名称。
 * @param key 存储键名。
 *
 * @return 链接配置项实例。
 */
+ (instancetype)itemWithName:(NSString *)name key:(NSString *)key;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
