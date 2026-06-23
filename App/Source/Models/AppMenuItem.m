//
//  AppMenuItem.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "AppMenuItem.h"

@interface AppMenuItem ()

@property (nonatomic, assign, readwrite) AppMenuItemType type;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite, nullable) NSString *schema;
@property (nonatomic, copy, readwrite, nullable) NSString *itemDescription;

@end

@implementation AppMenuItem

#pragma mark - Public Methods

+ (instancetype)titleItemWithTitle:(NSString *)title {
    AppMenuItem *item = [[AppMenuItem alloc] init];
    item.type = AppMenuItemTypeTitle;
    item.title = title;
    return item;
}

+ (instancetype)menuItemWithTitle:(NSString *)title
                           schema:(NSString *)schema
                      description:(nullable NSString *)description {
    AppMenuItem *item = [[AppMenuItem alloc] init];
    item.type = AppMenuItemTypeItem;
    item.title = title;
    item.schema = schema;
    item.itemDescription = description;
    return item;
}

@end
