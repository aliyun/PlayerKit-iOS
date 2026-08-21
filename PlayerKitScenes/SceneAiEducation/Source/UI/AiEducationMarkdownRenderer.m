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

#pragma mark - Public Methods

- (UIView *)createMarkdownView {
#if AI_EDU_MARKDOWN_ENGINE_AVAILABLE
    // GMarkdown 渲染视图：内部自带 collectionView 分块渲染，滚动已关闭
    return [[AiEducationMarkdownView alloc] initWithFrame:CGRectZero];

#else
    // 降级：多行 UILabel 直出原文
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    return label;

#endif
}

- (CGFloat)renderMarkdown:(nullable NSString *)markdown
                 intoView:(UIView *)view
                    width:(CGFloat)width {
    if (markdown.length == 0 || width <= 0) {
        return 0;
    }

#if AI_EDU_MARKDOWN_ENGINE_AVAILABLE

    if ([view isKindOfClass:[AiEducationMarkdownView class]]) {
        // 渲染由 Swift 侧 GMarkdown 引擎完成，同步返回内容高度
        return [(AiEducationMarkdownView *)view renderWithMarkdown:markdown width:width];
    }

#endif

    // 降级：原文 + 正文样式，按宽度计算高度
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        label.attributedText = [[NSAttributedString alloc] initWithString:markdown
                                                               attributes:[self bodyAttributes]];
        CGSize fitSize = [label sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
        return ceil(fitSize.height);
    }

    return 0;
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
