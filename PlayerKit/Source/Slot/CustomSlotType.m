//
//  CustomSlotType.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "CustomSlotType.h"

@implementation CustomSlotType

+ (instancetype)typeWithKey:(NSString *)key order:(NSInteger)order {
    NSParameterAssert(key.length > 0);
    CustomSlotType *instance = [[CustomSlotType alloc] initWithKey:key order:order];
    return instance;
}

- (instancetype)initWithKey:(NSString *)key order:(NSInteger)order {
    self = [super init];
    if (self) {
        _key = [key copy];
        _order = order;
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[CustomSlotType class]]) {
        return NO;
    }
    return [self.key isEqualToString:((CustomSlotType *)object).key];
}

- (NSUInteger)hash {
    return self.key.hash;
}

#pragma mark - Description

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: key=%@, order=%ld>",
            NSStringFromClass([self class]), self.key, (long)self.order];
}

@end
