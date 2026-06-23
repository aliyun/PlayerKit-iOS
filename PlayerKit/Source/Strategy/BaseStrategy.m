//
//  BaseStrategy.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseStrategy.h"
#import "StrategyContext.h"
#import "AliPlayerController.h"
#import "Log.h"

@interface BaseStrategy ()

@property (nonatomic, strong, readwrite, nullable) StrategyContext *context;

@end

@implementation BaseStrategy

#pragma mark - StrategyProtocol

- (NSString *)strategyName {
    [NSException raise:NSInternalInconsistencyException
                format:@"子类 %@ 必须覆写 strategyName 方法", NSStringFromClass([self class])];
    return @"";
}

- (void)strategyDidStart:(StrategyContext *)context {
    self.context = context;
    AliPlayerController *controller = context.controller;
    if (controller) {
        [controller addNotificationDelegate:self];
    }
    SLOGI(@"Strategy [%@] started", [self strategyName]);
}

- (void)strategyDidStop {
    if (!self.context) return;
    AliPlayerController *controller = self.context.controller;
    if (controller) {
        [controller removeNotificationDelegate:self];
    }
    self.context = nil;
    SLOGI(@"Strategy [%@] stopped", [self strategyName]);
}

- (void)strategyDidReset:(StrategyContext *)context {
    self.context = context;
    [self resetInternalState];
    SLOGI(@"Strategy [%@] reset", [self strategyName]);
}

#pragma mark - Subclass Hooks

- (void)resetInternalState {
    // 默认空实现，子类按需覆写
}

@end
