//
//  DefaultLifecycleStrategy.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "DefaultLifecycleStrategy.h"
#import "Log.h"

@implementation DefaultLifecycleStrategy

#pragma mark - PlayerLifecycleStrategy

- (id<MediaPlayer>)acquirePlayer {
    return [self createPlayer];
}

- (void)recyclePlayer:(nullable id<MediaPlayer>)player force:(BOOL)force {
    if (!player) return;
    [self destroyPlayer:player];
}

- (void)clear {
    SLOGI(@"Clear (no-op for default strategy)");
}

@end
