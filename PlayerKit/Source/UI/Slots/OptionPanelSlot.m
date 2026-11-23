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
@property (nonatomic, strong) UIScrollView *optionsScrollView;
@property (nonatomic, strong) UIView *optionsContentView;
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

// 动画位移采用实际面板尺寸，适应窄区域
- (CGSize)panelSize {
    return [self shownPanelFrame].size;
}

- (CGRect)shownPanelFrame {
    return [self panelFrameForSize:CGSizeMake(kPanelWidth, CGRectGetHeight([self panelLayoutBounds]))];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutPanelView:self.contentPanel toShownFrame:[self shownPanelFrame]];
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
    self.contentPanel.layoutMargins = UIEdgeInsetsZero;
    self.contentPanel.clipsToBounds = YES;
    // 使用基类内容承载视图，统一面板布局与动画坐标
    [self.panelContentHostView addSubview:self.contentPanel];
}

- (void)createOptionsStack {
    self.optionsScrollView = [[UIScrollView alloc] init];
    self.optionsScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.optionsScrollView.showsVerticalScrollIndicator = NO;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
    if (@available(iOS 11.0, *)) {
        self.optionsScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
#endif
    [self.contentPanel addSubview:self.optionsScrollView];

    self.optionsContentView = [[UIView alloc] init];
    self.optionsContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.optionsScrollView addSubview:self.optionsContentView];

    self.optionsStack = [[UIStackView alloc] init];
    self.optionsStack.axis = UILayoutConstraintAxisVertical;
    self.optionsStack.alignment = UIStackViewAlignmentFill;
    self.optionsStack.spacing = 0;
    self.optionsStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.optionsContentView addSubview:self.optionsStack];
}

- (void)setupConstraints {
    // 可视区域使用面板自身安全区，避免叠加自动滚动内边距
    UILayoutGuide *contentGuide = self.contentPanel.layoutMarginsGuide;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
    if (@available(iOS 11.0, *)) {
        contentGuide = self.contentPanel.safeAreaLayoutGuide;
    }
#endif

    // 短列表保持居中，长列表可滚动，避免低高度区域裁切选项
    NSLayoutConstraint *preferredHeight = [self.optionsContentView.heightAnchor
        constraintEqualToAnchor:self.optionsScrollView.heightAnchor];
    preferredHeight.priority = UILayoutPriorityDefaultLow;
    [NSLayoutConstraint activateConstraints:@[
        [self.optionsScrollView.topAnchor constraintEqualToAnchor:contentGuide.topAnchor],
        [self.optionsScrollView.bottomAnchor constraintEqualToAnchor:contentGuide.bottomAnchor],
        [self.optionsScrollView.leadingAnchor constraintEqualToAnchor:contentGuide.leadingAnchor],
        [self.optionsScrollView.trailingAnchor constraintEqualToAnchor:contentGuide.trailingAnchor],

        [self.optionsContentView.topAnchor constraintEqualToAnchor:self.optionsScrollView.topAnchor],
        [self.optionsContentView.bottomAnchor constraintEqualToAnchor:self.optionsScrollView.bottomAnchor],
        [self.optionsContentView.leadingAnchor constraintEqualToAnchor:self.optionsScrollView.leadingAnchor],
        [self.optionsContentView.trailingAnchor constraintEqualToAnchor:self.optionsScrollView.trailingAnchor],
        [self.optionsContentView.widthAnchor constraintEqualToAnchor:self.optionsScrollView.widthAnchor],
        [self.optionsContentView.heightAnchor constraintGreaterThanOrEqualToAnchor:self.optionsScrollView.heightAnchor],
        preferredHeight,

        [self.optionsStack.centerYAnchor constraintEqualToAnchor:self.optionsContentView.centerYAnchor],
        [self.optionsStack.leadingAnchor constraintEqualToAnchor:self.optionsContentView.leadingAnchor],
        [self.optionsStack.trailingAnchor constraintEqualToAnchor:self.optionsContentView.trailingAnchor],
        [self.optionsStack.topAnchor constraintGreaterThanOrEqualToAnchor:self.optionsContentView.topAnchor],
        [self.optionsStack.bottomAnchor constraintLessThanOrEqualToAnchor:self.optionsContentView.bottomAnchor],
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
