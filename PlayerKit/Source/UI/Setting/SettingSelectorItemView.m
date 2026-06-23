//
//  SettingSelectorItemView.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SettingSelectorItemView.h"
#import "SettingItem.h"
#import "SettingConstants.h"
#import "PlayerColor.h"
#import "PlayerFont.h"

static const CGFloat kOptionSpacing = 16.0;
static const CGFloat kOptionFontSize = 12.0;

@interface SettingSelectorItemView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIStackView *optionsStack;
@property (nonatomic, strong, readwrite) UIView *separatorView;
@property (nonatomic, strong) SettingItem *item;
@property (nonatomic, strong) NSMutableArray<UILabel *> *optionLabels;

@end

@implementation SettingSelectorItemView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _optionLabels = [NSMutableArray array];
        [self setupViews];
    }
    return self;
}

#pragma mark - SettingItemViewProtocol

- (UIView *)contentView {
    return self;
}

- (void)bindItem:(SettingItem *)item {
    self.item = item;
    self.titleLabel.text = item.title;
    [self rebuildOptions];
}

- (void)updateValueOnly:(id)value {
    if (!self.item) return;
    self.item.currentValue = value;
    [self refreshOptionStyles];
}

#pragma mark - Private

- (void)setupViews {
    self.backgroundColor = [UIColor clearColor];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:SettingItemTitleFontSize];
    self.titleLabel.textColor = [PlayerColor settingOptionSelected];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.titleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self addSubview:self.titleLabel];

    self.optionsStack = [[UIStackView alloc] init];
    self.optionsStack.axis = UILayoutConstraintAxisHorizontal;
    self.optionsStack.spacing = kOptionSpacing;
    self.optionsStack.alignment = UIStackViewAlignmentCenter;
    self.optionsStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.optionsStack];

    self.separatorView = [[UIView alloc] init];
    self.separatorView.backgroundColor = [PlayerColor settingDivider];
    self.separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.separatorView];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:SettingItemHorizontalPadding],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

        [self.optionsStack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-SettingItemHorizontalPadding],
        [self.optionsStack.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.optionsStack.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.titleLabel.trailingAnchor constant:12],

        [self.separatorView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:SettingItemHorizontalPadding],
        [self.separatorView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.separatorView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.separatorView.heightAnchor constraintEqualToConstant:SettingItemSeparatorHeight],
    ]];
}

- (void)rebuildOptions {
    for (UIView *v in self.optionsStack.arrangedSubviews) {
        [self.optionsStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    [self.optionLabels removeAllObjects];

    id<SettingOptions> options = self.item.options;
    if (!options) return;

    NSInteger count = [options count];
    for (NSInteger i = 0; i < count; i++) {
        id optionValue = [options objectAtIndex:i];
        NSString *text = self.item.formatterBlock ? self.item.formatterBlock(optionValue) : [optionValue description];

        UILabel *label = [[UILabel alloc] init];
        label.text = text;
        label.textAlignment = NSTextAlignmentCenter;
        label.userInteractionEnabled = YES;
        label.tag = i;

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(optionTapped:)];
        [label addGestureRecognizer:tap];

        [self.optionsStack addArrangedSubview:label];
        [self.optionLabels addObject:label];
    }

    [self refreshOptionStyles];
}

- (void)refreshOptionStyles {
    id<SettingOptions> options = self.item.options;
    if (!options) return;

    for (NSInteger i = 0; i < (NSInteger)self.optionLabels.count; i++) {
        UILabel *label = self.optionLabels[i];
        id optionValue = [options objectAtIndex:i];
        BOOL selected = [optionValue isEqual:self.item.currentValue];

        if (selected) {
            label.font = [UIFont boldSystemFontOfSize:kOptionFontSize];
            label.textColor = [PlayerColor settingOptionSelected];
        } else {
            label.font = [UIFont systemFontOfSize:kOptionFontSize];
            label.textColor = [PlayerColor settingOptionNormal];
        }
    }
}

- (void)optionTapped:(UITapGestureRecognizer *)gesture {
    NSInteger index = gesture.view.tag;
    id<SettingOptions> options = self.item.options;
    if (!options || index < 0 || index >= [options count]) return;

    id newValue = [options objectAtIndex:index];
    if ([newValue isEqual:self.item.currentValue]) return;

    self.item.currentValue = newValue;
    [self refreshOptionStyles];

    if (self.item.valueChangedBlock) {
        self.item.valueChangedBlock(self.item, newValue);
    }
}

@end
