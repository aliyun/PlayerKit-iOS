//
//  SlotConfig.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SlotConfig.h"

@interface SlotConfig ()

@property (nonatomic, assign, readwrite) SlotType slotType;
@property (nonatomic, copy, readwrite, nullable) NSSet<NSNumber *> *excludedScenes;
@property (nonatomic, copy, readwrite, nullable) BOOL(^visibilityCondition)(void);

@end

@implementation SlotConfig

#pragma mark - Lifecycle

// 指定初始化方法
- (instancetype)initWithSlotType:(SlotType)slotType
                  excludedScenes:(nullable NSSet<NSNumber *> *)excludedScenes
             visibilityCondition:(nullable BOOL(^)(void))condition {
    self = [super init];
    if (self) {
        _slotType = slotType;
        _excludedScenes = [excludedScenes copy];
        _visibilityCondition = [condition copy];
    }
    return self;
}

#pragma mark - Public Methods

+ (instancetype)configWithSlotType:(SlotType)slotType {
    return [[self alloc] initWithSlotType:slotType
                           excludedScenes:nil
                      visibilityCondition:nil];
}

+ (instancetype)configWithSlotType:(SlotType)slotType
                    excludedScenes:(nullable NSSet<NSNumber *> *)excludedScenes {
    return [[self alloc] initWithSlotType:slotType
                           excludedScenes:excludedScenes
                      visibilityCondition:nil];
}

+ (instancetype)configWithSlotType:(SlotType)slotType
                    excludedScenes:(nullable NSSet<NSNumber *> *)excludedScenes
               visibilityCondition:(nullable BOOL(^)(void))condition {
    return [[self alloc] initWithSlotType:slotType
                           excludedScenes:excludedScenes
                      visibilityCondition:condition];
}

- (BOOL)isVisibleInScene:(SceneType)sceneType {
    // Check excluded scenes
    if (self.excludedScenes && [self.excludedScenes containsObject:@(sceneType)]) {
        return NO;
    }

    // Check visibility condition
    if (self.visibilityCondition && !self.visibilityCondition()) {
        return NO;
    }

    return YES;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, slotType=%ld, excludedScenes=%@>",
            NSStringFromClass([self class]), self, (long)self.slotType, self.excludedScenes];
}

@end
