//
//  TopBarSlot.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "TopBarSlot.h"
#import "AliPlayerModel.h"
#import "AliPlayerController.h"
#import "PlayerStateStore.h"
#import "PlayerViewState.h"
#import "GestureNotificationDispatcher.h"
#import "GestureNotificationDelegate.h"
#import "SlotActionNotificationDispatcher.h"
#import "SlotActionNotificationDelegate.h"
#import "PlayerNotificationDelegate.h"
#import "SlotElements.h"
#import "PlayerImage.h"
#import "PlayerColor.h"
#import "PlayerFont.h"
#import "Log.h"
#import "LocaleMacros.h"
#import "LocaleKeys.h"

static const CGFloat kBarHeight = 48.0;
static const CGFloat kPaddingPortrait = 20.0;
static const CGFloat kPaddingLandscape = 34.0;
static const CGFloat kBackIconHeight = 18.0;
static const CGFloat kBackIconRightMargin = 6.0;
static const CGFloat kIconSize = 30.0;
static const CGFloat kIconRightMargin = 20.0;
static const CGFloat kSnapshotLeftMargin = 27.0;
static const CGFloat kTitleHeight = 24.0;
static const CGFloat kTitleShadowRadius = 2.0;

@interface TopBarSlot () <GestureNotificationDelegate, PlayerNotificationDelegate>

@property (nonatomic, strong) UIView *backTouchArea;
@property (nonatomic, strong) UIImageView *backIconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *snapshotButton;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) UIButton *settingButton;
@property (nonatomic, strong) dispatch_block_t autoHideBlock;

@property (nonatomic, strong) NSLayoutConstraint *backIconLeadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *settingTrailingConstraint;

// Whether external title is used (higher priority than MediaInfo)
@property (nonatomic, assign) BOOL externalTitleUsed;

@end

@implementation TopBarSlot

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
    }
    return self;
}

- (NSUInteger)onRegisterElements {
    // Download 默认隐藏（功能未实现）
    return TopBarElementBack | TopBarElementTitle | TopBarElementSettings | TopBarElementSnapshot;
}

- (void)setupContentView {
    BOOL showBack = [self isElementVisible:TopBarElementBack];
    BOOL showTitle = [self isElementVisible:TopBarElementTitle];
    BOOL showSettings = [self isElementVisible:TopBarElementSettings];
    BOOL showSnapshot = [self isElementVisible:TopBarElementSnapshot];
    BOOL showDownload = [self isElementVisible:TopBarElementDownload];

    [self buildLayoutShowBack:showBack
                    showTitle:showTitle
                 showSettings:showSettings
                 showSnapshot:showSnapshot
                 showDownload:showDownload];
    SLOGI(@"Content view setup complete");
}

- (void)buildLayoutShowBack:(BOOL)showBack
                  showTitle:(BOOL)showTitle
               showSettings:(BOOL)showSettings
               showSnapshot:(BOOL)showSnapshot
               showDownload:(BOOL)showDownload {
    if (showBack) {
        [self createBackButton];
    }
    if (showSettings) {
        [self createSettingButton];
    }
    if (showDownload) {
        [self createDownloadButton];
    }
    if (showSnapshot) {
        [self createSnapshotButton];
    }
    if (showTitle) {
        [self createTitleLabel];
    }

    [self setupConstraints];
}

#pragma mark - Slot Lifecycle

- (void)onAttach:(id<SlotHost>)host {
    [super onAttach:host];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLocaleDidChange:)
                                                 name:LocaleDidChangeNotification
                                               object:nil];
}

- (void)onDetach {
    [self cancelAutoHide];
    if (_gestureDispatcher) {
        [_gestureDispatcher removeObserver:self];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:LocaleDidChangeNotification
                                                  object:nil];
    [super onDetach];
}

- (void)onBindData:(AliPlayerModel *)model {
    if (model.videoTitle.length > 0) {
        self.externalTitleUsed = YES;
    } else {
        self.externalTitleUsed = NO;
    }
    self.titleLabel.text = model.videoTitle ?: @"";
    [self updatePaddingForFullscreen:self.host.viewState.isFullscreen];
    AliPlayerController *controller = self.host.controller;
    [controller setControlsVisible:YES];
}

- (void)onUnbindData {
    [self cancelAutoHide];
    self.titleLabel.text = @"";
    self.externalTitleUsed = NO;
}

#pragma mark - GestureDispatcher

- (void)setGestureDispatcher:(GestureNotificationDispatcher *)gestureDispatcher {
    if (_gestureDispatcher) {
        [_gestureDispatcher removeObserver:self];
    }
    _gestureDispatcher = gestureDispatcher;
    if (_gestureDispatcher) {
        [_gestureDispatcher addObserver:self];
        SLOGI(@"Registered as gesture notification observer");
    }
}

#pragma mark - GestureNotificationDelegate

- (void)gestureDidSingleTap {
    // Show/hide is now driven by playerDidChangeControlsVisible:
}

#pragma mark - Auto Hide

- (void)scheduleAutoHide {
    [self cancelAutoHide];
    __weak typeof(self) weakSelf = self;
    self.autoHideBlock = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.host) return;
        AliPlayerController *controller = strongSelf.host.controller;
        if (!controller) return;
        [controller setControlsVisible:NO];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SlotAutoHideDelay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), self.autoHideBlock);
}

- (void)cancelAutoHide {
    if (self.autoHideBlock) {
        dispatch_block_cancel(self.autoHideBlock);
        self.autoHideBlock = nil;
    }
}

- (void)resetAutoHide {
    if ([self isShowing]) {
        [self scheduleAutoHide];
    }
}

#pragma mark - Hit Testing

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (![self isShowing] || self.alpha < 0.01) {
        return nil;
    }
    if (point.y > kBarHeight) {
        return nil;
    }
    return [super hitTest:point withEvent:event];
}

#pragma mark - Actions

- (void)backButtonTapped {
    AliPlayerController *controller = self.host.controller;

    if (self.host.viewState.isFullscreen) {
        [controller setFullscreen:NO animated:YES];
        SLOGI(@"Back button tapped - exit fullscreen");
        return;
    }

    // 通过 SlotHost 协议通知宿主处理返回事件
    [self.host notifyBackPressed];
    SLOGI(@"Back button tapped - notified host");
}

- (void)settingButtonTapped {
    [self cancelAutoHide];
    if (!self.slotActionDispatcher) {
        // dispatcher 未被 wireSlotActionNotifications 连接，SettingMenuSlot 无法收到事件
        SLOGW(@"Setting button tapped but slotActionDispatcher is nil, request will be lost");
        return;
    }
    [self.slotActionDispatcher notifyObservers:^(id<SlotActionNotificationDelegate> observer) {
        if (observer && [observer respondsToSelector:@selector(slotDidRequestToggleSettingMenu)]) {
            [observer slotDidRequestToggleSettingMenu];
        }
    }];
    SLOGI(@"Setting button tapped");
}

- (void)snapshotButtonTapped {
    AliPlayerController *controller = self.host.controller;
    if (controller) {
        [controller snapshot];
    }
    [self resetAutoHide];
    SLOGI(@"Snapshot button tapped");
}

- (void)downloadButtonTapped {
    // TODO: implement download action
    [self resetAutoHide];
    SLOGI(@"Download button tapped");
}

#pragma mark - Private Methods - View Creation

- (void)createBackButton {
    // 透明容器扩大点击热区（宽度=padding+icon+margin，高度=barHeight）
    self.backTouchArea = [[UIView alloc] init];
    self.backTouchArea.backgroundColor = [UIColor clearColor];
    self.backTouchArea.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.backTouchArea];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backButtonTapped)];
    [self.backTouchArea addGestureRecognizer:tap];

    // 图标 ImageView，高度=18pt，宽度按比例缩放
    self.backIconView = [[UIImageView alloc] init];
    self.backIconView.image = [PlayerImage iconBack];
    self.backIconView.tintColor = [UIColor whiteColor];
    self.backIconView.contentMode = UIViewContentModeScaleAspectFit;
    self.backIconView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backTouchArea addSubview:self.backIconView];
}

- (void)createSettingButton {
    self.settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *icon = [PlayerImage iconSettings];
    [self.settingButton setImage:icon forState:UIControlStateNormal];
    self.settingButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.settingButton.tintColor = [UIColor whiteColor];
    self.settingButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.settingButton addTarget:self action:@selector(settingButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.settingButton];
}

- (void)createDownloadButton {
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *icon = [PlayerImage iconDownload];
    [self.downloadButton setImage:icon forState:UIControlStateNormal];
    self.downloadButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.downloadButton.tintColor = [UIColor whiteColor];
    self.downloadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.downloadButton addTarget:self action:@selector(downloadButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.downloadButton];
}

- (void)createSnapshotButton {
    self.snapshotButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *icon = [PlayerImage iconSnapshot];
    [self.snapshotButton setImage:icon forState:UIControlStateNormal];
    self.snapshotButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.snapshotButton.tintColor = [UIColor whiteColor];
    self.snapshotButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.snapshotButton addTarget:self action:@selector(snapshotButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.snapshotButton];
}

- (void)createTitleLabel {
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [PlayerFont regular16];
    self.titleLabel.textColor = [PlayerColor textWhite];
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLabel.text = @"";
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

    // 文字阴影：仅使用 layer shadow（支持 radius）
    self.titleLabel.layer.shadowColor = [PlayerColor textShadow].CGColor;
    self.titleLabel.layer.shadowOffset = CGSizeZero;
    self.titleLabel.layer.shadowRadius = kTitleShadowRadius;
    self.titleLabel.layer.shadowOpacity = 1.0;

    [self addSubview:self.titleLabel];
}

#pragma mark - Private Methods - Constraints

- (void)setupConstraints {
    CGFloat padding = kPaddingPortrait;

    NSLayoutAnchor *leftAnchor = self.leadingAnchor;
    CGFloat leftConstant = padding;

    if (self.backTouchArea) {
        [NSLayoutConstraint activateConstraints:@[
            [self.backTouchArea.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.backTouchArea.topAnchor constraintEqualToAnchor:self.topAnchor],
            [self.backTouchArea.heightAnchor constraintEqualToConstant:kBarHeight],
        ]];

        CGFloat backIconWidth = kBackIconHeight * (59.0 / 81.0);
        self.backIconLeadingConstraint = [self.backIconView.leadingAnchor constraintEqualToAnchor:self.backTouchArea.leadingAnchor constant:padding];
        [NSLayoutConstraint activateConstraints:@[
            self.backIconLeadingConstraint,
            [self.backIconView.centerYAnchor constraintEqualToAnchor:self.backTouchArea.centerYAnchor],
            [self.backIconView.heightAnchor constraintEqualToConstant:kBackIconHeight],
            [self.backIconView.widthAnchor constraintEqualToConstant:backIconWidth],
            [self.backTouchArea.trailingAnchor constraintEqualToAnchor:self.backIconView.trailingAnchor constant:kBackIconRightMargin],
        ]];

        leftAnchor = self.backTouchArea.trailingAnchor;
        leftConstant = 0;
    }

    NSLayoutAnchor *rightAnchor = self.trailingAnchor;
    CGFloat rightConstant = -padding;

    if (self.settingButton) {
        self.settingTrailingConstraint = [self.settingButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-padding];
        [NSLayoutConstraint activateConstraints:@[
            self.settingTrailingConstraint,
            [self.settingButton.centerYAnchor constraintEqualToAnchor:self.topAnchor constant:kBarHeight / 2.0],
            [self.settingButton.widthAnchor constraintEqualToConstant:kIconSize],
            [self.settingButton.heightAnchor constraintEqualToConstant:kIconSize],
        ]];
        rightAnchor = self.settingButton.leadingAnchor;
        rightConstant = -kIconRightMargin;
    }

    if (self.downloadButton) {
        [NSLayoutConstraint activateConstraints:@[
            [self.downloadButton.trailingAnchor constraintEqualToAnchor:rightAnchor constant:rightConstant],
            [self.downloadButton.centerYAnchor constraintEqualToAnchor:self.topAnchor constant:kBarHeight / 2.0],
            [self.downloadButton.widthAnchor constraintEqualToConstant:kIconSize],
            [self.downloadButton.heightAnchor constraintEqualToConstant:kIconSize],
        ]];
        rightAnchor = self.downloadButton.leadingAnchor;
        rightConstant = -kIconRightMargin;
    }

    if (self.snapshotButton) {
        [NSLayoutConstraint activateConstraints:@[
            [self.snapshotButton.trailingAnchor constraintEqualToAnchor:rightAnchor constant:rightConstant],
            [self.snapshotButton.centerYAnchor constraintEqualToAnchor:self.topAnchor constant:kBarHeight / 2.0],
            [self.snapshotButton.widthAnchor constraintEqualToConstant:kIconSize],
            [self.snapshotButton.heightAnchor constraintEqualToConstant:kIconSize],
        ]];
        rightAnchor = self.snapshotButton.leadingAnchor;
        rightConstant = -kSnapshotLeftMargin;
    }

    if (self.titleLabel) {
        [NSLayoutConstraint activateConstraints:@[
            [self.titleLabel.leadingAnchor constraintEqualToAnchor:leftAnchor constant:leftConstant],
            [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:rightAnchor constant:rightConstant],
            [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.topAnchor constant:kBarHeight / 2.0],
            [self.titleLabel.heightAnchor constraintEqualToConstant:kTitleHeight],
        ]];
    }
}

- (void)updatePaddingForFullscreen:(BOOL)isFullscreen {
    CGFloat padding = isFullscreen ? kPaddingLandscape : kPaddingPortrait;
    self.backIconLeadingConstraint.constant = padding;
    self.settingTrailingConstraint.constant = -padding;
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeFullscreen:(BOOL)isFullscreen {
    [self updatePaddingForFullscreen:isFullscreen];
}

- (void)playerDidChangeControlsVisible:(BOOL)visible {
    if (visible) {
        [self showWithAnimation:YES];
        [self scheduleAutoHide];
    } else {
        [self cancelAutoHide];
        [self hideWithAnimation:YES];
    }
}

- (void)playerDidReadyVideoTitle:(NSString *)videoTitle {
    // 仅在未使用外部 videoTitle 时，使用自动提取的值
    if (self.externalTitleUsed || videoTitle.length == 0) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.titleLabel.text = videoTitle;
    });
}

#pragma mark - Notification Handlers

- (void)onLocaleDidChange:(NSNotification *)notification {
    // Icons don't need locale updates
}

@end
