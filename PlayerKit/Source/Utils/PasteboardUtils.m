//
//  PasteboardUtils.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "PasteboardUtils.h"
#import <UIKit/UIPasteboard.h>

@implementation PasteboardUtils

+ (BOOL)copyText:(nullable NSString *)text {
    if (!text.length) return NO;

    [UIPasteboard generalPasteboard].string = text;
    return YES;
}

@end
