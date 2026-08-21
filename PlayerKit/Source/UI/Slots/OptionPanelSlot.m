//
//  OptionPanelSlot.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "OptionPanelSlot.h"
#import "PlayerColor.h"
#import "PlayerFont.h"
#import "Log.h"

static const CGFloat kPanelWidth = 200.0;
static const CGFloat kItemHeight = 54.0;
static const CGFloat kItemFontSize = 14.0;

@interface OptionPanelSlot ()

@property (nonatomic, strong) UIView *contentPanel;
@property (nonatomic, strong) UIStackView *optionsStack;

@property (nonatomic, copy) NSArray<NSString *> *displayTexts;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, copy) void(^selectBlock)(NSInteger index);
@property (nonatomic, strong) NSMutableArray<UILabel *> *optionLabels;

@end

@implementation OptionPanelSlot

#pragma mark - BasePanelSlot Overrides

/// 面板贴右侧边缘，由基类统一以 transform 滑入滑出
- (nullable UIView *)panelView {
    return self.contentPanel;
}

- (PanelSlideEdge)panelSlideEdge {
    return PanelSlideEdgeRight;
}

/// 宽度由约束固定为 kPanelWidth，直接给出确定尺寸，不依赖布局是否已结算
- (CGSize)panelSize {
    return CGSizeMake(kPanelWidth, self.bounds.size.height);
}

- (NSTimeInterval)animationDuration {
    return 0.25;
}

/// 显示前按最新的 displayTexts / selectedIndex 重建选项
- (BOOL)onPrepareForShow {
    [self rebuildOptionLabels];
    return YES;
}

- (void)onPanelHidden {
    [super onPanelHidden];
    self.selectBlock = nil;
}

#pragma mark - Slot Lifecycle

- (void)setupContentView {
    self.hidden = YES;
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;

    _optionLabels = [NSMutableArray array];

    [self createContentPanel];
    [self createOptionsStack];
    [self setupConstraints];

    SLOGI(@"OptionPanelSlot content view setup complete");
}

#pragma mark - Public

- (void)showWithOptions:(NSArray<NSString *> *)displayTexts
          selectedIndex:(NSInteger)selectedIndex
               onSelect:(void(^)(NSInteger index))selectBlock {
    self.displayTexts = displayTexts;
    self.selectedIndex = selectedIndex;
    self.selectBlock = selectBlock;

    [self showPanel];

    SLOGI(@"Show option panel, options count: %ld", (long)displayTexts.count);
}

#pragma mark - Private - UI

- (void)createContentPanel {
    self.contentPanel = [[UIView alloc] init];
    self.contentPanel.backgroundColor = [PlayerColor settingPanelBackground];
    self.contentPanel.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentPanel.clipsToBounds = YES;
    [self addSubview:self.contentPanel];
}

- (void)createOptionsStack {
    self.optionsStack = [[UIStackView alloc] init];
    self.optionsStack.axis = UILayoutConstraintAxisVertical;
    self.optionsStack.alignment = UIStackViewAlignmentFill;
    self.optionsStack.spacing = 0;
    self.optionsStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentPanel addSubview:self.optionsStack];
}

- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:@[
        [self.contentPanel.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.contentPanel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.contentPanel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.contentPanel.widthAnchor constraintEqualToConstant:kPanelWidth],

        [self.optionsStack.centerYAnchor constraintEqualToAnchor:self.contentPanel.centerYAnchor],
        [self.optionsStack.leadingAnchor constraintEqualToAnchor:self.contentPanel.leadingAnchor],
        [self.optionsStack.trailingAnchor constraintEqualToAnchor:self.contentPanel.trailingAnchor],
    ]];
}

#pragma mark - Private - Data

- (void)rebuildOptionLabels {
    for (UIView *v in self.optionsStack.arrangedSubviews) {
        [self.optionsStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    [self.optionLabels removeAllObjects];

    for (NSInteger i = 0; i < (NSInteger)self.displayTexts.count; i++) {
        UILabel *label = [[UILabel alloc] init];
        label.text = self.displayTexts[i];
        label.textAlignment = NSTextAlignmentCenter;
        label.userInteractionEnabled = YES;
        label.tag = i;
        label.translatesAutoresizingMaskIntoConstraints = NO;

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(optionTapped:)];
        [label addGestureRecognizer:tap];

        [self.optionsStack addArrangedSubview:label];
        [label.heightAnchor constraintEqualToConstant:kItemHeight].active = YES;
        [self.optionLabels addObject:label];
    }

    [self refreshStyles];
}

- (void)refreshStyles {
    for (NSInteger i = 0; i < (NSInteger)self.optionLabels.count; i++) {
        UILabel *label = self.optionLabels[i];
        BOOL selected = (i == self.selectedIndex);

        if (selected) {
            label.font = [UIFont boldSystemFontOfSize:kItemFontSize];
            label.textColor = [PlayerColor settingOptionSelected];
        } else {
            label.font = [UIFont systemFontOfSize:kItemFontSize];
            label.textColor = [PlayerColor settingOptionNormal];
        }
    }
}

#pragma mark - Actions

- (void)optionTapped:(UITapGestureRecognizer *)gesture {
    NSInteger index = gesture.view.tag;
    if (index < 0 || index >= (NSInteger)self.displayTexts.count) {
        return;
    }

    self.selectedIndex = index;
    [self refreshStyles];

    if (self.selectBlock) {
        self.selectBlock(index);
    }

    [self hidePanel];
}

@end
