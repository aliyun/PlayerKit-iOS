//
//  SeekThumbnailSlot.m
//  AliPlayerKit
//
//  Created by keria on 2026/07/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "SeekThumbnailSlot.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "PlayerNotificationDelegate.h"
#import "SlotActionNotificationDelegate.h"
#import "ChapterInfo.h"
#import "FormatUtil.h"
#import "Log.h"

#pragma mark - Constants

static const CGFloat kContainerBottomMargin = 80.0;
static const CGFloat kThumbnailMaxSize = 200.0;
static const CGFloat kThumbnailPlaceholderSize = 112.0;
static const CGFloat kThumbnailCornerRadius = 4.0;
static const CGFloat kThumbnailBackgroundAlpha = 0.5;
static const CGFloat kTimeLabelTopMargin = 8.0;
static const CGFloat kTimeLabelFontSize = 16.0;
static const CGFloat kChapterTitleFontSize = 13.0;
static const CGFloat kChapterTitleTopMargin = 4.0;
static NSString *const kTimeTextFormat = @"%@ / %@";

@interface SeekThumbnailSlot () <PlayerNotificationDelegate, SlotActionNotificationDelegate>

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *chapterTitleLabel;

// 双源初始化标志位：外部 URL 优先于媒体信息自动提取，多道检查防重复初始化
@property (nonatomic, assign) BOOL externalUrlUsed;
@property (nonatomic, assign) BOOL thumbnailInitialized;

@end

@implementation SeekThumbnailSlot

#pragma mark - Slot Lifecycle

- (void)setupContentView {
    self.backgroundColor = [UIColor clearColor];
    // 纯展示浮层，不参与任何触摸交互，避免遮挡下层手势
    self.userInteractionEnabled = NO;

    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.containerView];

    self.thumbnailImageView = [[UIImageView alloc] init];
    self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.thumbnailImageView.backgroundColor = [UIColor clearColor];
    self.thumbnailImageView.layer.cornerRadius = kThumbnailCornerRadius;
    self.thumbnailImageView.clipsToBounds = YES;
    self.thumbnailImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.thumbnailImageView];

    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.font = [UIFont systemFontOfSize:kTimeLabelFontSize];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.timeLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.containerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-kContainerBottomMargin],

        // 图片尺寸随内容等比变化：上限 200pt，占位下限 112pt
        [self.thumbnailImageView.topAnchor constraintEqualToAnchor:self.containerView.topAnchor],
        [self.thumbnailImageView.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.thumbnailImageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.containerView.leadingAnchor],
        [self.thumbnailImageView.trailingAnchor constraintLessThanOrEqualToAnchor:self.containerView.trailingAnchor],
        [self.thumbnailImageView.widthAnchor constraintLessThanOrEqualToConstant:kThumbnailMaxSize],
        [self.thumbnailImageView.heightAnchor constraintLessThanOrEqualToConstant:kThumbnailMaxSize],
        [self.thumbnailImageView.widthAnchor constraintGreaterThanOrEqualToConstant:kThumbnailPlaceholderSize],
        [self.thumbnailImageView.heightAnchor constraintGreaterThanOrEqualToConstant:kThumbnailPlaceholderSize],

        [self.timeLabel.topAnchor constraintEqualToAnchor:self.thumbnailImageView.bottomAnchor constant:kTimeLabelTopMargin],
        [self.timeLabel.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.timeLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.containerView.leadingAnchor],
        [self.timeLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.containerView.trailingAnchor],
    ]];

    // 章节标题标签（时间标签下方，仅 AI_VOD 场景显示）
    self.chapterTitleLabel = [[UILabel alloc] init];
    self.chapterTitleLabel.textColor = [UIColor whiteColor];
    self.chapterTitleLabel.font = [UIFont systemFontOfSize:kChapterTitleFontSize];
    self.chapterTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.chapterTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.chapterTitleLabel.numberOfLines = 1;
    self.chapterTitleLabel.hidden = YES;
    self.chapterTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.chapterTitleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.chapterTitleLabel.topAnchor constraintEqualToAnchor:self.timeLabel.bottomAnchor constant:kChapterTitleTopMargin],
        [self.chapterTitleLabel.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.chapterTitleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.containerView.leadingAnchor],
        [self.chapterTitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.containerView.trailingAnchor],
        [self.chapterTitleLabel.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor],
    ]];

    // 初始隐藏，拖动开始事件到达时再显示
    [self hide];
}

- (void)onBindData:(AliPlayerModel *)model {
    [super onBindData:model];

    // 双源初始化之一：外部指定的缩略图 URL 优先生效
    // thumbnailUrl 对外标记为废弃（推荐 Vid 自动提取），此处为兼容读取
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSString *externalUrl = model.thumbnailUrl;
#pragma clang diagnostic pop
    if (externalUrl.length > 0) {
        [self.host.controller setThumbnailUrl:externalUrl];
        self.externalUrlUsed = YES;
        self.thumbnailInitialized = YES;
        SLOGI(@"Thumbnail initialized with external url");
    }
}

- (void)onUnbindData {
    [self resetThumbnailState];
    [super onUnbindData];
}

- (void)onDetach {
    [self resetThumbnailState];
    [super onDetach];
}

#pragma mark - SlotActionNotificationDelegate

- (void)slotDidBeginSeekPreview {
    [self show];
}

- (void)slotDidUpdateSeekPreview:(int64_t)targetPositionMs
                        duration:(int64_t)durationMs {
    self.timeLabel.text = [NSString stringWithFormat:kTimeTextFormat,
                           [FormatUtil formatTime:targetPositionMs],
                           [FormatUtil formatTime:durationMs]];

    // 未初始化成功时仅更新时间文本，不发起缩略图请求
    if (self.thumbnailInitialized) {
        [self.host.controller requestThumbnailAtPosition:targetPositionMs];
    }

    // 章节标题显示（仅 AI_VOD 场景）
    NSArray<ChapterInfo *> *chapters = self.host.model.chapters;
    if (chapters.count >= 2) {
        NSInteger chapterIndex = [ChapterInfo findIndexByPosition:chapters
                                                       positionMs:(NSInteger)targetPositionMs];
        if (chapterIndex >= 0 && chapterIndex < (NSInteger)chapters.count) {
            self.chapterTitleLabel.text = chapters[chapterIndex].title;
            self.chapterTitleLabel.hidden = NO;
        } else {
            self.chapterTitleLabel.hidden = YES;
        }
    } else {
        self.chapterTitleLabel.hidden = YES;
    }
}

- (void)slotDidEndSeekPreview {
    // 隐藏浮层并清空时间文本；图片保留，下次拖动可立即展示上一帧
    [self hide];
    self.timeLabel.text = nil;
    self.chapterTitleLabel.text = nil;
    self.chapterTitleLabel.hidden = YES;
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidReadyThumbnailUrl:(NSString *)thumbnailUrl {
    // 双源初始化之二：媒体信息自动提取的 URL，仅在外部 URL 未使用且尚未初始化时生效
    if (self.externalUrlUsed || self.thumbnailInitialized || thumbnailUrl.length == 0) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        // 主线程块内二次检查，防止并发场景下重复初始化
        if (strongSelf.thumbnailInitialized) return;
        [strongSelf initializeThumbnailWithUrl:thumbnailUrl];
    });
}

- (void)playerDidRetrieveThumbnail:(int64_t)positionMs
                             image:(UIImage *)image {
    self.thumbnailImageView.image = image;
}

#pragma mark - Private Methods

- (void)initializeThumbnailWithUrl:(NSString *)thumbnailUrl {
    [self.host.controller setThumbnailUrl:thumbnailUrl];
    self.thumbnailInitialized = YES;
    SLOGI(@"Thumbnail initialized with media info url");
}

- (void)resetThumbnailState {
    self.externalUrlUsed = NO;
    self.thumbnailInitialized = NO;
    self.thumbnailImageView.image = nil;
    self.timeLabel.text = nil;
}

@end
