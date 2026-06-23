//
//  SettingItem.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SettingItem.h"

@implementation SettingItem

- (instancetype)initWithElement:(SettingMenuElement)element
                          title:(NSString *)title
                           type:(SettingItemType)type
                   initialValue:(id)initialValue {
    self = [super init];
    if (self) {
        _element = element;
        _title = [title copy];
        _type = type;
        _currentValue = initialValue;
    }
    return self;
}

- (NSString *)displayValue {
    if (!self.currentValue) {
        return @"";
    }
    if (self.formatterBlock) {
        return self.formatterBlock(self.currentValue);
    }
    return [self.currentValue description];
}

- (BOOL)isSupportedInScene:(SceneType)sceneType {
    if (!self.supportedScenes) {
        return YES;
    }
    return [self.supportedScenes containsIndex:(NSUInteger)sceneType];
}

@end
