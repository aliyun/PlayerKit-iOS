//
//  PlayStateSlot.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "PlayStateSlot.h"
#import "AliPlayerController.h"
#import "PlayerNotificationDelegate.h"
#import "PlayerStateStore.h"
#import "SlotElements.h"
#import "PlayerImage.h"
#import "PlayerColor.h"
#import "PlayerFont.h"
#import "TrackQuality.h"
#import "TrackUtil.h"
#import "Log.h"
#import "LocaleMacros.h"
#import "LocaleKeys.h"
#import "FileUtils.h"
#import <Photos/Photos.h>

static const CGFloat kContainerPadding = 16.0;
static const CGFloat kContainerCornerRadius = 8.0;
static const CGFloat kIconSize = 30.0;
static const CGFloat kIconBottomMargin = 16.0;
static const CGFloat kTextMinWidth = 98.0;
static const CGFloat kTextMinHeight = 24.0;
static const CGFloat kContainerMaxWidthRatio = 0.6;
static const CGFloat kLineSpacing = 6.0;
static const CGFloat kFadeAnimationDuration = 0.2;
static const NSTimeInterval kToastDuration = 2.5;
static const CFTimeInterval kLoadingRotationDuration = 1.0;
static NSString *const kLoadingRotationKey = @"loadingRotation";
static NSString *const kSnapshotSubDirectory = @"AliPlayerKit/Snapshot";
static NSString *const kSnapshotFileNameFormat = @"snapshot_%lld.png";

typedef NS_ENUM(NSInteger, DisplayType) {
    DisplayTypeNone,
    DisplayTypeError,
    DisplayTypeLoading,
    DisplayTypeToast,
};

@interface PlayStateSlot () <PlayerNotificationDelegate>

@property (nonatomic, strong) UIView *messageContainer;
@property (nonatomic, strong) UIImageView *stateIcon;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, assign) DisplayType displayType;
@property (nonatomic, strong) NSError *lastError;
@property (nonatomic, assign) NSInteger toastSequence;

@end

@implementation PlayStateSlot

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

- (NSUInteger)onRegisterElements {
    return PlayStateElementErrorMessage | PlayStateElementLoadingMessage;
}

- (void)setupContentView {
    BOOL hideError = ![self isElementVisible:PlayStateElementErrorMessage];
    BOOL hideLoading = ![self isElementVisible:PlayStateElementLoadingMessage];

    if (hideError && hideLoading) {
        [self hide];
        return;
    }

    self.backgroundColor = [UIColor clearColor];

    self.messageContainer = [[UIView alloc] init];
    self.messageContainer.backgroundColor = [PlayerColor playStateBackground];
    self.messageContainer.layer.cornerRadius = kContainerCornerRadius;
    self.messageContainer.clipsToBounds = YES;
    self.messageContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageContainer.alpha = 0;
    [self addSubview:self.messageContainer];

    self.stateIcon = [[UIImageView alloc] init];
    self.stateIcon.image = [PlayerImage iconError];
    self.stateIcon.tintColor = [UIColor whiteColor];
    self.stateIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.stateIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [self.messageContainer addSubview:self.stateIcon];

    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.textColor = [PlayerColor textWhite];
    self.messageLabel.font = [PlayerFont regular14];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.numberOfLines = 3;
    self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.messageContainer addSubview:self.messageLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.messageContainer.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.messageContainer.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.messageContainer.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor multiplier:kContainerMaxWidthRatio],

        [self.stateIcon.topAnchor constraintEqualToAnchor:self.messageContainer.topAnchor constant:kContainerPadding],
        [self.stateIcon.centerXAnchor constraintEqualToAnchor:self.messageContainer.centerXAnchor],
        [self.stateIcon.widthAnchor constraintEqualToConstant:kIconSize],
        [self.stateIcon.heightAnchor constraintEqualToConstant:kIconSize],

        [self.messageLabel.topAnchor constraintEqualToAnchor:self.stateIcon.bottomAnchor constant:kIconBottomMargin],
        [self.messageLabel.bottomAnchor constraintEqualToAnchor:self.messageContainer.bottomAnchor constant:-kContainerPadding],
        [self.messageLabel.leadingAnchor constraintEqualToAnchor:self.messageContainer.leadingAnchor constant:kContainerPadding],
        [self.messageLabel.trailingAnchor constraintEqualToAnchor:self.messageContainer.trailingAnchor constant:-kContainerPadding],
        [self.messageLabel.widthAnchor constraintGreaterThanOrEqualToConstant:kTextMinWidth],
        [self.messageLabel.heightAnchor constraintGreaterThanOrEqualToConstant:kTextMinHeight],
    ]];

    [self hide];
}

- (void)onBindData:(AliPlayerModel *)model {
    [super onBindData:model];

    PlayerStateStore *stateStore = self.host.playerStateStore;
    if (stateStore && stateStore.playState == PlayerStateError) {
        NSString *codeLabel = LocalizedString(LocaleKeyPlayStateErrorCodeLabel);
        NSString *msgLabel = LocalizedString(LocaleKeyPlayStateErrorMessageLabel);
        NSString *defaultMsg = LocalizedString(LocaleKeyPlayStateErrorMessageDefault);
        [self showDisplayType:DisplayTypeError
                         icon:[PlayerImage iconError]
                      message:LocalizedFormat(LocaleKeyPlayStateErrorDetailsFormat, codeLabel, 0L, msgLabel, defaultMsg)];
        SLOGI(@"Already in error state on bind, showing generic error");
    } else {
        [self dismissDisplay];
    }
}

- (void)onUnbindData {
    [self dismissDisplay];
    self.lastError = nil;
    [super onUnbindData];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidEncounterError:(NSError *)error {
    self.lastError = error;
    NSString *message = [self buildErrorMessageWithError:error];
    [self showDisplayType:DisplayTypeError
                     icon:[PlayerImage iconError]
                  message:message];
    SLOGI(@"Showing error: %@", error.localizedDescription);
}

- (void)playerDidChangeState:(PlayerState)state {
    if (state != PlayerStateError && self.displayType == DisplayTypeError) {
        [self dismissDisplay];
    }
}

- (void)playerDidLoadingBegin {
    if (self.displayType == DisplayTypeError) return;
    NSString *message = LocalizedString(LocaleKeyPlayStateLoading);
    [self showDisplayType:DisplayTypeLoading
                     icon:[PlayerImage iconLoading]
                  message:message];
    SLOGI(@"Showing loading");
}

- (void)playerDidLoadingEnd {
    if (self.displayType != DisplayTypeLoading) return;
    [self dismissDisplay];
    SLOGI(@"Hiding loading");
}

- (void)playerDidCompleteSnapshot:(UIImage *)image {
    if (!image) return;

    NSString *directory = [FileUtils combinePaths:@[[FileUtils documentsDirectory], kSnapshotSubDirectory]];
    int64_t timestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    NSString *fileName = [NSString stringWithFormat:kSnapshotFileNameFormat, timestamp];

    NSError *error = nil;
    BOOL success = [FileUtils saveImage:image toDirectory:directory fileName:fileName error:&error];

    if (success) {
        SLOGI(@"Snapshot saved to %@/%@", directory, fileName);
        NSString *message = LocalizedString(LocaleKeyPlayStateSnapshotCompleted);
        [self showToastWithIcon:[PlayerImage iconSuccess] message:message];

        // 检查是否配置了相册写入权限描述，未配置则跳过（避免崩溃）
        NSString *photoLibraryUsageDesc = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSPhotoLibraryAddUsageDescription"];
        if (!photoLibraryUsageDesc || photoLibraryUsageDesc.length == 0) {
            SLOGW(@"NSPhotoLibraryAddUsageDescription not configured, skipping photo album save");
            return;
        }

        // 检查相册授权状态，已拒绝或受限则跳过
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
            SLOGW(@"Photo library access denied or restricted, skipping photo album save");
            return;
        }

        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    } else {
        SLOGE(@"Snapshot save failed: %@", error.localizedDescription);
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        SLOGE(@"Snapshot save to photo album failed: %@", error.localizedDescription);
    } else {
        SLOGI(@"Snapshot saved to photo album");
    }
}

- (void)playerDidTrackChanged:(TrackQuality *)quality {
    NSString *resolution = [TrackUtil findNearestResolution:quality];
    NSString *message = LocalizedFormat(LocaleKeyPlayStateTrackSwitchCompleted, resolution);
    [self showToastWithIcon:[PlayerImage iconSuccess] message:message];
}

#pragma mark - Display State Machine

- (void)showDisplayType:(DisplayType)type icon:(UIImage *)icon message:(NSString *)message {
    self.displayType = type;
    self.stateIcon.image = icon;
    self.messageLabel.attributedText = [self attributedTextForString:message];

    if (type == DisplayTypeLoading) {
        [self startLoadingAnimation];
    } else {
        [self stopLoadingAnimation];
    }

    [self show];
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:kFadeAnimationDuration animations:^{
        weakSelf.messageContainer.alpha = 1.0;
    }];
}

- (void)showToastWithIcon:(UIImage *)icon message:(NSString *)message {
    if (self.displayType == DisplayTypeError || self.displayType == DisplayTypeLoading) return;
    [self showDisplayType:DisplayTypeToast icon:icon message:message];

    NSInteger seq = ++self.toastSequence;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kToastDuration * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (strongSelf.toastSequence == seq && strongSelf.displayType == DisplayTypeToast) {
            [strongSelf dismissDisplay];
        }
    });
}

- (void)dismissDisplay {
    DisplayType previousType = self.displayType;
    self.displayType = DisplayTypeNone;
    self.lastError = nil;
    [self stopLoadingAnimation];

    if (previousType == DisplayTypeNone) return;

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:kFadeAnimationDuration animations:^{
        weakSelf.messageContainer.alpha = 0;
    } completion:^(BOOL finished) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (strongSelf.displayType == DisplayTypeNone) {
            strongSelf.messageLabel.text = nil;
            [strongSelf hide];
        }
    }];
}

#pragma mark - Loading Animation

- (void)startLoadingAnimation {
    [self stopLoadingAnimation];
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.fromValue = @0;
    rotation.toValue = @(2 * M_PI);
    rotation.duration = kLoadingRotationDuration;
    rotation.repeatCount = HUGE_VALF;
    rotation.removedOnCompletion = NO;
    [self.stateIcon.layer addAnimation:rotation forKey:kLoadingRotationKey];
}

- (void)stopLoadingAnimation {
    [self.stateIcon.layer removeAnimationForKey:kLoadingRotationKey];
}

#pragma mark - Private Methods

- (NSAttributedString *)attributedTextForString:(NSString *)text {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = kLineSpacing;
    style.alignment = NSTextAlignmentCenter;
    return [[NSAttributedString alloc] initWithString:text
                                           attributes:@{
        NSFontAttributeName: [PlayerFont regular14],
        NSForegroundColorAttributeName: [PlayerColor textWhite],
        NSParagraphStyleAttributeName: style,
    }];
}

- (NSString *)buildErrorMessageWithError:(NSError *)error {
    NSString *codeLabel = LocalizedString(LocaleKeyPlayStateErrorCodeLabel);
    NSString *msgLabel = LocalizedString(LocaleKeyPlayStateErrorMessageLabel);
    NSString *actualMsg = error.localizedDescription.length > 0
        ? error.localizedDescription
        : LocalizedString(LocaleKeyPlayStateErrorMessageDefault);
    return LocalizedFormat(LocaleKeyPlayStateErrorDetailsFormat, codeLabel, (long)error.code, msgLabel, actualMsg);
}

#pragma mark - Notification Handlers

- (void)onLocaleDidChange:(NSNotification *)notification {
    switch (self.displayType) {
        case DisplayTypeError: {
            if (self.lastError) {
                self.messageLabel.attributedText = [self attributedTextForString:[self buildErrorMessageWithError:self.lastError]];
            } else {
                NSString *codeLabel = LocalizedString(LocaleKeyPlayStateErrorCodeLabel);
                NSString *msgLabel = LocalizedString(LocaleKeyPlayStateErrorMessageLabel);
                NSString *defaultMsg = LocalizedString(LocaleKeyPlayStateErrorMessageDefault);
                self.messageLabel.attributedText = [self attributedTextForString:
                    LocalizedFormat(LocaleKeyPlayStateErrorDetailsFormat, codeLabel, 0L, msgLabel, defaultMsg)];
            }
            break;
        }
        case DisplayTypeLoading:
            self.messageLabel.attributedText = [self attributedTextForString:LocalizedString(LocaleKeyPlayStateLoading)];
            break;
        default:
            break;
    }
}

#pragma mark - Hit Testing

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.displayType == DisplayTypeError) {
        return [super hitTest:point withEvent:event];
    }
    return nil;
}

@end
