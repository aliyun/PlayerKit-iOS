//
//  CenterDisplaySlot.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "CenterDisplaySlot.h"
#import "GestureNotificationDelegate.h"
#import "GestureNotificationDispatcher.h"
#import "SlotElements.h"
#import "PlayerImage.h"
#import "PlayerColor.h"
#import "PlayerFont.h"
#import "Log.h"
#import "LocaleMacros.h"
#import "LocaleKeys.h"

static const CGFloat kContainerWidth = 180.0;
static const CGFloat kContainerHeight = 45.0;
static const CGFloat kContainerCornerRadius = 8.0;
static const CGFloat kContainerPadding = 10.0;
static const CGFloat kContainerTopMargin = 110.0;
static const CGFloat kIconSize = 24.0;
static const CGFloat kProgressBarHeight = 4.0;
static const CGFloat kPercentLabelWidth = 38.0;
static const CGFloat kSpeedIconRightMargin = 6.0;

@interface CenterDisplaySlot () <GestureNotificationDelegate>

@property (nonatomic, strong) UIView *speedContainer;
@property (nonatomic, strong) UIImageView *speedIcon;
@property (nonatomic, strong) UILabel *speedLabel;

@property (nonatomic, strong) UIView *brightnessContainer;
@property (nonatomic, strong) UIImageView *brightnessIcon;
@property (nonatomic, strong) UIProgressView *brightnessProgressView;
@property (nonatomic, strong) UILabel *brightnessPercentLabel;

@property (nonatomic, strong) UIView *volumeContainer;
@property (nonatomic, strong) UIImageView *volumeIcon;
@property (nonatomic, strong) UIProgressView *volumeProgressView;
@property (nonatomic, strong) UILabel *volumePercentLabel;

@end

@implementation CenterDisplaySlot

#pragma mark - Slot Lifecycle

- (void)onAttach:(id<SlotHost>)host {
    [super onAttach:host];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLocaleDidChange:)
                                                 name:LocaleDidChangeNotification
                                               object:nil];
}

- (NSUInteger)onRegisterElements {
    return CenterDisplayElementVolume | CenterDisplayElementBrightness | CenterDisplayElementSpeed;
}

- (void)setupContentView {
    if ([self isElementVisible:CenterDisplayElementSpeed]) {
        [self setupSpeedView];
    }
    if ([self isElementVisible:CenterDisplayElementBrightness]) {
        [self setupBrightnessView];
    }
    if ([self isElementVisible:CenterDisplayElementVolume]) {
        [self setupVolumeView];
    }
}

- (void)onUnbindData {
    [self hideAllDisplays];
    [super onUnbindData];
}

- (void)onDetach {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:LocaleDidChangeNotification
                                                  object:nil];
    if (self.gestureDispatcher) {
        [self.gestureDispatcher removeObserver:self];
        self.gestureDispatcher = nil;
    }
    [self hideAllDisplays];
    [super onDetach];
}

#pragma mark - GestureNotificationDelegate

- (void)gestureDidBeginLongPress {
    [self hideAllDisplays];
    self.speedContainer.hidden = NO;
    SLOGI(@"Showing speed display");
}

- (void)gestureDidEndLongPress {
    self.speedContainer.hidden = YES;
    SLOGI(@"Hiding speed display");
}

- (void)gestureDidUpdateBrightnessWithPercent:(CGFloat)currentPercent {
    [self hideAllDisplays];
    self.brightnessContainer.hidden = NO;
    self.brightnessProgressView.progress = (float)currentPercent;
    self.brightnessPercentLabel.text = [NSString stringWithFormat:@"%d%%", (int)(currentPercent * 100)];
}

- (void)gestureDidEndBrightnessAdjust {
    self.brightnessContainer.hidden = YES;
    SLOGI(@"Hiding brightness display");
}

- (void)gestureDidUpdateVolumeWithPercent:(CGFloat)currentPercent {
    [self hideAllDisplays];
    self.volumeContainer.hidden = NO;
    self.volumeProgressView.progress = (float)currentPercent;
    self.volumePercentLabel.text = [NSString stringWithFormat:@"%d%%", (int)(currentPercent * 100)];
}

- (void)gestureDidEndVolumeAdjust {
    self.volumeContainer.hidden = YES;
    SLOGI(@"Hiding volume display");
}

#pragma mark - Private Methods

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

- (void)hideAllDisplays {
    self.speedContainer.hidden = YES;
    self.brightnessContainer.hidden = YES;
    self.volumeContainer.hidden = YES;
}

#pragma mark - Speed View Setup

- (void)setupSpeedView {
    self.speedContainer = [[UIView alloc] init];
    self.speedContainer.backgroundColor = [PlayerColor panelBackground];
    self.speedContainer.layer.cornerRadius = kContainerCornerRadius;
    self.speedContainer.clipsToBounds = YES;
    self.speedContainer.hidden = YES;
    self.speedContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.speedContainer];

    self.speedIcon = [[UIImageView alloc] init];
    self.speedIcon.image = [PlayerImage iconSpeed];
    self.speedIcon.tintColor = [UIColor whiteColor];
    self.speedIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.speedIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [self.speedContainer addSubview:self.speedIcon];

    self.speedLabel = [[UILabel alloc] init];
    self.speedLabel.text = LocalizedString(LocaleKeySpeedPlayingHint);
    self.speedLabel.textColor = [PlayerColor textWhite];
    self.speedLabel.font = [PlayerFont bold14];
    self.speedLabel.textAlignment = NSTextAlignmentCenter;
    self.speedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.speedContainer addSubview:self.speedLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.speedContainer.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.speedContainer.topAnchor constraintEqualToAnchor:self.topAnchor constant:kContainerTopMargin],
        [self.speedContainer.heightAnchor constraintEqualToConstant:kContainerHeight],

        [self.speedIcon.leadingAnchor constraintEqualToAnchor:self.speedContainer.leadingAnchor constant:kContainerPadding],
        [self.speedIcon.centerYAnchor constraintEqualToAnchor:self.speedContainer.centerYAnchor],
        [self.speedIcon.widthAnchor constraintEqualToConstant:kIconSize],
        [self.speedIcon.heightAnchor constraintEqualToConstant:kIconSize],

        [self.speedLabel.leadingAnchor constraintEqualToAnchor:self.speedIcon.trailingAnchor constant:kSpeedIconRightMargin],
        [self.speedLabel.trailingAnchor constraintEqualToAnchor:self.speedContainer.trailingAnchor constant:-kContainerPadding],
        [self.speedLabel.centerYAnchor constraintEqualToAnchor:self.speedContainer.centerYAnchor],
    ]];
}

#pragma mark - Brightness View Setup

- (void)setupBrightnessView {
    self.brightnessContainer = [self createProgressContainerWithIcon:[PlayerImage iconBrightness]
                                                        progressView:&_brightnessProgressView
                                                        percentLabel:&_brightnessPercentLabel
                                                            iconView:&_brightnessIcon];
    [self addSubview:self.brightnessContainer];

    [NSLayoutConstraint activateConstraints:@[
        [self.brightnessContainer.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.brightnessContainer.topAnchor constraintEqualToAnchor:self.topAnchor constant:kContainerTopMargin],
        [self.brightnessContainer.widthAnchor constraintEqualToConstant:kContainerWidth],
        [self.brightnessContainer.heightAnchor constraintEqualToConstant:kContainerHeight],
    ]];
}

#pragma mark - Volume View Setup

- (void)setupVolumeView {
    self.volumeContainer = [self createProgressContainerWithIcon:[PlayerImage iconVolume]
                                                    progressView:&_volumeProgressView
                                                    percentLabel:&_volumePercentLabel
                                                        iconView:&_volumeIcon];
    [self addSubview:self.volumeContainer];

    [NSLayoutConstraint activateConstraints:@[
        [self.volumeContainer.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.volumeContainer.topAnchor constraintEqualToAnchor:self.topAnchor constant:kContainerTopMargin],
        [self.volumeContainer.widthAnchor constraintEqualToConstant:kContainerWidth],
        [self.volumeContainer.heightAnchor constraintEqualToConstant:kContainerHeight],
    ]];
}

#pragma mark - Factory Methods

- (UIView *)createProgressContainerWithIcon:(UIImage *)iconImage
                               progressView:(UIProgressView * __strong *)outProgressView
                               percentLabel:(UILabel * __strong *)outPercentLabel
                                   iconView:(UIImageView * __strong *)outIcon {
    UIView *container = [[UIView alloc] init];
    container.backgroundColor = [PlayerColor panelBackground];
    container.layer.cornerRadius = kContainerCornerRadius;
    container.clipsToBounds = YES;
    container.hidden = YES;
    container.translatesAutoresizingMaskIntoConstraints = NO;

    UIImageView *icon = [[UIImageView alloc] init];
    icon.image = iconImage;
    icon.tintColor = [UIColor whiteColor];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:icon];

    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    progressView.trackTintColor = [PlayerColor sliderBackground];
    progressView.progressTintColor = [PlayerColor sliderTrack];
    progressView.progress = 0.0;
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:progressView];

    UILabel *percentLabel = [[UILabel alloc] init];
    percentLabel.text = @"0%";
    percentLabel.textColor = [PlayerColor textWhite];
    percentLabel.font = [PlayerFont regular14];
    percentLabel.textAlignment = NSTextAlignmentRight;
    percentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:percentLabel];

    [NSLayoutConstraint activateConstraints:@[
        [icon.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:kContainerPadding],
        [icon.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:kIconSize],
        [icon.heightAnchor constraintEqualToConstant:kIconSize],

        [progressView.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:kContainerPadding],
        [progressView.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],
        [progressView.heightAnchor constraintEqualToConstant:kProgressBarHeight],

        [percentLabel.leadingAnchor constraintEqualToAnchor:progressView.trailingAnchor constant:6],
        [percentLabel.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-kContainerPadding],
        [percentLabel.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],
        [percentLabel.widthAnchor constraintEqualToConstant:kPercentLabelWidth],
    ]];

    *outIcon = icon;
    *outProgressView = progressView;
    *outPercentLabel = percentLabel;

    return container;
}

#pragma mark - Notification Handlers

- (void)onLocaleDidChange:(NSNotification *)notification {
    self.speedLabel.text = LocalizedString(LocaleKeySpeedPlayingHint);
}

@end
