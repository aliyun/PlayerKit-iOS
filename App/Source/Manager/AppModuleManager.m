//
//  AppModuleManager.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "AppModuleManager.h"
#import <PlayerKitScenes/AppModuleProtocol.h>
#import "AppModuleInfo.h"
#import <objc/runtime.h>

@interface AppModuleManager ()

@property (nonatomic, strong, readwrite) NSArray<AppModuleInfo *> *moduleInfoList;
@property (nonatomic, assign) BOOL hasScanned;

@end

@implementation AppModuleManager

#pragma mark - Lifecycle

+ (instancetype)sharedManager {
    static AppModuleManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AppModuleManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _hasScanned = NO;
    }
    return self;
}

#pragma mark - Public Methods

- (NSArray<AppModuleInfo *> *)moduleInfoList {
    [self ensureModulesScanned];
    return _moduleInfoList;
}

- (BOOL)handleURL:(NSString *)url fromViewController:(UIViewController *)viewController {
    if (!url || url.length == 0) {
        return NO;
    }
    
    // 查找匹配该 schema 的模块类
    Class moduleClass = [self moduleClassForSchema:url];
    if (!moduleClass) {
        return NO;
    }
    
    // 推入目标视图控制器
    if (!viewController.navigationController) {
        return NO;
    }
    
    // 创建目标视图控制器
    UIViewController *targetVC = nil;
    
    // 优先使用 moduleViewControllerWithURL: 以传递 URL 上下文
    if ([moduleClass respondsToSelector:@selector(moduleViewControllerWithURL:)]) {
        targetVC = [moduleClass moduleViewControllerWithURL:url];
    } else if ([moduleClass respondsToSelector:@selector(moduleViewController)]) {
        targetVC = [moduleClass moduleViewController];
    }
    
    if (!targetVC || ![targetVC isKindOfClass:[UIViewController class]]) {
        return NO;
    }
    
    [viewController.navigationController pushViewController:targetVC animated:YES];
    return YES;
}

#pragma mark - Private Methods

// 首次访问时触发模块扫描（懒加载）
- (void)ensureModulesScanned {
    if (self.hasScanned) {
        return;
    }
    self.hasScanned = YES;
    [self scanModules];
}

// 扫描所有已加载的类，查找遵循 AppModuleProtocol 协议的模块
- (void)scanModules {
    NSMutableArray<AppModuleInfo *> *modules = [NSMutableArray array];
    
    unsigned int classCount = 0;
    Class *classes = objc_copyClassList(&classCount);
    
    for (unsigned int i = 0; i < classCount; i++) {
        Class cls = classes[i];
        NSString *className = NSStringFromClass(cls);
        
        // 仅处理以 "Module" 结尾的类
        if (![className hasSuffix:@"Module"]) {
            continue;
        }
        
        // 验证该类是否遵循 AppModuleProtocol 协议
        if (![cls conformsToProtocol:@protocol(AppModuleProtocol)]) {
            continue;
        }
        
        // 收集模块信息
        AppModuleInfo *info = [self moduleInfoFromClass:cls];
        if (info) {
            [modules addObject:info];
        }
    }
    
    free(classes);
    
    // 按优先级降序排列，优先级相同则按标题升序排列
    [modules sortUsingComparator:^NSComparisonResult(AppModuleInfo *a, AppModuleInfo *b) {
        if (a.priority != b.priority) {
            return (a.priority > b.priority) ? NSOrderedAscending : NSOrderedDescending;
        }
        return [a.title compare:b.title];
    }];
    
    self.moduleInfoList = [modules copy];
}

// 从有效的模块类中提取模块元数据
- (AppModuleInfo *)moduleInfoFromClass:(Class<AppModuleProtocol>)cls {
    NSString *title = [cls moduleTitle];
    NSString *schema = [cls moduleSchema];
    NSString *category = [cls moduleCategory];

    NSString *desc = nil;
    if ([cls respondsToSelector:@selector(moduleDescription)]) {
        desc = [cls moduleDescription];
    }
    
    if (!title || !schema) {
        return nil;
    }
    
    // 解析可选的优先级
    NSInteger priority = AppModulePriorityDefault;
    if ([cls respondsToSelector:@selector(modulePriority)]) {
        priority = [cls modulePriority];
    }
    
    return [AppModuleInfo infoWithTitle:title
                                schema:schema
                     moduleDescription:desc ?: @""
                              category:category ?: @""
                             className:NSStringFromClass(cls)
                              priority:priority];
}

// 查找 schema 与给定 URL 匹配的模块类（前缀匹配）
- (Class<AppModuleProtocol>)moduleClassForSchema:(NSString *)schema {
    [self ensureModulesScanned];
    
    for (AppModuleInfo *info in _moduleInfoList) {
        NSString *moduleSchema = info.schema;
        // 同时支持精确匹配和带参数 URL 的前缀匹配
        if ([schema isEqualToString:moduleSchema] || [schema hasPrefix:[moduleSchema stringByAppendingString:@"?"]]) {
            return NSClassFromString(info.className);
        }
    }
    return nil;
}

@end
