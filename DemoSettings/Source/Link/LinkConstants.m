//
//  LinkConstants.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "LinkConstants.h"
#import "LinkItem.h"

#pragma mark - Storage Keys

NSString * const LinkKeyVideoURL                    = @"key_video_url";
NSString * const LinkKeyVideoVid                    = @"key_video_vid";
NSString * const LinkKeyVideoPlayAuth               = @"key_video_play_auth";
NSString * const LinkKeyVideoLiveURL                = @"key_video_live_url";
NSString * const LinkKeyVideoVidStsVid              = @"key_video_vid_sts_vid";
NSString * const LinkKeyVideoVidStsAccessKeyId      = @"key_video_vid_sts_access_key_id";
NSString * const LinkKeyVideoVidStsAccessKeySecret  = @"key_video_vid_sts_access_key_secret";
NSString * const LinkKeyVideoVidStsSecurityToken    = @"key_video_vid_sts_security_token";
NSString * const LinkKeyVideoVidStsRegion           = @"key_video_vid_sts_region";

@implementation LinkConstants

+ (NSArray<LinkItem *> *)buildDefaultItems {
    return @[
        [LinkItem itemWithName:@"Video URL"             key:LinkKeyVideoURL],
        [LinkItem itemWithName:@"Video Vid"             key:LinkKeyVideoVid],
        [LinkItem itemWithName:@"Video PlayAuth"        key:LinkKeyVideoPlayAuth],
        [LinkItem itemWithName:@"Live URL"              key:LinkKeyVideoLiveURL],
        [LinkItem itemWithName:@"VidSts Vid"            key:LinkKeyVideoVidStsVid],
        [LinkItem itemWithName:@"VidSts AccessKeyId"    key:LinkKeyVideoVidStsAccessKeyId],
        [LinkItem itemWithName:@"VidSts AccessKeySecret" key:LinkKeyVideoVidStsAccessKeySecret],
        [LinkItem itemWithName:@"VidSts SecurityToken"  key:LinkKeyVideoVidStsSecurityToken],
        [LinkItem itemWithName:@"VidSts Region"         key:LinkKeyVideoVidStsRegion],
    ];
}

@end
