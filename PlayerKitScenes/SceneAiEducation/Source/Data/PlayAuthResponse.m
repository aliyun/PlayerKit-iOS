//
//  PlayAuthResponse.m
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "PlayAuthResponse.h"
#import "SafeValueHelper.h"

@implementation PlayAuthData

#pragma mark - Public Methods

+ (nullable instancetype)dataWithDictionary:(nullable NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    PlayAuthData *data = [[PlayAuthData alloc] init];
    data.videoId = SafeString(dictionary[@"videoId"]);
    data.playAuth = SafeString(dictionary[@"playAuth"]);
    return data;
}

@end

@implementation PlayAuthResponse

#pragma mark - Public Methods

+ (nullable instancetype)responseWithDictionary:(nullable NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    PlayAuthResponse *response = [[PlayAuthResponse alloc] init];
    response.code = SafeInteger(dictionary[@"code"], -1);
    response.success = SafeBool(dictionary[@"success"], NO);
    response.data = [PlayAuthData dataWithDictionary:dictionary[@"data"]];
    return response;
}

@end
