//
//  SettingMenuSlot.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SettingMenuSlot.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "PlayerStateStore.h"
#import "PlayerViewState.h"
#import "PlayerNotificationDelegate.h"
#import "SettingItem.h"
#import "SettingConstants.h"
#import "SlotElements.h"
#import "OptionPanelSlot.h"
#import "PlayerColor.h"
#import "PlayerFont.h"
#import "LocaleMacros.h"
#import "LocaleKeys.h"
#import "SettingItemViewProtocol.h"
#import "SettingSwitcherItemView.h"
#import "SettingSelectorItemView.h"
#import "TrackQuality.h"
#import "TrackUtil.h"
#import "Log.h"

static const CGFloat kTitleFontSize = 17.0;
static const CGFloat kTitleHeight = 56.0;

// Portrait (bottom sheet on VC)
static const CGFloat kPortraitPadding = 20.0;
static const CGFloat kPortraitCornerRadius = 16.0;
static const CGFloat kPortraitMaxHeight = 400.0;
static const CGFloat kPortraitItemHeight = 46.0;
static const CGFloat kPortraitGroupCornerRadius = 12.0;
static const CGFloat kPortraitGroupSpacing = 10.0;

// Landscape (right panel on self)
static const CGFloat kLandscapePanelWidth = 345.0;
static const CGFloat kLandscapePaddingH = 16.0;
static const CGFloat kLandscapePaddingTop = 20.0;
static const CGFloat kLandscapePaddingBottom = 24.0;

@interface SettingMenuSlot () <PlayerNotificationDelegate>

@property (nonatomic, strong) UIView *contentPanel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stackView;

@property (nonatomic, strong) NSArray<SettingItem *> *items;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, id<SettingItemViewProtocol>> *itemViews;

@property (nonatomic, assign) BOOL isFullscreen;
@property (nonatomic, assign) CGFloat currentPortraitPanelHeight;

// 面板与蒙层的承载容器，挂载在窗口上（见 panelHostView）
@property (nonatomic, strong) UIView *popupContainer;

@end

@implementation SettingMenuSlot

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _itemViews = [NSMutableDictionary dictionary];
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
    }
    return self;
}

#pragma mark - Slot Lifecycle

- (NSUInteger)onRegisterElements {
    return SettingMenuElementSpeed | SettingMenuElementTrackInfo | SettingMenuElementLoop
         | SettingMenuElementMute | SettingMenuElementMirrorMode | SettingMenuElementRotateMode
         | SettingMenuElementScaleMode | SettingMenuElementSubtitle;
}

- (void)setupContentView {
    // 面板视图形态取决于横竖屏，因此不在此创建，而是每次显示时由 onPrepareForShow 按当前形态构建
}

- (void)onAttach:(id<SlotHost>)host {
    [super onAttach:host];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLocaleDidChange:)
                                                 name:LocaleDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    SLOGI(@"Attached to host");
}

- (void)onDetach {
    [self teardownCurrentViews];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:LocaleDidChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];

    [super onDetach];
    SLOGI(@"Detached from host");
}

- (void)onBindData:(AliPlayerModel *)model {
    [super onBindData:model];
}

- (void)onUnbindData {
    // 面板的强制收起（无动画）由基类完成，并经 onPanelHidden 链路销毁当前视图
    [super onUnbindData];

    self.items = nil;
    [self.itemViews removeAllObjects];
}

#pragma mark - Public Methods

- (void)toggleMenu {
    if ([self isMenuVisible]) {
        [self hideMenu];
    } else {
        [self showMenu];
    }
}

- (void)showMenu {
    [self showPanel];
}

- (nullable SettingItem *)settingItemForElement:(SettingMenuElement)element {
    for (SettingItem *item in self.items) {
        if (item.element == element) {
            return item;
        }
    }
    return nil;
}

- (void)hideMenu {
    [self hidePanel];
}

#pragma mark - SlotActionNotificationDelegate

- (void)slotDidRequestToggleSettingMenu {
    SLOGI(@"Received toggle setting menu request, visible=%d, fullscreen=%d",
          self.isPanelShowing, self.host.viewState.isFullscreen);
    [self toggleMenu];
}

- (void)slotDidRequestShowSpeedPanel {
    [self ensureItemsLoaded];
    [self showOptionPanelForElement:SettingMenuElementSpeed];
}

- (void)slotDidRequestShowQualityPanel {
    [self ensureItemsLoaded];
    [self showOptionPanelForElement:SettingMenuElementTrackInfo];
}

#pragma mark - Private Methods - Option Panel Bridge

- (void)ensureItemsLoaded {
    if (self.items) {
        return;
    }
    AliPlayerController *controller = self.host.controller;
    if (!controller) {
        return;
    }
    self.items = [SettingConstants defaultItemsWithController:controller];
    [self syncWithPlayerState];
}

- (void)showOptionPanelForElement:(SettingMenuElement)element {
    UIView<SlotProtocol> *slot = [self.host slotViewForType:SlotTypeOptionPanel];
    if (![slot isKindOfClass:[OptionPanelSlot class]]) return;

    SettingItem *item = [self settingItemForElement:element];
    if (!item || !item.options) return;

    id<SettingOptions> options = item.options;
    NSInteger count = [options count];
    if (count == 0) return;

    NSMutableArray<NSString *> *texts = [NSMutableArray array];
    NSMutableArray *values = [NSMutableArray array];
    NSInteger selectedIdx = 0;

    for (NSInteger i = 0; i < count; i++) {
        id optionValue = [options objectAtIndex:i];
        [values addObject:optionValue];

        NSString *displayText;
        if (item.formatterBlock) {
            displayText = item.formatterBlock(optionValue);
        } else if ([optionValue isKindOfClass:[TrackQuality class]]) {
            TrackQuality *track = (TrackQuality *)optionValue;
            displayText = [NSString stringWithFormat:@"%ldP", (long)track.height];
        } else {
            displayText = [optionValue description];
        }
        [texts addObject:displayText];

        if ([optionValue isEqual:item.currentValue]) {
            selectedIdx = i;
        }
    }

    OptionPanelSlot *panel = (OptionPanelSlot *)slot;
    [panel showWithOptions:texts selectedIndex:selectedIdx onSelect:^(NSInteger index) {
        id newValue = values[index];
        item.currentValue = newValue;
        if (item.valueChangedBlock) {
            item.valueChangedBlock(item, newValue);
        }
    }];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    if (state == PlayerStateStopped || state == PlayerStateError) {
        [self hideMenu];
    }
}

- (void)playerDidTrackReady:(NSArray<TrackQuality *> *)tracks {
    [self applyClarityOptionsWithTracks:tracks];
}

- (void)playerDidTrackChanged:(TrackQuality *)quality {
    [self applySelectedTrack:quality];
}

#pragma mark - Private Methods - Menu Visibility

- (BOOL)isMenuVisible {
    return self.isPanelShowing;
}

#pragma mark - BasePanelSlot Overrides

/**
 * 竖屏时播放器只占据屏幕顶部一小块区域，底部弹窗必须覆盖整个屏幕，
 * 因此面板与蒙层统一承载在挂到窗口上的 popupContainer 内，而非插槽自身的视图层级。
 * 该容器每次显示时重建、每次隐藏后销毁（见 onPrepareForShow / onPanelHidden）。
 */
- (UIView *)panelHostView {
    return self.popupContainer ?: self;
}

- (nullable UIView *)panelView {
    return self.contentPanel;
}

/// 横屏为右侧抽屉，竖屏为底部弹窗
- (PanelSlideEdge)panelSlideEdge {
    return self.isFullscreen ? PanelSlideEdgeRight : PanelSlideEdgeBottom;
}

/// 面板 frame 由 mountPopupContainerInWindow: 手动设定，这里直接给出对应的确定尺寸
- (CGSize)panelSize {
    CGSize hostSize = self.popupContainer.bounds.size;
    if (self.isFullscreen) {
        return CGSizeMake(kLandscapePanelWidth, hostSize.height);
    }
    return CGSizeMake(hostSize.width, self.currentPortraitPanelHeight);
}

/// 动画期间容器已禁用交互，此处放开触摸以免阻塞其他手势
- (UIViewAnimationOptions)showAnimationOptions {
    return [super showAnimationOptions] | UIViewAnimationOptionAllowUserInteraction;
}

- (UIViewAnimationOptions)hideAnimationOptions {
    return [super hideAnimationOptions] | UIViewAnimationOptionAllowUserInteraction;
}

/// 按当前横竖屏形态重建视图与设置项；无可用窗口或无设置项时取消本次显示
- (BOOL)onPrepareForShow {
    // 形态可能已切换，先彻底清理上一次的残留视图
    [self teardownCurrentViews];

    UIWindow *window = [self resolveWindow];
    if (!window) {
        SLOGW(@"No window available, ignoring show request");
        return NO;
    }

    self.isFullscreen = self.host.viewState.isFullscreen;
    if (self.isFullscreen) {
        [self buildLandscapeViews];
    } else {
        [self buildPortraitViews];
    }
    [self rebuildItemsForFullscreen:self.isFullscreen];

    if (self.stackView.arrangedSubviews.count == 0) {
        SLOGW(@"No setting item available, ignoring show request");
        [self teardownCurrentViews];
        return NO;
    }

    [self mountPopupContainerInWindow:window];

    SLOGI(@"Show menu (%@)", self.isFullscreen ? @"landscape right panel" : @"portrait bottom sheet");
    return YES;
}

- (void)onPanelShown {
    self.popupContainer.userInteractionEnabled = YES;
}

/// 退场动画期间先冻结交互，避免面板在滑出过程中被再次点击
- (void)onPerformHideAnimation {
    self.popupContainer.userInteractionEnabled = NO;
    [super onPerformHideAnimation];
}

- (void)onPanelHidden {
    [super onPanelHidden];
    [self teardownCurrentViews];
    SLOGI(@"Hide menu");
}

#pragma mark - Private Methods - Panel Mounting

/// 优先取宿主视图所在窗口，其次退化到应用主窗口
- (nullable UIWindow *)resolveWindow {
    UIWindow *window = [self.host hostView].window;
    if (!window) {
        window = UIApplication.sharedApplication.keyWindow;
    }
    return window;
}

/**
 * 把承载容器铺满窗口并挂载，同时把面板摆到"已显示"的终态位置。
 * 隐藏态由基类通过 transform 平移到屏外，因此这里无需预置屏外 frame。
 */
- (void)mountPopupContainerInWindow:(UIWindow *)window {
    CGRect windowBounds = window.bounds;

    self.popupContainer.frame = windowBounds;
    // 进场动画结束后再放开交互（见 onPanelShown）
    self.popupContainer.userInteractionEnabled = NO;
    [window addSubview:self.popupContainer];

    if (self.isFullscreen) {
        self.contentPanel.frame = CGRectMake(windowBounds.size.width - kLandscapePanelWidth, 0,
                                            kLandscapePanelWidth, windowBounds.size.height);
    } else {
        CGFloat panelHeight = self.currentPortraitPanelHeight;
        self.contentPanel.frame = CGRectMake(0, windowBounds.size.height - panelHeight,
                                            windowBounds.size.width, panelHeight);
    }
}

#pragma mark - Private Methods - Portrait (Bottom Sheet)

- (void)buildPortraitViews {
    // 蒙层由基类持有，并在显示时插入到 panelHostView（即 popupContainer）的最底层
    self.popupContainer = [[UIView alloc] init];
    self.popupContainer.backgroundColor = [UIColor clearColor];

    self.contentPanel = [[UIView alloc] init];
    self.contentPanel.backgroundColor = [PlayerColor settingPanelBackground];
    self.contentPanel.clipsToBounds = YES;
    self.contentPanel.layer.cornerRadius = kPortraitCornerRadius;
    self.contentPanel.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self.popupContainer addSubview:self.contentPanel];

    [self createScrollViewWithMargins:YES];

    NSLayoutConstraint *scrollHeightConstraint = [self.scrollView.heightAnchor constraintEqualToAnchor:self.stackView.heightAnchor];
    scrollHeightConstraint.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.contentPanel.topAnchor constant:kPortraitPadding],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.contentPanel.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.contentPanel.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.contentPanel.bottomAnchor],
        scrollHeightConstraint,

        [self.stackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.stackView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.stackView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.stackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.stackView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],
    ]];
}

#pragma mark - Private Methods - Landscape (Right Panel)

- (void)buildLandscapeViews {
    // 蒙层由基类持有，并在显示时插入到 panelHostView（即 popupContainer）的最底层
    self.popupContainer = [[UIView alloc] init];
    self.popupContainer.backgroundColor = [UIColor clearColor];

    self.contentPanel = [[UIView alloc] init];
    self.contentPanel.backgroundColor = [PlayerColor settingPanelBackground];
    self.contentPanel.clipsToBounds = YES;
    [self.popupContainer addSubview:self.contentPanel];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LocalizedString(LocaleKeySettingMenuTitle);
    self.titleLabel.font = [UIFont boldSystemFontOfSize:kTitleFontSize];
    self.titleLabel.textColor = [PlayerColor settingOptionSelected];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentPanel addSubview:self.titleLabel];

    [self createScrollViewWithMargins:NO];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentPanel.topAnchor constant:kLandscapePaddingTop],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentPanel.leadingAnchor constant:kLandscapePaddingH],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.contentPanel.trailingAnchor constant:-kLandscapePaddingH],
        [self.titleLabel.heightAnchor constraintEqualToConstant:kTitleHeight - kLandscapePaddingTop],

        [self.scrollView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.contentPanel.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.contentPanel.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.contentPanel.bottomAnchor constant:-kLandscapePaddingBottom],

        [self.stackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.stackView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.stackView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.stackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.stackView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],
    ]];
}

#pragma mark - Private Methods - Shared UI

- (void)createScrollViewWithMargins:(BOOL)useMargins {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.contentPanel addSubview:self.scrollView];

    self.stackView = [[UIStackView alloc] init];
    self.stackView.axis = UILayoutConstraintAxisVertical;
    self.stackView.alignment = UIStackViewAlignmentFill;
    self.stackView.distribution = UIStackViewDistributionFill;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;

    if (useMargins) {
        self.stackView.spacing = kPortraitGroupSpacing;
        self.stackView.layoutMargins = UIEdgeInsetsMake(0, kPortraitPadding, kPortraitPadding, kPortraitPadding);
        self.stackView.layoutMarginsRelativeArrangement = YES;
    } else {
        self.stackView.spacing = 0;
        self.stackView.layoutMarginsRelativeArrangement = NO;
    }

    [self.scrollView addSubview:self.stackView];
}

#pragma mark - Private Methods - Teardown

- (void)teardownCurrentViews {
    // 强制取消任何正在进行的动画，防止动画 completion 回来后
    // 再次操作已被释放的视图引用
    if (self.popupContainer) {
        [self.popupContainer.layer removeAllAnimations];
        [self.popupContainer removeFromSuperview];
        self.popupContainer = nil;
    }

    if (self.contentPanel) {
        [self.contentPanel.layer removeAllAnimations];
        [self.contentPanel removeFromSuperview];
        self.contentPanel = nil;
    }
    self.titleLabel = nil;
    self.scrollView = nil;
    self.stackView = nil;
    self.currentPortraitPanelHeight = 0;

    [self.itemViews removeAllObjects];
}

#pragma mark - Private Methods - Data

- (void)rebuildItemsForFullscreen:(BOOL)isFullscreen {
    for (UIView *view in self.stackView.arrangedSubviews) {
        [self.stackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    [self.itemViews removeAllObjects];

    AliPlayerController *controller = self.host.controller;
    if (!controller) {
        return;
    }

    self.items = [SettingConstants defaultItemsWithController:controller];
    [self syncWithPlayerState];

    NSMutableArray<SettingItem *> *filteredItems = [NSMutableArray array];
    for (SettingItem *item in self.items) {
        if (![item isSupportedInScene:[self currentSceneType]]) {
            continue;
        }
        if (![self isElementVisible:item.element]) {
            continue;
        }
        if (isFullscreen &&
            (item.element == SettingMenuElementSpeed || item.element == SettingMenuElementTrackInfo)) {
            continue;
        }
        [filteredItems addObject:item];
    }

    if (isFullscreen) {
        [self buildLandscapeLayoutWithItems:filteredItems];
    } else {
        [self buildPortraitLayoutWithItems:filteredItems];
    }
}

- (void)buildLandscapeLayoutWithItems:(NSArray<SettingItem *> *)items {
    for (NSInteger i = 0; i < (NSInteger)items.count; i++) {
        SettingItem *item = items[i];
        id<SettingItemViewProtocol> itemView = [self createItemViewForItem:item];
        if (!itemView) continue;

        [itemView bindItem:item];
        self.itemViews[@(item.element)] = itemView;

        UIView *view = itemView.contentView;
        [self.stackView addArrangedSubview:view];
        [view.heightAnchor constraintEqualToConstant:SettingItemHeight].active = YES;

        BOOL isLast = (i == (NSInteger)items.count - 1);
        if (isLast) {
            [self hideSeparatorForItemView:itemView];
        }
    }
}

- (void)buildPortraitLayoutWithItems:(NSArray<SettingItem *> *)items {
    NSMutableOrderedSet<NSNumber *> *groupOrder = [NSMutableOrderedSet orderedSet];
    NSMutableDictionary<NSNumber *, NSMutableArray<SettingItem *> *> *groups = [NSMutableDictionary dictionary];

    for (SettingItem *item in items) {
        NSNumber *groupKey = @(item.group);
        if (!groups[groupKey]) {
            groups[groupKey] = [NSMutableArray array];
            [groupOrder addObject:groupKey];
        }
        [groups[groupKey] addObject:item];
    }

    NSInteger totalItemCount = 0;

    for (NSNumber *groupKey in groupOrder) {
        NSArray<SettingItem *> *groupItems = groups[groupKey];

        UIView *cardView = [[UIView alloc] init];
        cardView.backgroundColor = [PlayerColor settingItemBackground];
        cardView.layer.cornerRadius = kPortraitGroupCornerRadius;
        cardView.clipsToBounds = YES;
        cardView.translatesAutoresizingMaskIntoConstraints = NO;

        UIStackView *groupStack = [[UIStackView alloc] init];
        groupStack.axis = UILayoutConstraintAxisVertical;
        groupStack.alignment = UIStackViewAlignmentFill;
        groupStack.spacing = 0;
        groupStack.translatesAutoresizingMaskIntoConstraints = NO;
        [cardView addSubview:groupStack];

        [NSLayoutConstraint activateConstraints:@[
            [groupStack.topAnchor constraintEqualToAnchor:cardView.topAnchor],
            [groupStack.leadingAnchor constraintEqualToAnchor:cardView.leadingAnchor],
            [groupStack.trailingAnchor constraintEqualToAnchor:cardView.trailingAnchor],
            [groupStack.bottomAnchor constraintEqualToAnchor:cardView.bottomAnchor],
        ]];

        for (NSInteger i = 0; i < (NSInteger)groupItems.count; i++) {
            SettingItem *item = groupItems[i];
            id<SettingItemViewProtocol> itemView = [self createItemViewForItem:item];
            if (!itemView) continue;

            [itemView bindItem:item];
            self.itemViews[@(item.element)] = itemView;

            UIView *view = itemView.contentView;
            [groupStack addArrangedSubview:view];
            [view.heightAnchor constraintEqualToConstant:kPortraitItemHeight].active = YES;

            BOOL isLast = (i == (NSInteger)groupItems.count - 1);
            if (isLast) {
                [self hideSeparatorForItemView:itemView];
            }
        }

        totalItemCount += (NSInteger)groupItems.count;
        [self.stackView addArrangedSubview:cardView];
    }

    // Calculate panel height based on actual content
    NSInteger groupCount = (NSInteger)groupOrder.count;
    CGFloat contentHeight = kPortraitPadding
                          + totalItemCount * kPortraitItemHeight
                          + MAX(0, groupCount - 1) * kPortraitGroupSpacing
                          + kPortraitPadding;
    self.currentPortraitPanelHeight = MIN(contentHeight, kPortraitMaxHeight);
}

- (id<SettingItemViewProtocol>)createItemViewForItem:(SettingItem *)item {
    switch (item.type) {
        case SettingItemTypeSelector:
            return [[SettingSelectorItemView alloc] init];
        case SettingItemTypeSwitcher:
            return [[SettingSwitcherItemView alloc] init];
    }
    return nil;
}

- (void)hideSeparatorForItemView:(id<SettingItemViewProtocol>)itemView {
    if (itemView && [itemView respondsToSelector:@selector(separatorView)]) {
        UIView *separator = [(id)itemView separatorView];
        separator.hidden = YES;
    }
}

- (void)syncWithPlayerState {
    PlayerStateStore *store = self.host.playerStateStore;
    if (!store) {
        return;
    }

    NSArray<TrackQuality *> *qualityList = store.trackQualityList;
    if (qualityList.count > 0) {
        [self applyClarityOptionsWithTracks:qualityList];
    }

    [self updateItemValue:SettingMenuElementSpeed withValue:@(store.speed)];
    [self updateItemValue:SettingMenuElementLoop withValue:@(store.isLoop)];
    [self updateItemValue:SettingMenuElementMute withValue:@(store.isMuted)];
    [self updateItemValue:SettingMenuElementMirrorMode withValue:@(store.mirrorMode)];
    [self updateItemValue:SettingMenuElementScaleMode withValue:@(store.scaleMode)];
    [self updateItemValue:SettingMenuElementRotateMode withValue:@(store.rotateMode)];
}

- (void)updateItemValue:(SettingMenuElement)element withValue:(id)value {
    if (!value) {
        return;
    }

    SettingItem *item = [self settingItemForElement:element];
    if (item) {
        item.currentValue = value;
    }

    id<SettingItemViewProtocol> itemView = self.itemViews[@(element)];
    if (itemView) {
        [itemView updateValueOnly:value];
    }
}

#pragma mark - Private Methods - Clarity

- (void)applyClarityOptionsWithTracks:(NSArray<TrackQuality *> *)tracks {
    SettingItem *qualityItem = [self settingItemForElement:SettingMenuElementTrackInfo];
    if (!qualityItem) {
        return;
    }

    NSArray<TrackQuality *> *filtered = [TrackUtil filterVideoTrackQualityList:tracks];
    if (filtered.count == 0) {
        return;
    }

    qualityItem.options = [ArraySettingOptions optionsWithArray:filtered];

    if (!qualityItem.currentValue) {
        TrackQuality *selected = self.host.playerStateStore.selectedTrackQuality;
        TrackQuality *match = nil;
        if (selected) {
            for (TrackQuality *track in filtered) {
                if (track.index == selected.index) {
                    match = track;
                    break;
                }
            }
        }
        qualityItem.currentValue = match ?: filtered.firstObject;
    }

    id<SettingItemViewProtocol> itemView = self.itemViews[@(SettingMenuElementTrackInfo)];
    if (itemView) {
        [itemView bindItem:qualityItem];
    }
}

- (void)applySelectedTrack:(TrackQuality *)quality {
    if (!quality) {
        return;
    }

    SettingItem *qualityItem = [self settingItemForElement:SettingMenuElementTrackInfo];
    if (!qualityItem || !qualityItem.options) {
        return;
    }

    id<SettingOptions> options = qualityItem.options;
    NSInteger count = [options count];
    for (NSInteger i = 0; i < count; i++) {
        TrackQuality *option = [options objectAtIndex:i];
        if (option.index == quality.index) {
            qualityItem.currentValue = option;
            id<SettingItemViewProtocol> itemView = self.itemViews[@(SettingMenuElementTrackInfo)];
            if (itemView) {
                [itemView updateValueOnly:option];
            }
            break;
        }
    }
}

#pragma mark - Notification Handlers

- (void)onLocaleDidChange:(NSNotification *)notification {
    if (self.titleLabel) {
        self.titleLabel.text = LocalizedString(LocaleKeySettingMenuTitle);
    }
}

- (void)onAppDidEnterBackground:(NSNotification *)notification {
    // 进入后台时动画不会执行，直接无动画收起，避免面板残留在窗口上
    [self hidePanelAnimated:NO];
}

@end
