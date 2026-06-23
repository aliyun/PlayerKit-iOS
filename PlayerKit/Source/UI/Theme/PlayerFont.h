//
//  PlayerFont.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright (c) 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerFont : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (UIFont *)regular12;
+ (UIFont *)regular14;
+ (UIFont *)regular16;
+ (UIFont *)bold14;
+ (UIFont *)bold16;
+ (UIFont *)monospacedDigit14;

@end

NS_ASSUME_NONNULL_END
