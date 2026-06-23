//
//  StrategyManager.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "StrategyManager.h"
#import "StrategyProtocol.h"
#import "StrategyContext.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "Log.h"

@interface StrategyManager ()

@property (nonatomic, strong) NSMutableArray<NSString *> *orderedNames;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<StrategyProtocol>> *strategies;
@property (nonatomic, strong, nullable) StrategyContext *currentContext;
@property (nonatomic, assign, readwrite, getter=isStarted) BOOL started;

@end

@implementation StrategyManager

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _orderedNames = [NSMutableArray array];
        _strategies = [NSMutableDictionary dictionary];
        _started = NO;

        SLOGI(@"[LC][init] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
    }
    return self;
}

- (void)dealloc {
    SLOGI(@"[LC][dealloc] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
}

#pragma mark - Public Methods

- (void)registerStrategy:(id<StrategyProtocol>)strategy {
    if (!strategy) return;

    NSString *name = [strategy strategyName];
    if (name.length == 0) return;

    // 如果同名策略已存在，先停止旧策略
    id<StrategyProtocol> existing = self.strategies[name];
    if (existing) {
        if (self.started) {
            [self safeStop:existing];
        }
        [self.orderedNames removeObject:name];
    }

    self.strategies[name] = strategy;
    [self.orderedNames addObject:name];

    // 如果管理器已启动，立即启动新策略
    if (self.started && self.currentContext) {
        [self safeStart:strategy context:self.currentContext];
    }
}

- (void)unregisterStrategyWithName:(NSString *)name {
    if (name.length == 0) return;

    id<StrategyProtocol> strategy = self.strategies[name];
    if (!strategy) return;

    if (self.started) {
        [self safeStop:strategy];
    }

    [self.strategies removeObjectForKey:name];
    [self.orderedNames removeObject:name];
}

- (id<StrategyProtocol>)strategyWithName:(NSString *)name {
    if (name.length == 0) return nil;
    return self.strategies[name];
}

- (void)startWithController:(AliPlayerController *)controller
                playerModel:(AliPlayerModel *)playerModel {
    if (self.started) {
        [self stop];
    }

    StrategyContext *context = [[StrategyContext alloc] initWithController:controller
                                                               playerModel:playerModel];
    self.currentContext = context;
    self.started = YES;

    for (NSString *name in [self.orderedNames copy]) {
        id<StrategyProtocol> strategy = self.strategies[name];
        [self safeStart:strategy context:context];
    }
}

- (void)resetWithPlayerModel:(AliPlayerModel *)playerModel {
    if (!self.started) return;

    // 更新上下文中的播放模型
    AliPlayerController *controller = self.currentContext.controller;
    if (!controller) return;

    StrategyContext *newContext = [[StrategyContext alloc] initWithController:controller
                                                                  playerModel:playerModel];
    self.currentContext = newContext;

    for (NSString *name in [self.orderedNames copy]) {
        id<StrategyProtocol> strategy = self.strategies[name];
        [self safeReset:strategy context:newContext];
    }
}

- (void)stop {
    if (!self.started) return;

    for (NSString *name in [self.orderedNames copy]) {
        id<StrategyProtocol> strategy = self.strategies[name];
        [self safeStop:strategy];
    }

    self.currentContext = nil;
    self.started = NO;
}

- (void)destroy {
    [self stop];
    [self.strategies removeAllObjects];
    [self.orderedNames removeAllObjects];
}

- (NSUInteger)strategyCount {
    return self.strategies.count;
}

#pragma mark - Private Methods

// 安全启动策略，异常不影响其他策略
- (void)safeStart:(id<StrategyProtocol>)strategy context:(StrategyContext *)context {
    @try {
        [strategy strategyDidStart:context];
    } @catch (NSException *exception) {
        SLOGE(@"Strategy [%@] start failed: %@", [strategy strategyName], exception);
    }
}

// 安全停止策略，异常不影响其他策略
- (void)safeStop:(id<StrategyProtocol>)strategy {
    @try {
        [strategy strategyDidStop];
    } @catch (NSException *exception) {
        SLOGE(@"Strategy [%@] stop failed: %@", [strategy strategyName], exception);
    }
}

// 安全重置策略，异常不影响其他策略
- (void)safeReset:(id<StrategyProtocol>)strategy context:(StrategyContext *)context {
    @try {
        [strategy strategyDidReset:context];
    } @catch (NSException *exception) {
        SLOGE(@"Strategy [%@] reset failed: %@", [strategy strategyName], exception);
    }
}

@end
