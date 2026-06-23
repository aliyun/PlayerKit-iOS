//
//  SlotManager.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SlotManager.h"
#import "CustomSlotType.h"
#import "SlotHostLayout.h"
#import "SlotConfig.h"
#import "DefaultSlotFactory.h"
#import "Log.h"

@interface SlotManager ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, SlotProvider> *providers;
@property (nonatomic, strong) NSMutableSet<NSNumber *> *hiddenSlots;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *hiddenElementMasks;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *shownElementMasks;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, SlotConfig *> *slotConfigs;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CustomSlotType *> *customTypes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, SlotProvider> *customProviders;
@property (nonatomic, weak) SlotHostLayout *hostLayout;

@end

@implementation SlotManager

#pragma mark - Lifecycle

- (instancetype)initInternal {
    self = [super init];
    if (self) {
        _providers = [NSMutableDictionary dictionary];
        _hiddenSlots = [NSMutableSet set];
        _hiddenElementMasks = [NSMutableDictionary dictionary];
        _shownElementMasks = [NSMutableDictionary dictionary];
        _slotConfigs = [NSMutableDictionary dictionary];
        _customTypes = [NSMutableDictionary dictionary];
        _customProviders = [NSMutableDictionary dictionary];
        [self setupBuiltinSlots];
        [self registerDefaultConfigs];

        SLOGI(@"[LC][init] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
    }
    return self;
}

- (void)dealloc {
    SLOGI(@"[LC][dealloc] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
}

#pragma mark - Slot Registration

- (void)registerSlotType:(SlotType)type provider:(SlotProvider)provider {
    if (!provider) {
        SLOGW(@"SlotManager: attempted to register nil provider for type: %@", SlotTypeName(type));
        return;
    }
    self.providers[@(type)] = [provider copy];
}

- (void)unregisterSlotType:(SlotType)type {
    [self.providers removeObjectForKey:@(type)];
}

- (BOOL)isRegistered:(SlotType)type {
    return self.providers[@(type)] != nil;
}

#pragma mark - Custom Slot Registration

- (void)registerCustomSlotType:(CustomSlotType *)type provider:(SlotProvider)provider {
    if (!type || !provider) {
        SLOGW(@"SlotManager: attempted to register nil custom type or provider");
        return;
    }
    self.customTypes[type.key] = type;
    self.customProviders[type.key] = [provider copy];
}

- (void)unregisterCustomSlotType:(CustomSlotType *)type {
    if (!type) {
        return;
    }
    [self.customTypes removeObjectForKey:type.key];
    [self.customProviders removeObjectForKey:type.key];
}

- (BOOL)isCustomSlotRegistered:(CustomSlotType *)type {
    if (!type) {
        return NO;
    }
    return self.customTypes[type.key] != nil;
}

- (NSArray<CustomSlotType *> *)customSlotTypes {
    return self.customTypes.allValues;
}

#pragma mark - Slot Visibility

- (void)hideSlot:(SlotType)type {
    [self.hiddenSlots addObject:@(type)];
}

- (void)showSlot:(SlotType)type {
    [self.hiddenSlots removeObject:@(type)];
}

- (BOOL)isSlotHidden:(SlotType)type {
    return [self.hiddenSlots containsObject:@(type)];
}

#pragma mark - Element Visibility

- (void)hideElements:(NSUInteger)mask forSlot:(SlotType)type {
    if (mask == 0) {
        return;
    }
    NSNumber *key = @(type);
    NSUInteger currentHidden = [self.hiddenElementMasks[key] unsignedIntegerValue];
    NSUInteger currentShown = [self.shownElementMasks[key] unsignedIntegerValue];
    self.hiddenElementMasks[key] = @(currentHidden | mask);
    self.shownElementMasks[key] = @(currentShown & ~mask);
}

- (void)showElements:(NSUInteger)mask forSlot:(SlotType)type {
    if (mask == 0) {
        return;
    }
    NSNumber *key = @(type);
    NSUInteger currentHidden = [self.hiddenElementMasks[key] unsignedIntegerValue];
    NSUInteger currentShown = [self.shownElementMasks[key] unsignedIntegerValue];
    self.shownElementMasks[key] = @(currentShown | mask);
    self.hiddenElementMasks[key] = @(currentHidden & ~mask);
}

- (NSUInteger)hiddenElementMaskForSlot:(SlotType)type {
    return [self.hiddenElementMasks[@(type)] unsignedIntegerValue];
}

- (NSUInteger)shownElementMaskForSlot:(SlotType)type {
    return [self.shownElementMasks[@(type)] unsignedIntegerValue];
}

- (void)setHiddenElementMask:(NSUInteger)mask forSlot:(SlotType)type {
    NSNumber *key = @(type);
    if (mask == 0) {
        [self.hiddenElementMasks removeObjectForKey:key];
    } else {
        self.hiddenElementMasks[key] = @(mask);
    }
    [self.shownElementMasks removeObjectForKey:key];
}

- (void)setAllHiddenElementMasks:(nullable NSDictionary<NSNumber *, NSNumber *> *)config {
    [self.hiddenElementMasks removeAllObjects];
    [self.shownElementMasks removeAllObjects];
    if (!config) {
        return;
    }
    for (NSNumber *key in config) {
        NSNumber *value = config[key];
        NSUInteger mask = [value unsignedIntegerValue];
        if (mask != 0) {
            self.hiddenElementMasks[key] = @(mask);
        }
    }
}

- (void)clearAllElementMasks {
    [self.hiddenElementMasks removeAllObjects];
    [self.shownElementMasks removeAllObjects];
}

#pragma mark - Scene-based Visibility (SlotConfig)

- (void)registerSlotConfig:(SlotConfig *)config {
    self.slotConfigs[@(config.slotType)] = config;
}

- (void)unregisterSlotConfigForType:(SlotType)slotType {
    [self.slotConfigs removeObjectForKey:@(slotType)];
}

- (nullable SlotConfig *)slotConfigForType:(SlotType)type {
    return self.slotConfigs[@(type)];
}

#pragma mark - Runtime Access

- (nullable UIView<SlotProtocol> *)slotViewForType:(SlotType)type {
    return [self.hostLayout slotViewForType:type];
}

- (void)rebuildSlots {
    [self.hostLayout rebuildSlots];
}

- (void)clearAll {
    [self.providers removeAllObjects];
    [self.hiddenSlots removeAllObjects];
    [self clearAllElementMasks];
    [self.slotConfigs removeAllObjects];
    [self.customTypes removeAllObjects];
    [self.customProviders removeAllObjects];
    SLOGI(@"SlotManager: all configurations cleared");
}

#pragma mark - Internal (Package)

- (void)bindHostLayout:(SlotHostLayout *)hostLayout {
    self.hostLayout = hostLayout;
}

- (nullable UIView<SlotProtocol> *)buildSlotForType:(SlotType)type parentView:(UIView *)parentView {
    SlotProvider provider = self.providers[@(type)];
    if (!provider) {
        return nil;
    }
    return provider(parentView);
}

- (nullable UIView<SlotProtocol> *)buildCustomSlotForType:(CustomSlotType *)type parentView:(UIView *)parentView {
    if (!type) {
        return nil;
    }
    SlotProvider provider = self.customProviders[type.key];
    if (!provider) {
        return nil;
    }
    return provider(parentView);
}

- (NSArray<CustomSlotType *> *)registeredCustomSlotTypes {
    return self.customTypes.allValues;
}

#pragma mark - Private Methods

- (void)setupBuiltinSlots {
    NSDictionary<NSNumber *, SlotProvider> *providers = [DefaultSlotFactory defaultProviders];
    [providers enumerateKeysAndObjectsUsingBlock:^(NSNumber *typeKey, SlotProvider provider, BOOL *stop) {
        [self registerSlotType:(SlotType)[typeKey integerValue] provider:provider];
    }];
}

- (void)registerDefaultConfigs {
    NSArray<SlotConfig *> *configs = [DefaultSlotFactory defaultConfigs];
    for (SlotConfig *config in configs) {
        self.slotConfigs[@(config.slotType)] = config;
    }
}

@end
