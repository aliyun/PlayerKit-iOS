//
//  AiEducationMarkdownRenderer.m
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "AiEducationMarkdownRenderer.h"
#import "AiEducationColorConstants.h"

#if __has_include(<PlayerKitScenes/PlayerKitScenes-Swift.h>)
#import <PlayerKitScenes/PlayerKitScenes-Swift.h>
#define AI_EDU_MARKDOWN_ENGINE_AVAILABLE 1
#elif __has_include("PlayerKitScenes-Swift.h")
#import "PlayerKitScenes-Swift.h"
#define AI_EDU_MARKDOWN_ENGINE_AVAILABLE 1
#else
#define AI_EDU_MARKDOWN_ENGINE_AVAILABLE 0
#endif

@interface AiEducationMarkdownRenderer ()

// 渲染结果缓存，key 为 Markdown 原文
@property (nonatomic, strong) NSCache<NSString *, NSAttributedString *> *cache;

@end

@implementation AiEducationMarkdownRenderer

#pragma mark - Lifecycle

+ (instancetype)sharedRenderer {
    static AiEducationMarkdownRenderer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AiEducationMarkdownRenderer alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cache = [[NSCache alloc] init];
        _cache.countLimit = 64;
    }
    return self;
}

#pragma mark - Public Methods

- (NSAttributedString *)renderMarkdown:(nullable NSString *)markdown {
    if (markdown.length == 0) {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    NSAttributedString *cached = [self.cache objectForKey:markdown];
    if (cached) {
        return cached;
    }
    NSAttributedString *rendered = nil;
#if AI_EDU_MARKDOWN_ENGINE_AVAILABLE
    // 渲染由 Swift 侧 Down 引擎提供，失败返回 nil 走降级
    rendered = [[AiEducationMarkdownEngine shared] render:markdown];
#endif
    if (!rendered) {
        // 降级：原文 + 正文样式
        rendered = [[NSAttributedString alloc] initWithString:markdown
                                                   attributes:[self bodyAttributes]];
    }
    [self.cache setObject:rendered forKey:markdown];
    return rendered;
}

#pragma mark - Private Methods

// 降级正文样式
- (NSDictionary *)bodyAttributes {
    return @{
        NSFontAttributeName: [UIFont systemFontOfSize:13],
        NSForegroundColorAttributeName: AiEducationBodyTextColor(),
    };
}

@end
