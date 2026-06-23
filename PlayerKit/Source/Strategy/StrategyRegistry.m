//
//  StrategyRegistry.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "StrategyRegistry.h"
#import "StrategyManager.h"
#import "StrategyProtocol.h"
#import "FirstFrameStrategy.h"
#import "StutterDetectStrategy.h"
#import "TrafficProtectionStrategy.h"

@interface StrategyRegistry ()

@property (nonatomic, strong) NSMutableArray<StrategyFactory> *factories;

@end

@implementation StrategyRegistry

#pragma mark - Lifecycle

+ (instancetype)sharedRegistry {
    static StrategyRegistry *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initPrivate];
    });
    return instance;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _factories = [NSMutableArray array];
        [self setupBuiltinStrategies];
    }
    return self;
}

#pragma mark - Public Methods

- (void)addGlobalStrategyFactory:(StrategyFactory)factory {
    if (!factory) return;
    [self.factories addObject:[factory copy]];
}

- (void)clearGlobalStrategies {
    [self.factories removeAllObjects];
}

- (void)applyToManager:(StrategyManager *)manager {
    if (!manager) return;
    for (StrategyFactory factory in self.factories) {
        id<StrategyProtocol> strategy = factory();
        if (strategy) {
            [manager registerStrategy:strategy];
        }
    }
}

- (void)resetToDefault {
    [self.factories removeAllObjects];
    [self setupBuiltinStrategies];
}

#pragma mark - Private Methods

// 注册内置默认策略工厂
- (void)setupBuiltinStrategies {
    [self.factories addObject:^id<StrategyProtocol>{
        return [[FirstFrameStrategy alloc] init];
    }];
    [self.factories addObject:^id<StrategyProtocol>{
        return [[StutterDetectStrategy alloc] init];
    }];
    [self.factories addObject:^id<StrategyProtocol>{
        return [[TrafficProtectionStrategy alloc] init];
    }];
}

@end
