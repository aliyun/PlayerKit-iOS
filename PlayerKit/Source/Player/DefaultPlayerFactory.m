//
//  DefaultPlayerFactory.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "DefaultPlayerFactory.h"
#import "AliMediaPlayer.h"
#import "Log.h"

@implementation DefaultPlayerFactory

#pragma mark - PlayerFactory

- (id<MediaPlayer>)createPlayer {
    id<MediaPlayer> player = [[AliMediaPlayer alloc] init];
    SLOGI(@"Player created");
    return player;
}

- (void)destroyPlayer:(nullable id<MediaPlayer>)player {
    if (!player) {
        SLOGW(@"Player is nil");
        return;
    }
    [player destroy];
    SLOGI(@"Player destroyed");
}

@end
