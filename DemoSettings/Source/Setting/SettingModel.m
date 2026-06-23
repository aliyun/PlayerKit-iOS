//
//  SettingModel.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SettingModel.h"
#import "ValueFormatter.h"

@interface SettingModel ()

@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, assign, readwrite) SettingType type;

@end

@implementation SettingModel

#pragma mark - Lifecycle

- (instancetype)initWithId:(NSString *)identifier
                     title:(NSString *)title
                      type:(SettingType)type {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _title = [title copy];
        _type = type;
        _enabled = YES;
    }
    return self;
}

#pragma mark - Factory Methods

+ (instancetype)headerWithId:(NSString *)identifier title:(NSString *)title {
    return [[self alloc] initWithId:identifier title:title type:SettingTypeHeader];
}

+ (instancetype)buttonWithId:(NSString *)identifier title:(NSString *)title {
    return [[self alloc] initWithId:identifier title:title type:SettingTypeButton];
}

+ (instancetype)buttonArrowWithId:(NSString *)identifier title:(NSString *)title {
    SettingModel *model = [[self alloc] initWithId:identifier title:title type:SettingTypeButton];
    model.showArrow = YES;
    return model;
}

+ (instancetype)textWithId:(NSString *)identifier title:(NSString *)title value:(nullable NSString *)value {
    SettingModel *model = [[self alloc] initWithId:identifier title:title type:SettingTypeText];
    model.value = value;
    return model;
}

+ (instancetype)switchWithId:(NSString *)identifier title:(NSString *)title checked:(BOOL)checked {
    SettingModel *model = [[self alloc] initWithId:identifier title:title type:SettingTypeSwitch];
    model.checked = checked;
    return model;
}

+ (instancetype)selectorWithId:(NSString *)identifier
                         title:(NSString *)title
                       options:(NSArray<NSString *> *)options {
    SettingModel *model = [[self alloc] initWithId:identifier title:title type:SettingTypeSelector];
    model.options = options;
    return model;
}

+ (instancetype)selectorWithId:(NSString *)identifier
                         title:(NSString *)title
                  valueOptions:(NSArray *)valueOptions
                     formatter:(id<ValueFormatter>)formatter {
    SettingModel *model = [[self alloc] initWithId:identifier title:title type:SettingTypeSelector];
    model.valueFormatter = formatter;

    NSMutableArray<NSString *> *displayOptions = [NSMutableArray arrayWithCapacity:valueOptions.count];
    for (id value in valueOptions) {
        [displayOptions addObject:[formatter formatValue:value]];
    }
    model.options = displayOptions;

    return model;
}

#pragma mark - Actions

- (void)loadAsyncWithBlock:(nullable SettingLoadedBlock)block {
    if (!self.asyncLoaderBlock) return;

    SettingAsyncLoaderBlock loader = self.asyncLoaderBlock;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *result = loader();
        dispatch_async(dispatch_get_main_queue(), ^{
            self.value = result;
            if (block) {
                block(result);
            }
        });
    });
}

- (void)handleValueChange:(NSString *)newDisplayValue {
    self.value = newDisplayValue;
    if (self.onValueChangedBlock) {
        id parsedValue = newDisplayValue;
        if (self.valueFormatter) {
            parsedValue = [self.valueFormatter parseDisplayString:newDisplayValue];
        }
        self.onValueChangedBlock(self, parsedValue);
    }
}

- (void)handleCheckedChange:(BOOL)checked {
    self.checked = checked;
    if (self.onValueChangedBlock) {
        self.onValueChangedBlock(self, @(checked));
    }
}

@end
