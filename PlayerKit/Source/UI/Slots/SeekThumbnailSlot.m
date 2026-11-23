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
@property (nonatomic, strong) NSLayoutConstraint *containerBottomConstraint;

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

    self.containerBottomConstraint = [self.containerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-kContainerBottomMargin];
    NSLayoutConstraint *placeholderWidth = [self.thumbnailImageView.widthAnchor constraintGreaterThanOrEqualToConstant:kThumbnailPlaceholderSize];
    NSLayoutConstraint *placeholderHeight = [self.thumbnailImageView.heightAnchor constraintGreaterThanOrEqualToConstant:kThumbnailPlaceholderSize];
    placeholderWidth.priority = UILayoutPriorityDefaultLow;
    placeholderHeight.priority = UILayoutPriorityDefaultLow;

    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        self.containerBottomConstraint,
        [self.containerView.topAnchor constraintGreaterThanOrEqualToAnchor:self.topAnchor],
        [self.containerView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor],
        [self.containerView.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor],

        // 空间不足时允许缩小图片占位，优先保留时间和章节文本
        [self.thumbnailImageView.topAnchor constraintEqualToAnchor:self.containerView.topAnchor],
        [self.thumbnailImageView.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.thumbnailImageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.containerView.leadingAnchor],
        [self.thumbnailImageView.trailingAnchor constraintLessThanOrEqualToAnchor:self.containerView.trailingAnchor],
        [self.thumbnailImageView.widthAnchor constraintLessThanOrEqualToConstant:kThumbnailMaxSize],
        [self.thumbnailImageView.heightAnchor constraintLessThanOrEqualToConstant:kThumbnailMaxSize],
        placeholderWidth,
        placeholderHeight,

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

    // 章节标题显示（章节数据统一由 controller 存储，可能晚于绑定到达）
    NSArray<ChapterInfo *> *chapters = self.host.controller.chapters;
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

#pragma mark - Layout

- (void)layoutSubviews {
    // 高度不足时缩小底距，为图片占位和文本预留空间
    CGFloat textHeight = self.timeLabel.intrinsicContentSize.height + kTimeLabelTopMargin
                       + self.chapterTitleLabel.intrinsicContentSize.height + kChapterTitleTopMargin;
    CGFloat bottomMargin = MIN(kContainerBottomMargin, MAX(0, CGRectGetHeight(self.bounds) - textHeight - kThumbnailPlaceholderSize));
    if (self.containerBottomConstraint.constant != -bottomMargin) {
        self.containerBottomConstraint.constant = -bottomMargin;
    }
    [super layoutSubviews];
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
