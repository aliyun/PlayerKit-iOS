//
//  VideoSource.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "VideoSource.h"

@interface VideoSource ()

@property (nonatomic, assign, readwrite) VideoSourceType sourceType;
@property (nonatomic, copy, readwrite, nullable) NSString *url;
@property (nonatomic, copy, readwrite, nullable) NSString *vid;
@property (nonatomic, copy, readwrite, nullable) NSString *accessKeyId;
@property (nonatomic, copy, readwrite, nullable) NSString *accessKeySecret;
@property (nonatomic, copy, readwrite, nullable) NSString *securityToken;
@property (nonatomic, copy, readwrite, nullable) NSString *region;
@property (nonatomic, copy, readwrite, nullable) NSString *playAuth;

@end

@implementation VideoSource

#pragma mark - Lifecycle

- (instancetype)initWithType:(VideoSourceType)type {
    self = [super init];
    if (self) {
        _sourceType = type;
    }
    return self;
}

#pragma mark - Public Methods

+ (instancetype)urlSourceWithUrl:(NSString *)url {
    if (!url || url.length == 0) return nil;
    VideoSource *source = [[VideoSource alloc] initWithType:VideoSourceTypeUrl];
    source.url = url;
    return source;
}

+ (instancetype)vidStsSourceWithVid:(NSString *)vid
                        accessKeyId:(NSString *)accessKeyId
                    accessKeySecret:(NSString *)accessKeySecret
                      securityToken:(NSString *)securityToken
                             region:(nullable NSString *)region {
    if (!vid || vid.length == 0) return nil;
    if (!accessKeyId || accessKeyId.length == 0) return nil;
    if (!accessKeySecret || accessKeySecret.length == 0) return nil;
    if (!securityToken || securityToken.length == 0) return nil;
    VideoSource *source = [[VideoSource alloc] initWithType:VideoSourceTypeVidSts];
    source.vid = vid;
    source.accessKeyId = accessKeyId;
    source.accessKeySecret = accessKeySecret;
    source.securityToken = securityToken;
    source.region = region;
    return source;
}

+ (instancetype)vidAuthSourceWithVid:(NSString *)vid
                            playAuth:(NSString *)playAuth {
    if (!vid || vid.length == 0) return nil;
    if (!playAuth || playAuth.length == 0) return nil;
    VideoSource *source = [[VideoSource alloc] initWithType:VideoSourceTypeVidAuth];
    source.vid = vid;
    source.playAuth = playAuth;
    return source;
}

- (NSString *)uniqueId {
    switch (self.sourceType) {
        case VideoSourceTypeVidAuth:
        case VideoSourceTypeVidSts:
            return self.vid;
        case VideoSourceTypeUrl:
            return self.url;
    }
    return nil;
}

- (BOOL)isValid {
    switch (self.sourceType) {
        case VideoSourceTypeUrl:
            return self.url.length > 0;
        case VideoSourceTypeVidSts:
            return self.vid.length > 0
                && self.accessKeyId.length > 0
                && self.accessKeySecret.length > 0
                && self.securityToken.length > 0;
        case VideoSourceTypeVidAuth:
            return self.vid.length > 0
                && self.playAuth.length > 0;
    }
    return NO;
}

- (NSString *)description {
    switch (self.sourceType) {
        case VideoSourceTypeUrl:
            return [NSString stringWithFormat:@"<VideoSource: URL=%@>", self.url];
        case VideoSourceTypeVidSts:
            return [NSString stringWithFormat:@"<VideoSource: VidSts, vid=%@, region=%@>", self.vid, self.region];
        case VideoSourceTypeVidAuth:
            return [NSString stringWithFormat:@"<VideoSource: VidAuth, vid=%@>", self.vid];
    }
    return [super description];
}

@end
