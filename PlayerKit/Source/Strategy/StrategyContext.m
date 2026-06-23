//
//  StrategyContext.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "StrategyContext.h"
#import "AliPlayerController.h"
#import "PlayerStateStore.h"

@interface StrategyContext ()

@property (nonatomic, weak, readwrite) AliPlayerController *controller;
@property (nonatomic, strong, readwrite) AliPlayerModel *playerModel;

@end

@implementation StrategyContext

#pragma mark - Lifecycle

- (instancetype)initWithController:(AliPlayerController *)controller
                       playerModel:(AliPlayerModel *)playerModel {
    self = [super init];
    if (self) {
        _controller = controller;
        _playerModel = playerModel;
    }
    return self;
}

#pragma mark - Getters & Setters

- (PlayerStateStore *)stateStore {
    return self.controller.stateStore;
}

@end
