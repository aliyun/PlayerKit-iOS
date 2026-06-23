//
//  LandscapeHintSlot.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "LandscapeHintSlot.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "PlayerNotificationDelegate.h"
#import "PlayerStateStore.h"
#import "PlayerViewState.h"
#import "ScaleMode.h"
#import "RotateMode.h"
#import "PlayerImage.h"
#import "PlayerColor.h"
#import "PlayerFont.h"
#import "LocaleMacros.h"
#import "LocaleKeys.h"
#import "Log.h"

static const CGFloat kPillWidth = 94.0;
static const CGFloat kPillHeight = 32.0;
static const CGFloat kPillCornerRadius = 18.0;
static const CGFloat kPillBorderWidth = 1.0;
static const CGFloat kPillBottomMargin = 12.0;
static const CGFloat kIconSize = 18.0;
static const CGFloat kIconTextSpacing = 4.0;

@interface LandscapeHintSlot () <PlayerNotificationDelegate>

@property (nonatomic, strong) UIView *pillView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) NSLayoutConstraint *pillTopConstraint;
@property (nonatomic, assign) BOOL isVideoLandscape;

@end

@implementation LandscapeHintSlot

#pragma mark - Slot Lifecycle

- (void)onAttach:(id<SlotHost>)host {
    [super onAttach:host];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLocaleDidChange:)
                                                 name:LocaleDidChangeNotification
                                               object:nil];
}

- (void)onDetach {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:LocaleDidChangeNotification
                                                  object:nil];
    [super onDetach];
}

- (void)setupContentView {
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = YES;

    [self createPillView];
    self.pillView.hidden = YES;
}

- (void)onBindData:(AliPlayerModel *)model {
    [super onBindData:model];
    self.isVideoLandscape = NO;
    self.pillView.hidden = YES;
}

- (void)onUnbindData {
    self.isVideoLandscape = NO;
    self.pillView.hidden = YES;
    [super onUnbindData];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidRenderFirstFrame {
    [self evaluateVideoOrientation];
}

- (void)playerDidChangeVideoWidth:(NSInteger)width
                           height:(NSInteger)height {
    [self evaluateVideoOrientation];
}

- (void)playerDidChangeFullscreen:(BOOL)isFullscreen {
    if (isFullscreen) {
        self.pillView.hidden = YES;
    } else {
        [self evaluateVideoOrientation];
    }
}

- (void)playerDidChangeScaleMode:(ScaleMode)scaleMode {
    [self evaluateVideoOrientation];
}

- (void)playerDidChangeRotateMode:(RotateMode)rotateMode {
    [self evaluateVideoOrientation];
}

#pragma mark - Actions

- (void)pillTapped {
    AliPlayerController *controller = self.host.controller;
    [controller setFullscreen:YES animated:YES];
    self.pillView.hidden = YES;
    SLOGI(@"Landscape hint tapped, entering fullscreen");
}

#pragma mark - Private Methods

- (void)createPillView {
    self.pillView = [[UIView alloc] init];
    self.pillView.backgroundColor = [PlayerColor landscapeHintBackground];
    self.pillView.layer.cornerRadius = kPillCornerRadius;
    self.pillView.layer.borderWidth = kPillBorderWidth;
    self.pillView.layer.borderColor = [PlayerColor landscapeHintBorder].CGColor;
    self.pillView.clipsToBounds = YES;
    self.pillView.translatesAutoresizingMaskIntoConstraints = NO;
    self.pillView.userInteractionEnabled = YES;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pillTapped)];
    [self.pillView addGestureRecognizer:tap];
    [self addSubview:self.pillView];

    self.iconView = [[UIImageView alloc] init];
    self.iconView.image = [PlayerImage iconFullscreenHint];
    self.iconView.tintColor = [UIColor whiteColor];
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.pillView addSubview:self.iconView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LocalizedString(LocaleKeyLandscapeHintFullscreen);
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [PlayerFont regular12];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.pillView addSubview:self.titleLabel];

    self.pillTopConstraint = [self.pillView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0];

    [NSLayoutConstraint activateConstraints:@[
        [self.pillView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        self.pillTopConstraint,
        [self.pillView.widthAnchor constraintEqualToConstant:kPillWidth],
        [self.pillView.heightAnchor constraintEqualToConstant:kPillHeight],

        [self.iconView.leadingAnchor constraintEqualToAnchor:self.pillView.leadingAnchor constant:12],
        [self.iconView.centerYAnchor constraintEqualToAnchor:self.pillView.centerYAnchor],
        [self.iconView.widthAnchor constraintEqualToConstant:kIconSize],
        [self.iconView.heightAnchor constraintEqualToConstant:kIconSize],

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:kIconTextSpacing],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.pillView.centerYAnchor],
    ]];
}

- (void)evaluateVideoOrientation {
    if (self.host.viewState.isFullscreen) {
        self.pillView.hidden = YES;
        return;
    }

    PlayerStateStore *store = self.host.playerStateStore;
    if (store.scaleMode != ScaleModeFitCenter) {
        self.pillView.hidden = YES;
        return;
    }

    UIView *hostView = [self.host hostView];
    if (hostView) {
        CGFloat hostWidth = CGRectGetWidth(hostView.bounds);
        CGFloat hostHeight = CGRectGetHeight(hostView.bounds);
        if (hostWidth >= hostHeight) {
            self.pillView.hidden = YES;
            return;
        }
    }

    NSInteger videoWidth = store.videoWidth;
    NSInteger videoHeight = store.videoHeight;
    if (videoWidth <= 0 || videoHeight <= 0) {
        self.pillView.hidden = YES;
        return;
    }

    RotateMode rotation = store.rotateMode;
    if (rotation == RotateModeDegree90 || rotation == RotateModeDegree270) {
        NSInteger temp = videoWidth;
        videoWidth = videoHeight;
        videoHeight = temp;
    }

    BOOL wasLandscape = self.isVideoLandscape;
    self.isVideoLandscape = (videoWidth > videoHeight);
    if (self.isVideoLandscape) {
        [self updatePillPosition];
    }
    self.pillView.hidden = !self.isVideoLandscape;
    if (self.isVideoLandscape && !wasLandscape) {
        SLOGI(@"Video is landscape (%ldx%ld) in portrait container, showing hint",
              (long)videoWidth, (long)videoHeight);
    }
}

- (void)updatePillPosition {
    PlayerStateStore *store = self.host.playerStateStore;
    NSInteger videoWidth = store.videoWidth;
    NSInteger videoHeight = store.videoHeight;
    if (videoWidth <= 0 || videoHeight <= 0) return;

    RotateMode rotation = store.rotateMode;
    if (rotation == RotateModeDegree90 || rotation == RotateModeDegree270) {
        NSInteger temp = videoWidth;
        videoWidth = videoHeight;
        videoHeight = temp;
    }

    CGFloat containerW = self.bounds.size.width;
    CGFloat containerH = self.bounds.size.height;
    if (containerW <= 0 || containerH <= 0) return;

    CGFloat videoAspect = (CGFloat)videoWidth / (CGFloat)videoHeight;
    CGFloat displayHeight = containerW / videoAspect;
    CGFloat videoTop = (containerH - displayHeight) / 2.0;
    CGFloat videoBottomY = videoTop + displayHeight;

    CGFloat pillTopY = videoBottomY + kPillBottomMargin;
    CGFloat maxPillTopY = containerH - kPillHeight - kPillBottomMargin;
    if (pillTopY > maxPillTopY) {
        pillTopY = maxPillTopY;
    }

    if (fabs(self.pillTopConstraint.constant - pillTopY) > 0.5) {
        self.pillTopConstraint.constant = pillTopY;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.host) {
        [self updatePillPosition];
    }
}

#pragma mark - Locale

- (void)onLocaleDidChange:(NSNotification *)notification {
    self.titleLabel.text = LocalizedString(LocaleKeyLandscapeHintFullscreen);
}

#pragma mark - Hit Testing

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.pillView.hidden) {
        return nil;
    }
    CGPoint pillPoint = [self.pillView convertPoint:point fromView:self];
    if ([self.pillView pointInside:pillPoint withEvent:event]) {
        return self.pillView;
    }
    return nil;
}

@end
