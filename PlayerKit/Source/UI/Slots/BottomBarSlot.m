//
//  BottomBarSlot.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BottomBarSlot.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "PlayerNotificationDelegate.h"
#import "PlayerStateStore.h"
#import "PlayerViewState.h"
#import "GestureNotificationDispatcher.h"
#import "GestureNotificationDelegate.h"
#import "SlotActionNotificationDispatcher.h"
#import "SlotActionNotificationDelegate.h"
#import "SlotElements.h"
#import "PlayerImage.h"
#import "PlayerColor.h"
#import "PlayerFont.h"
#import "LocaleMacros.h"
#import "LocaleKeys.h"
#import "Log.h"
#import "SceneType.h"

#pragma mark - Constants

static const CGFloat kPaddingPortraitH = 20.0;
static const CGFloat kPaddingPortraitV = 2.0;
static const CGFloat kPaddingLandscapeH = 34.0;
static const CGFloat kPaddingLandscapeTop = 11.0;
static const CGFloat kPaddingLandscapeBottom = 0.0;
static const CGFloat kIconSize = 30.0;
static const CGFloat kIconPadding = 3.0;
static const CGFloat kThumbSizePortrait = 8.0;
static const CGFloat kThumbTouchSize = 14.0;
static const CGFloat kThumbSizeLandscape = 14.0;
static const CGFloat kTrackHeight = 4.0;
static const CGFloat kItemMarginH = 8.0;
static const CGFloat kItemMarginV = 12.0;
static const CGFloat kBtnMarginH = 15.0;
static const CGFloat kTitleShadowRadius = 2.0;
static const NSTimeInterval kMillisecondsPerSecond = 1000.0;
static const NSInteger kSecondsPerMinute = 60;
static const CGFloat kThumbHighlightScale = 1.5;

@interface BottomBarSlot () <PlayerNotificationDelegate, GestureNotificationDelegate>

@property (nonatomic, strong) UIView *portraitContainer;
@property (nonatomic, strong) UIView *landscapeContainer;

// Portrait elements
@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UIProgressView *bufferProgressView;
@property (nonatomic, strong) UISlider *progressSlider;
@property (nonatomic, strong) UILabel *timeLabel;

// Landscape elements
@property (nonatomic, strong) UILabel *timeLabelLandscape;
@property (nonatomic, strong) UIProgressView *bufferProgressViewLandscape;
@property (nonatomic, strong) UISlider *progressSliderLandscape;
@property (nonatomic, strong) UIButton *playPauseButtonLandscape;
@property (nonatomic, strong) UIButton *speedButton;
@property (nonatomic, strong) UIButton *qualityButton;

@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UIButton *refreshButtonLandscape;

@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) BOOL isSeeking;
@property (nonatomic, assign) NSInteger seekSequence;
@property (nonatomic, assign) BOOL isLandscapeLayout;
@property (nonatomic, copy) NSString *cachedTimeFormat;
@property (nonatomic, strong) dispatch_block_t autoHideBlock;

@end

@implementation BottomBarSlot

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.deferContentCreation = YES;
    }
    return self;
}

- (NSUInteger)onRegisterElements {
    // Play / Progress 始终注册；Refresh 与 Speed 根据 sceneType 互斥
    NSUInteger mask = BottomBarElementPlay | BottomBarElementProgress;
    if ([self currentSceneType] == SceneTypeLive) {
        mask |= BottomBarElementRefresh;
    } else {
        mask |= BottomBarElementSpeed;
    }
    return mask;
}

- (void)setupContentView {
    BOOL showPlay = [self isElementVisible:BottomBarElementPlay];
    BOOL showRefresh = [self isElementVisible:BottomBarElementRefresh];
    BOOL showProgress = [self isElementVisible:BottomBarElementProgress];
    BOOL showSpeed = [self isElementVisible:BottomBarElementSpeed];

    [self buildPortraitLayoutShowPlay:showPlay showRefresh:showRefresh showProgress:showProgress];
    [self buildLandscapeLayoutShowPlay:showPlay showRefresh:showRefresh showProgress:showProgress showSpeed:showSpeed];

    self.landscapeContainer.hidden = YES;
}

#pragma mark - Slot Lifecycle

- (void)onAttach:(id<SlotHost>)host {
    [super onAttach:host];
    self.cachedTimeFormat = LocalizedString(LocaleKeyBottomBarTimeFormat);
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
    [super onBindData:model];
    [self resetProgressUI];
    [self updatePlayPauseState];
    [self updateLayoutForFullscreen:self.host.viewState.isFullscreen];
    AliPlayerController *controller = self.host.controller;
    [controller setControlsVisible:YES];
}

- (void)onUnbindData {
    [self cancelAutoHide];
    if (self.isDragging) {
        self.isDragging = NO;
        self.host.controller.controlsVisibilityLocked = NO;
    }
    [self resetProgressUI];
    [super onUnbindData];
}

#pragma mark - GestureDispatcher

- (void)setGestureDispatcher:(GestureNotificationDispatcher *)gestureDispatcher {
    if (_gestureDispatcher) {
        [_gestureDispatcher removeObserver:self];
    }
    _gestureDispatcher = gestureDispatcher;
    if (_gestureDispatcher) {
        [_gestureDispatcher addObserver:self];
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
        if (!strongSelf) return;
        [strongSelf.host.controller setControlsVisible:NO];
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

    if (self.isLandscapeLayout) {
        CGPoint containerPoint = [self.landscapeContainer convertPoint:point fromView:self];
        if ([self.landscapeContainer pointInside:containerPoint withEvent:event]) {
            return [self.landscapeContainer hitTest:containerPoint withEvent:event];
        }
        return nil;
    }

    CGPoint containerPoint = [self.portraitContainer convertPoint:point fromView:self];
    if ([self.portraitContainer pointInside:containerPoint withEvent:event]) {
        return [self.portraitContainer hitTest:containerPoint withEvent:event];
    }
    return nil;
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    [self updatePlayPauseState];
}

- (void)playerDidChangeFullscreen:(BOOL)isFullscreen {
    [self updateLayoutForFullscreen:isFullscreen];
}

- (void)playerDidChangeControlsVisible:(BOOL)visible {
    if (visible) {
        [self showWithAnimation:YES];
        if (!self.isDragging) {
            [self scheduleAutoHide];
        }
    } else {
        [self cancelAutoHide];
        [self hideWithAnimation:YES];
    }
}

- (void)playerDidUpdateCurrentPosition:(NSInteger)position
                              duration:(NSInteger)duration
                      bufferedPosition:(NSInteger)bufferedPosition {
    if (self.isDragging || self.isSeeking) {
        return;
    }

    float progress = duration > 0 ? (float)position / (float)duration : 0;
    float buffer = duration > 0 ? (float)bufferedPosition / (float)duration : 0;
    NSString *timeText = [self formatTimeString:position duration:duration];

    self.progressSlider.value = progress;
    self.bufferProgressView.progress = buffer;
    self.timeLabel.text = timeText;

    self.progressSliderLandscape.value = progress;
    self.bufferProgressViewLandscape.progress = buffer;
    self.timeLabelLandscape.text = timeText;
}

#pragma mark - Actions

- (void)playPauseButtonTapped {
    AliPlayerController *controller = self.host.controller;
    if (!controller) return;

    if (controller.playerState == PlayerStatePlaying) {
        [controller pause];
    } else if (controller.playerState == PlayerStateCompleted) {
        [controller replay];
    } else {
        [controller play];
    }
    [self updatePlayPauseState];
    [self resetAutoHide];
}


- (void)refreshButtonTapped {
    AliPlayerController *controller = self.host.controller;
    if (!controller) return;
    [controller replay];
    [self resetAutoHide];
}

- (void)speedButtonTapped {
    [self resetAutoHide];
    [self.slotActionDispatcher notifyObservers:^(id<SlotActionNotificationDelegate> observer) {
        if (observer && [observer respondsToSelector:@selector(slotDidRequestShowSpeedPanel)]) {
            [observer slotDidRequestShowSpeedPanel];
        }
    }];
    SLOGI(@"Speed button tapped");
}

- (void)qualityButtonTapped {
    [self resetAutoHide];
    [self.slotActionDispatcher notifyObservers:^(id<SlotActionNotificationDelegate> observer) {
        if (observer && [observer respondsToSelector:@selector(slotDidRequestShowQualityPanel)]) {
            [observer slotDidRequestShowQualityPanel];
        }
    }];
    SLOGI(@"Quality button tapped");
}

- (void)sliderTouchDown:(UISlider *)slider {
    if ([self currentSceneType] == SceneTypeLive || [self currentSceneType] == SceneTypeRestricted) return;
    self.isDragging = YES;
    [self cancelAutoHide];
    self.host.controller.controlsVisibilityLocked = YES;
}

- (void)sliderValueChanged:(UISlider *)slider {
    if (!self.isDragging) return;
    AliPlayerController *controller = self.host.controller;
    NSInteger duration = controller.duration;
    NSInteger position = (NSInteger)(slider.value * duration);
    NSString *timeText = [self formatTimeString:position duration:duration];
    self.timeLabel.text = timeText;
    self.timeLabelLandscape.text = timeText;
}

- (void)sliderTouchUp:(UISlider *)slider {
    if ([self currentSceneType] == SceneTypeLive || [self currentSceneType] == SceneTypeRestricted) return;
    self.isDragging = NO;
    self.host.controller.controlsVisibilityLocked = NO;
    self.isSeeking = YES;
    NSInteger currentSeq = ++self.seekSequence;
    AliPlayerController *controller = self.host.controller;
    NSInteger duration = controller.duration;
    NSInteger position = (NSInteger)(slider.value * duration);
    [controller seekTo:position];
    [self resetAutoHide];

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakSelf.seekSequence == currentSeq) {
            weakSelf.isSeeking = NO;
        }
    });
}

- (void)sliderTapped:(UITapGestureRecognizer *)recognizer {
    if ([self currentSceneType] == SceneTypeLive || [self currentSceneType] == SceneTypeRestricted) return;
    UISlider *slider = (UISlider *)recognizer.view;
    CGPoint point = [recognizer locationInView:slider];
    CGFloat value = point.x / slider.bounds.size.width;
    value = MAX(0.0f, MIN(1.0f, value));

    [slider setValue:value animated:YES];

    self.isSeeking = YES;
    NSInteger currentSeq = ++self.seekSequence;
    AliPlayerController *controller = self.host.controller;
    NSInteger duration = controller.duration;
    NSInteger position = (NSInteger)(value * duration);
    [controller seekTo:position];

    NSString *timeText = [self formatTimeString:position duration:duration];
    self.timeLabel.text = timeText;
    self.timeLabelLandscape.text = timeText;

    [self resetAutoHide];

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakSelf.seekSequence == currentSeq) {
            weakSelf.isSeeking = NO;
        }
    });
}

#pragma mark - Layout Switching

- (void)updateLayoutForFullscreen:(BOOL)isFullscreen {
    self.isLandscapeLayout = isFullscreen;
    self.portraitContainer.hidden = isFullscreen;
    self.landscapeContainer.hidden = !isFullscreen;

    if (isFullscreen) {
        [self.progressSliderLandscape setThumbImage:[self thumbImageWithSize:kThumbSizeLandscape] forState:UIControlStateNormal];
        [self.progressSliderLandscape setThumbImage:[self thumbImageWithSize:kThumbSizeLandscape * kThumbHighlightScale] forState:UIControlStateHighlighted];
    }
}

#pragma mark - Portrait Layout

- (void)buildPortraitLayoutShowPlay:(BOOL)showPlay
                        showRefresh:(BOOL)showRefresh
                       showProgress:(BOOL)showProgress {
    self.portraitContainer = [[UIView alloc] init];
    self.portraitContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.portraitContainer.backgroundColor = [UIColor clearColor];
    [self addSubview:self.portraitContainer];

    [NSLayoutConstraint activateConstraints:@[
        [self.portraitContainer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.portraitContainer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.portraitContainer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    // 链式锚点：从左侧开始向右传递（因 BottomBar 不适合 StackView，需保留链式约束）
    NSLayoutAnchor *leftAnchor = self.portraitContainer.leadingAnchor;
    CGFloat leftOffset = kPaddingPortraitH;

    if (showPlay) {
        self.playPauseButton = [self createIconButton:[PlayerImage iconPlay]];
        [self.portraitContainer addSubview:self.playPauseButton];
        [NSLayoutConstraint activateConstraints:@[
            [self.playPauseButton.leadingAnchor constraintEqualToAnchor:self.portraitContainer.leadingAnchor constant:kPaddingPortraitH],
            [self.playPauseButton.centerYAnchor constraintEqualToAnchor:self.portraitContainer.centerYAnchor],
            [self.playPauseButton.widthAnchor constraintEqualToConstant:kIconSize],
            [self.playPauseButton.heightAnchor constraintEqualToConstant:kIconSize],
        ]];
        [self.playPauseButton addTarget:self action:@selector(playPauseButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        leftAnchor = self.playPauseButton.trailingAnchor;
        leftOffset = kItemMarginH;
    }

    if (showRefresh) {
        self.refreshButton = [self createIconButton:[PlayerImage iconReplay]];
        [self.portraitContainer addSubview:self.refreshButton];
        [NSLayoutConstraint activateConstraints:@[
            [self.refreshButton.leadingAnchor constraintEqualToAnchor:leftAnchor constant:leftOffset],
            [self.refreshButton.centerYAnchor constraintEqualToAnchor:self.portraitContainer.centerYAnchor],
            [self.refreshButton.widthAnchor constraintEqualToConstant:kIconSize],
            [self.refreshButton.heightAnchor constraintEqualToConstant:kIconSize],
        ]];
        [self.refreshButton addTarget:self action:@selector(refreshButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        leftAnchor = self.refreshButton.trailingAnchor;
        leftOffset = kItemMarginH;
    }

    NSLayoutAnchor *rightAnchor = self.portraitContainer.trailingAnchor;
    CGFloat rightOffset = -kPaddingPortraitH;

    if (showProgress) {
        self.timeLabel = [self createTimeLabel];
        [self.portraitContainer addSubview:self.timeLabel];
        [NSLayoutConstraint activateConstraints:@[
            [self.timeLabel.trailingAnchor constraintEqualToAnchor:rightAnchor constant:rightOffset],
            [self.timeLabel.centerYAnchor constraintEqualToAnchor:self.portraitContainer.centerYAnchor],
        ]];
        rightAnchor = self.timeLabel.leadingAnchor;
        rightOffset = -kItemMarginH;

        self.bufferProgressView = [self createBufferProgress];
        [self.portraitContainer addSubview:self.bufferProgressView];
        self.progressSlider = [self createSliderWithThumbSize:kThumbSizePortrait touchSize:kThumbTouchSize];
        [self.portraitContainer addSubview:self.progressSlider];

        [NSLayoutConstraint activateConstraints:@[
            [self.bufferProgressView.leadingAnchor constraintEqualToAnchor:leftAnchor constant:leftOffset],
            [self.bufferProgressView.trailingAnchor constraintEqualToAnchor:rightAnchor constant:rightOffset],
            [self.bufferProgressView.centerYAnchor constraintEqualToAnchor:self.portraitContainer.centerYAnchor],

            [self.progressSlider.leadingAnchor constraintEqualToAnchor:self.bufferProgressView.leadingAnchor],
            [self.progressSlider.trailingAnchor constraintEqualToAnchor:self.bufferProgressView.trailingAnchor],
            [self.progressSlider.centerYAnchor constraintEqualToAnchor:self.portraitContainer.centerYAnchor],
        ]];
    }

    CGFloat containerHeight = kPaddingPortraitV * 2 + kIconSize;
    [self.portraitContainer.heightAnchor constraintEqualToConstant:containerHeight].active = YES;
}

#pragma mark - Landscape Layout

- (void)buildLandscapeLayoutShowPlay:(BOOL)showPlay
                         showRefresh:(BOOL)showRefresh
                        showProgress:(BOOL)showProgress
                           showSpeed:(BOOL)showSpeed {
    // 注：横屏布局保留固有结构（时间标签、进度条、播放/刷新/倍速/清晰度），
    //    showPlay/showProgress 当前在横屏中始终保留以保持外部行为一致；
    //    showRefresh 决定刷新按钮是否创建。
    (void)showPlay;
    (void)showProgress;

    self.landscapeContainer = [[UIView alloc] init];
    self.landscapeContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.landscapeContainer.backgroundColor = [UIColor clearColor];
    [self addSubview:self.landscapeContainer];

    [NSLayoutConstraint activateConstraints:@[
        [self.landscapeContainer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.landscapeContainer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.landscapeContainer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    // Row 1: Time label (top)
    self.timeLabelLandscape = [self createTimeLabel];
    [self.landscapeContainer addSubview:self.timeLabelLandscape];

    // Row 2: SeekBar
    self.bufferProgressViewLandscape = [self createBufferProgress];
    [self.landscapeContainer addSubview:self.bufferProgressViewLandscape];
    self.progressSliderLandscape = [self createSliderWithThumbSize:kThumbSizeLandscape touchSize:kThumbSizeLandscape];
    [self.landscapeContainer addSubview:self.progressSliderLandscape];

    // Row 3: Play button + Refresh (left) + Speed/Quality (right)
    self.playPauseButtonLandscape = [self createIconButton:[PlayerImage iconPlay]];
    [self.landscapeContainer addSubview:self.playPauseButtonLandscape];
    [self.playPauseButtonLandscape addTarget:self action:@selector(playPauseButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    if (showRefresh) {
        self.refreshButtonLandscape = [self createIconButton:[PlayerImage iconReplay]];
        [self.landscapeContainer addSubview:self.refreshButtonLandscape];
        [self.refreshButtonLandscape addTarget:self action:@selector(refreshButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }

    if (showSpeed) {
        self.speedButton = [self createTextButton:LocalizedString(LocaleKeyBottomBarSpeed)];
        [self.landscapeContainer addSubview:self.speedButton];
        [self.speedButton addTarget:self action:@selector(speedButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }

    self.qualityButton = [self createTextButton:LocalizedString(LocaleKeyBottomBarQuality)];
    [self.landscapeContainer addSubview:self.qualityButton];
    [self.qualityButton addTarget:self action:@selector(qualityButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    [NSLayoutConstraint activateConstraints:@[
        // Time label
        [self.timeLabelLandscape.topAnchor constraintEqualToAnchor:self.landscapeContainer.topAnchor constant:kPaddingLandscapeTop],
        [self.timeLabelLandscape.leadingAnchor constraintEqualToAnchor:self.landscapeContainer.leadingAnchor constant:kPaddingLandscapeH + kItemMarginH],

        // SeekBar
        [self.bufferProgressViewLandscape.topAnchor constraintEqualToAnchor:self.timeLabelLandscape.bottomAnchor constant:kItemMarginV],
        [self.bufferProgressViewLandscape.leadingAnchor constraintEqualToAnchor:self.landscapeContainer.leadingAnchor constant:kPaddingLandscapeH],
        [self.bufferProgressViewLandscape.trailingAnchor constraintEqualToAnchor:self.landscapeContainer.trailingAnchor constant:-kPaddingLandscapeH],

        [self.progressSliderLandscape.leadingAnchor constraintEqualToAnchor:self.bufferProgressViewLandscape.leadingAnchor],
        [self.progressSliderLandscape.trailingAnchor constraintEqualToAnchor:self.bufferProgressViewLandscape.trailingAnchor],
        [self.progressSliderLandscape.centerYAnchor constraintEqualToAnchor:self.bufferProgressViewLandscape.centerYAnchor],

        // Bottom row
        [self.playPauseButtonLandscape.topAnchor constraintEqualToAnchor:self.bufferProgressViewLandscape.bottomAnchor constant:kItemMarginV],
        [self.playPauseButtonLandscape.leadingAnchor constraintEqualToAnchor:self.landscapeContainer.leadingAnchor constant:kPaddingLandscapeH],
        [self.playPauseButtonLandscape.widthAnchor constraintEqualToConstant:kIconSize],
        [self.playPauseButtonLandscape.heightAnchor constraintEqualToConstant:kIconSize],
        [self.playPauseButtonLandscape.bottomAnchor constraintEqualToAnchor:self.landscapeContainer.bottomAnchor constant:-kPaddingLandscapeBottom],

        // Quality (rightmost)
        [self.qualityButton.trailingAnchor constraintEqualToAnchor:self.landscapeContainer.trailingAnchor constant:-kPaddingLandscapeH],
        [self.qualityButton.centerYAnchor constraintEqualToAnchor:self.playPauseButtonLandscape.centerYAnchor],
    ]];

    if (showSpeed) {
        [NSLayoutConstraint activateConstraints:@[
            [self.speedButton.trailingAnchor constraintEqualToAnchor:self.qualityButton.leadingAnchor constant:-kBtnMarginH],
            [self.speedButton.centerYAnchor constraintEqualToAnchor:self.playPauseButtonLandscape.centerYAnchor],
        ]];
    }

    if (showRefresh) {
        [NSLayoutConstraint activateConstraints:@[
            [self.refreshButtonLandscape.leadingAnchor constraintEqualToAnchor:self.playPauseButtonLandscape.trailingAnchor constant:kItemMarginH],
            [self.refreshButtonLandscape.centerYAnchor constraintEqualToAnchor:self.playPauseButtonLandscape.centerYAnchor],
            [self.refreshButtonLandscape.widthAnchor constraintEqualToConstant:kIconSize],
            [self.refreshButtonLandscape.heightAnchor constraintEqualToConstant:kIconSize],
        ]];
    }
}

#pragma mark - Factory Methods

- (UIButton *)createIconButton:(UIImage *)icon {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:icon forState:UIControlStateNormal];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.tintColor = [UIColor whiteColor];
    button.contentEdgeInsets = UIEdgeInsetsMake(kIconPadding, kIconPadding, kIconPadding, kIconPadding);
    button.translatesAutoresizingMaskIntoConstraints = NO;
    return button;
}

- (UIButton *)createTextButton:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[PlayerColor textWhite] forState:UIControlStateNormal];
    button.titleLabel.font = [PlayerFont regular14];
    button.titleLabel.layer.shadowColor = [PlayerColor textShadow].CGColor;
    button.titleLabel.layer.shadowOffset = CGSizeZero;
    button.titleLabel.layer.shadowRadius = kTitleShadowRadius;
    button.titleLabel.layer.shadowOpacity = 1.0;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    return button;
}

- (UILabel *)createTimeLabel {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [PlayerFont monospacedDigit14];
    label.textColor = [PlayerColor textWhite];
    label.textAlignment = NSTextAlignmentLeft;
    label.text = LocalizedString(LocaleKeyBottomBarTimeZero);
    label.layer.shadowColor = [PlayerColor textShadow].CGColor;
    label.layer.shadowOffset = CGSizeZero;
    label.layer.shadowRadius = kTitleShadowRadius;
    label.layer.shadowOpacity = 1.0;
    return label;
}

- (UIProgressView *)createBufferProgress {
    UIProgressView *view = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.trackTintColor = [PlayerColor sliderBackground];
    view.progressTintColor = [PlayerColor sliderBuffer];
    view.progress = 0.0;
    view.layer.cornerRadius = kTrackHeight / 2.0;
    view.clipsToBounds = YES;
    [view.heightAnchor constraintEqualToConstant:kTrackHeight].active = YES;
    return view;
}

- (UISlider *)createSliderWithThumbSize:(CGFloat)thumbSize touchSize:(CGFloat)touchSize {
    UISlider *slider = [[UISlider alloc] init];
    slider.translatesAutoresizingMaskIntoConstraints = NO;
    slider.minimumValue = 0.0;
    slider.maximumValue = 1.0;
    slider.value = 0.0;
    slider.maximumTrackTintColor = [UIColor clearColor];

    UIImage *minTrackImage = [self trackImageWithColor:[PlayerColor sliderTrack]];
    [slider setMinimumTrackImage:minTrackImage forState:UIControlStateNormal];
    UIImage *maxTrackImage = [self trackImageWithColor:[UIColor clearColor]];
    [slider setMaximumTrackImage:maxTrackImage forState:UIControlStateNormal];

    UIImage *thumbNormal = [self thumbImageWithSize:thumbSize touchSize:touchSize];
    UIImage *thumbHighlighted = [self thumbImageWithSize:thumbSize * kThumbHighlightScale touchSize:touchSize * kThumbHighlightScale];
    [slider setThumbImage:thumbNormal forState:UIControlStateNormal];
    [slider setThumbImage:thumbHighlighted forState:UIControlStateHighlighted];

    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [slider addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [slider addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [slider addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
    [slider addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchCancel];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapped:)];
    tapGesture.cancelsTouchesInView = NO;
    [slider addGestureRecognizer:tapGesture];

    return slider;
}

#pragma mark - Private Methods

- (void)resetProgressUI {
    self.progressSlider.value = 0;
    self.bufferProgressView.progress = 0;
    self.progressSliderLandscape.value = 0;
    self.bufferProgressViewLandscape.progress = 0;
    NSString *zero = LocalizedString(LocaleKeyBottomBarTimeZero);
    self.timeLabel.text = zero;
    self.timeLabelLandscape.text = zero;
}

- (void)updatePlayPauseState {
    AliPlayerController *controller = self.host.controller;
    BOOL isPlaying = (controller.playerState == PlayerStatePlaying);
    UIImage *icon = isPlaying ? [PlayerImage iconPause] : [PlayerImage iconPlay];
    [self.playPauseButton setImage:icon forState:UIControlStateNormal];
    [self.playPauseButtonLandscape setImage:icon forState:UIControlStateNormal];
}

- (NSString *)formatTimeString:(NSInteger)currentMs duration:(NSInteger)durationMs {
    NSInteger currentSeconds = currentMs / (NSInteger)kMillisecondsPerSecond;
    NSInteger durationSeconds = durationMs / (NSInteger)kMillisecondsPerSecond;
    NSString *fmt = self.cachedTimeFormat ?: LocalizedString(LocaleKeyBottomBarTimeFormat);
    return [NSString stringWithFormat:fmt,
            (long)(currentSeconds / kSecondsPerMinute), (long)(currentSeconds % kSecondsPerMinute),
            (long)(durationSeconds / kSecondsPerMinute), (long)(durationSeconds % kSecondsPerMinute)];
}

- (UIImage *)thumbImageWithSize:(CGFloat)size {
    return [self thumbImageWithSize:size touchSize:size];
}

- (UIImage *)thumbImageWithSize:(CGFloat)size touchSize:(CGFloat)touchSize {
    CGFloat canvasSize = MAX(size, touchSize);
    CGRect canvas = CGRectMake(0, 0, canvasSize, canvasSize);
    UIGraphicsBeginImageContextWithOptions(canvas.size, NO, 0);
    CGFloat offset = (canvasSize - size) / 2.0;
    CGRect ovalRect = CGRectMake(offset, offset, size, size);
    [[UIColor whiteColor] setFill];
    [[UIBezierPath bezierPathWithOvalInRect:ovalRect] fill];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)trackImageWithColor:(UIColor *)color {
    CGFloat radius = kTrackHeight / 2.0;
    CGRect rect = CGRectMake(0, 0, kTrackHeight + 2, kTrackHeight);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius] fill];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(0, radius + 1, 0, radius + 1)
                                 resizingMode:UIImageResizingModeStretch];
}

#pragma mark - Notification Handlers

- (void)onLocaleDidChange:(NSNotification *)notification {
    self.cachedTimeFormat = LocalizedString(LocaleKeyBottomBarTimeFormat);
    [self.speedButton setTitle:LocalizedString(LocaleKeyBottomBarSpeed) forState:UIControlStateNormal];
    [self.qualityButton setTitle:LocalizedString(LocaleKeyBottomBarQuality) forState:UIControlStateNormal];
}

@end
