//
//  SingletonLifecycleStrategy.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SingletonLifecycleStrategy.h"
#import "MediaPlayer.h"
#import "Log.h"

static id<MediaPlayer> sSharedPlayer = nil;

@implementation SingletonLifecycleStrategy

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static SingletonLifecycleStrategy *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

#pragma mark - PlayerLifecycleStrategy

- (id<MediaPlayer>)acquirePlayer {
    if (!sSharedPlayer) {
        sSharedPlayer = [self createPlayer];
        SLOGI(@"Acquired player (created singleton) (%@)", sSharedPlayer);
    } else {
        SLOGI(@"Acquired player (reused singleton) (%@)", sSharedPlayer);
    }
    return sSharedPlayer;
}

- (void)recyclePlayer:(nullable id<MediaPlayer>)player force:(BOOL)force {
    if (!player) return;

    if (force) {
        if (player == sSharedPlayer) {
            sSharedPlayer = nil;
        }
        [self destroyPlayer:player];
        SLOGI(@"Recycled player (force destroyed singleton) (%@)", player);
        return;
    }

    [player stop];
    player.notificationDispatcher = nil;
    SLOGI(@"Recycled player (singleton kept alive) (%@)", player);
}

- (void)clear {
    id<MediaPlayer> player = sSharedPlayer;
    sSharedPlayer = nil;
    if (player) {
        [self destroyPlayer:player];
        SLOGI(@"Cleared singleton player (%@)", player);
    }
}

@end
