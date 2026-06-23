//
//  SettingOptions.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SettingOptions.h"

@interface ArraySettingOptions ()

@property (nonatomic, copy) NSArray *items;

@end

@implementation ArraySettingOptions

- (instancetype)initWithArray:(NSArray *)array {
    self = [super init];
    if (self) {
        _items = [array copy];
    }
    return self;
}

+ (instancetype)optionsWithArray:(NSArray *)array {
    return [[self alloc] initWithArray:array];
}

#pragma mark - SettingOptions

- (NSInteger)count {
    return (NSInteger)self.items.count;
}

- (id)objectAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.items.count) {
        return nil;
    }
    return self.items[index];
}

@end
