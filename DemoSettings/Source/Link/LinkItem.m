//
//  LinkItem.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "LinkItem.h"

@interface LinkItem ()

@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSString *key;

@end

@implementation LinkItem

+ (instancetype)itemWithName:(NSString *)name key:(NSString *)key {
    LinkItem *item = [[LinkItem alloc] initPrivate];
    item.name = name;
    item.key = key;
    item.link = @"";
    return item;
}

- (instancetype)initPrivate {
    return [super init];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: name=%@, key=%@, link=%@>",
            NSStringFromClass([self class]), self.name, self.key, self.link];
}

@end
