//
//  PlayerFont.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright (c) 2024 Alibaba Cloud. All rights reserved.
//

#import "PlayerFont.h"

@implementation PlayerFont

+ (UIFont *)regular12 {
    return [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
}

+ (UIFont *)regular14 {
    return [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
}

+ (UIFont *)regular16 {
    return [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
}

+ (UIFont *)bold14 {
    return [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
}

+ (UIFont *)bold16 {
    return [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
}

+ (UIFont *)monospacedDigit14 {
    return [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightRegular];
}

@end
