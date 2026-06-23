//
//  PlayerViewState.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/19.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "PlayerViewState.h"
#import "Log.h"

@interface PlayerViewState ()

@property (nonatomic, assign, readwrite, getter=isFullscreen) BOOL fullscreen;
@property (nonatomic, assign, readwrite) BOOL controlsVisible;

@end

@implementation PlayerViewState

- (instancetype)init {
    self = [super init];
    if (self) {
        [self reset];
    }
    return self;
}

- (void)reset {
    _fullscreen = NO;
    _controlsVisible = NO;
}

- (void)updateFullscreen:(BOOL)fullscreen {
    if (_fullscreen == fullscreen) {
        return;
    }
    _fullscreen = fullscreen;
}

- (void)updateControlsVisible:(BOOL)controlsVisible {
    if (_controlsVisible == controlsVisible) {
        return;
    }
    _controlsVisible = controlsVisible;
}

@end
