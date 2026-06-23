//
//  BaseLifecycleStrategy.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/22.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseLifecycleStrategy.h"
#import "PlayerFactory.h"
#import "MediaPlayer.h"
#import "Log.h"

@interface BaseLifecycleStrategy () {
    BOOL _initialized;
}

@property (nonatomic, strong, readwrite) id<PlayerFactory> factory;

@end

@implementation BaseLifecycleStrategy

#pragma mark - Setup

- (void)setupWithFactory:(id<PlayerFactory>)factory {
    if (_initialized) {
        SLOGW(@"setupWithFactory: already initialized, ignoring duplicate call.");
        return;
    }
    NSParameterAssert(factory);
    self.factory = factory;
    _initialized = YES;
    SLOGI(@"Setup with factory: %@", NSStringFromClass([factory class]));
}

#pragma mark - Template Methods

- (id<MediaPlayer>)createPlayer {
    NSAssert(self.factory, @"Must call setupWithFactory: before createPlayer");
    id<MediaPlayer> player = [self.factory createPlayer];
    SLOGI(@"Created player (%@)", player);
    return player;
}

- (void)destroyPlayer:(nullable id<MediaPlayer>)player {
    if (!player) return;
    [self.factory destroyPlayer:player];
    SLOGI(@"Destroyed player (%@)", player);
}

@end
