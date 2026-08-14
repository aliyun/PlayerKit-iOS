//
//  AiSummary.m
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "AiSummary.h"

@implementation AiSummary

#pragma mark - Lifecycle

- (instancetype)initWithTitle:(nullable NSString *)title
                  summaryText:(nullable NSString *)summaryText
                     markdown:(nullable NSString *)markdown
                         tags:(nullable NSArray<NSString *> *)tags {
    self = [super init];
    if (self) {
        _title = [title copy];
        _summaryText = [summaryText copy];
        _markdown = [markdown copy];
        _tags = [tags copy];
    }
    return self;
}

@end
