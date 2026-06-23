//
//  SettingSwitcherItemView.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SettingSwitcherItemView.h"
#import "SettingItem.h"
#import "SettingConstants.h"
#import "PlayerColor.h"

@interface SettingSwitcherItemView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UISwitch *toggleSwitch;
@property (nonatomic, strong, readwrite) UIView *separatorView;
@property (nonatomic, strong) SettingItem *item;
@property (nonatomic, assign) BOOL suppressCallback;

@end

@implementation SettingSwitcherItemView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
        [self setupGesture];
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

    self.suppressCallback = YES;
    self.toggleSwitch.on = [item.currentValue boolValue];
    self.suppressCallback = NO;
}

- (void)updateValueOnly:(id)value {
    if (!self.item) {
        return;
    }
    self.item.currentValue = value;

    self.suppressCallback = YES;
    self.toggleSwitch.on = [value boolValue];
    self.suppressCallback = NO;
}

#pragma mark - Private Methods

- (void)setupViews {
    self.backgroundColor = [UIColor clearColor];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:SettingItemTitleFontSize];
    self.titleLabel.textColor = [PlayerColor settingOptionSelected];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.titleLabel];

    self.toggleSwitch = [[UISwitch alloc] init];
    self.toggleSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [self.toggleSwitch addTarget:self
                          action:@selector(switchValueChanged:)
                forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.toggleSwitch];

    self.separatorView = [[UIView alloc] init];
    self.separatorView.backgroundColor = [PlayerColor settingDivider];
    self.separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.separatorView];

    NSLayoutConstraint *heightConstraint = [self.heightAnchor constraintEqualToConstant:SettingItemHeight];
    heightConstraint.priority = UILayoutPriorityDefaultLow;

    [NSLayoutConstraint activateConstraints:@[
        heightConstraint,

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:SettingItemHorizontalPadding],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

        [self.toggleSwitch.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-SettingItemHorizontalPadding],
        [self.toggleSwitch.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

        [self.separatorView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:SettingItemHorizontalPadding],
        [self.separatorView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.separatorView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.separatorView.heightAnchor constraintEqualToConstant:SettingItemSeparatorHeight],
    ]];
}

- (void)setupGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    tap.delegate = self;
    [self addGestureRecognizer:tap];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UISwitch class]] || [touch.view isDescendantOfView:self.toggleSwitch]) {
        return NO;
    }
    return YES;
}

- (void)handleTap {
    [self.toggleSwitch setOn:!self.toggleSwitch.isOn animated:YES];
    [self switchValueChanged:self.toggleSwitch];
}

- (void)switchValueChanged:(UISwitch *)sender {
    if (self.suppressCallback) {
        return;
    }

    SettingItem *item = self.item;
    if (!item) {
        return;
    }

    NSNumber *newValue = @(sender.isOn);
    item.currentValue = newValue;

    if (item.valueChangedBlock) {
        item.valueChangedBlock(item, newValue);
    }
}

@end
