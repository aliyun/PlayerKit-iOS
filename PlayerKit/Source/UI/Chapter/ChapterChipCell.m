//
//  ChapterChipCell.m
//  AliPlayerKit
//
//  Created by keria on 2026/8/3.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "ChapterChipCell.h"

#pragma mark - Constants

/// Chip 文字字体大小
static const CGFloat kChipFontSize = 10.0;

/// Chip 圆角半径
static const CGFloat kChipCornerRadius = 6.0;

/// Chip 水平内边距
static const CGFloat kChipPaddingH = 10.0;

/// Chip 垂直内边距
static const CGFloat kChipPaddingV = 6.0;

/// Chip 最大宽度
static const CGFloat kChipMaxWidth = 160.0;

@interface ChapterChipCell ()

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation ChapterChipCell

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - Setup

- (void)setupUI {
    self.contentView.layer.cornerRadius = kChipCornerRadius;
    self.contentView.layer.masksToBounds = YES;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:kChipFontSize weight:UIFontWeightMedium];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.titleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kChipPaddingH],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kChipPaddingH],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:kChipPaddingV],
        [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-kChipPaddingV],
    ]];

    // 最大宽度约束
    NSLayoutConstraint *maxWidth = [self.contentView.widthAnchor constraintLessThanOrEqualToConstant:kChipMaxWidth];
    maxWidth.active = YES;

    [self updateAppearanceForSelected:NO];
}

#pragma mark - Public Methods

- (void)configureWithText:(NSString *)text isCurrent:(BOOL)isCurrent {
    self.titleLabel.text = text;
    [self updateAppearanceForSelected:isCurrent];
}

#pragma mark - Selection

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self updateAppearanceForSelected:selected];
}

#pragma mark - Private Methods

- (void)updateAppearanceForSelected:(BOOL)selected {
    if (selected) {
        // 选中：深灰背景 rgba(51,51,51,1)，白色文字
        self.contentView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        self.titleLabel.textColor = [UIColor whiteColor];
    } else {
        // 未选中：半透明白底，白色文字（设计稿 rgba(255,255,255,0.1)）
        self.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        self.titleLabel.textColor = [UIColor whiteColor];
    }
}

@end
