//
//  AppMenuConfig.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "AppMenuConfig.h"
#import "AppMenuItem.h"
#import "AppModuleManager.h"
#import "AppModuleInfo.h"

@implementation AppMenuConfig

#pragma mark - Public Methods

- (NSArray<NSArray<AppMenuItem *> *> *)menuSections {
    NSArray<AppModuleInfo *> *moduleInfoList = [AppModuleManager sharedManager].moduleInfoList;
    
    // 按分类对模块进行分组
    NSMutableDictionary<NSString *, NSMutableArray *> *categoryMap = [NSMutableDictionary dictionary];
    NSMutableArray<NSString *> *orderedCategories = [NSMutableArray array];
    
    for (AppModuleInfo *info in moduleInfoList) {
        NSString *category = info.category.length > 0 ? info.category : @"Other";
        
        if (!categoryMap[category]) {
            categoryMap[category] = [NSMutableArray array];
            [orderedCategories addObject:category];
        }
        
        AppMenuItem *item = [AppMenuItem menuItemWithTitle:info.title
                                                   schema:info.schema
                                              description:info.moduleDescription];
        [categoryMap[category] addObject:item];
    }
    
    // 构建带标题头的分组
    NSMutableArray<NSArray<AppMenuItem *> *> *sections = [NSMutableArray array];
    
    for (NSString *category in orderedCategories) {
        NSMutableArray<AppMenuItem *> *sectionItems = [NSMutableArray array];
        
        // 添加分组标题项
        AppMenuItem *titleItem = [AppMenuItem titleItemWithTitle:category];
        [sectionItems addObject:titleItem];
        
        // 添加模块项
        [sectionItems addObjectsFromArray:categoryMap[category]];
        
        [sections addObject:[sectionItems copy]];
    }
    
    return [sections copy];
}

@end
