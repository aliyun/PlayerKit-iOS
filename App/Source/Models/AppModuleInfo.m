//
//  AppModuleInfo.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "AppModuleInfo.h"

@interface AppModuleInfo ()

@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *schema;
@property (nonatomic, copy, readwrite, nullable) NSString *moduleDescription;
@property (nonatomic, copy, readwrite, nullable) NSString *category;
@property (nonatomic, copy, readwrite) NSString *className;
@property (nonatomic, assign, readwrite) NSInteger priority;

@end

@implementation AppModuleInfo

#pragma mark - Public Methods

+ (instancetype)infoWithTitle:(NSString *)title
                       schema:(NSString *)schema
            moduleDescription:(NSString *)moduleDescription
                     category:(NSString *)category
                    className:(NSString *)className
                     priority:(NSInteger)priority {
    AppModuleInfo *info = [[AppModuleInfo alloc] init];
    info.title = title;
    info.schema = schema;
    info.moduleDescription = moduleDescription;
    info.category = category;
    info.className = className;
    info.priority = priority;
    return info;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<AppModuleInfo: title=%@, schema=%@, category=%@, priority=%ld>",
            self.title, self.schema, self.category, (long)self.priority];
}

@end
