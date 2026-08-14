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
static const CGFloat kChipFontSize = 12.0;

/// Chip 圆角半径
static const CGFloat kChipCornerRadius = 16.0;

/// Chip 水平内边距
static const CGFloat kChipPaddingH = 12.0;

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
    self.titleLabel.font = [UIFont systemFontOfSize:kChipFontSize];
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
        // 选中：背景 #E6FFFFFF，文字 #222222
        self.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
        self.titleLabel.textColor = [UIColor colorWithRed:0.133 green:0.133 blue:0.133 alpha:1.0];
    } else {
        // 未选中：背景 #CC222222，文字白色
        self.contentView.backgroundColor = [UIColor colorWithRed:0.133
                                                           green:0.133
                                                            blue:0.133
                                                           alpha:0.8];
        self.titleLabel.textColor = [UIColor whiteColor];
    }
}

@end
