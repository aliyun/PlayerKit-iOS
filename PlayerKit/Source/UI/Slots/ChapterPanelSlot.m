//
//  ChapterPanelSlot.m
//  AliPlayerKit
//
//  Created by keria on 2026/08/11.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "ChapterPanelSlot.h"
#import "ChapterInfo.h"
#import "FormatUtil.h"
#import "LocaleKeys.h"
#import "LocaleMacros.h"
#import "Log.h"
#import "PlayerColor.h"
#import "PlayerNotificationDelegate.h"

#import <SDWebImage/UIImageView+WebCache.h>

// 从 SceneAiEducation 资源 bundle 加载图片
static UIImage *AiEducationImageNamed(NSString *name) {
    NSBundle *mainBundle = [NSBundle bundleForClass:[ChapterPanelSlot class]];
    NSURL *bundleURL = [mainBundle URLForResource:@"PlayerKitScenes_SceneAiEducation"
                                    withExtension:@"bundle"];
    NSBundle *resourceBundle = bundleURL ? [NSBundle bundleWithURL:bundleURL] : mainBundle;
    return [UIImage imageNamed:name
                      inBundle:resourceBundle
     compatibleWithTraitCollection:nil];
}

#pragma mark - Constants

static const CGFloat kPanelWidth = 345.0;
static const CGFloat kHeaderHeight = 56.0;
static const CGFloat kCellHeight = 72.0;
static const CGFloat kThumbnailWidth = 80.0;
static const CGFloat kThumbnailHeight = 45.0;
static const CGFloat kCellPaddingH = 12.0;
static const CGFloat kCellContentSpacing = 8.0;

static NSString *const kChapterCellIdentifier = @"ChapterPanelCell";

#pragma mark - ChapterPanelCell

@interface ChapterPanelCell : UITableViewCell

@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIImageView *chevronView;

- (void)configureWithChapter:(ChapterInfo *)chapter isCurrent:(BOOL)isCurrent;

@end

@implementation ChapterPanelCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        // 消除 layoutMargins 留白
        self.layoutMargins = UIEdgeInsetsZero;
        self.preservesSuperviewLayoutMargins = NO;
        [self setupCellUI];
    }

    return self;
}

- (void)setupCellUI {
    self.thumbnailImageView = [[UIImageView alloc] init];
    self.thumbnailImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.thumbnailImageView.clipsToBounds = YES;
    self.thumbnailImageView.layer.cornerRadius = 4.0;
    self.thumbnailImageView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    [self.contentView addSubview:self.thumbnailImageView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.contentView addSubview:self.titleLabel];

    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timeLabel.font = [UIFont systemFontOfSize:12];
    self.timeLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.4];
    [self.contentView addSubview:self.timeLabel];

    // 右侧箭头
    UIImageView *chevronView = [[UIImageView alloc] init];
    chevronView.translatesAutoresizingMaskIntoConstraints = NO;
    chevronView.image = AiEducationImageNamed(@"ai_education_chevron_right");
    chevronView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:chevronView];
    self.chevronView = chevronView;

    [NSLayoutConstraint activateConstraints:@[
        [self.thumbnailImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor
                                                              constant:kCellPaddingH],
        [self.thumbnailImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.thumbnailImageView.widthAnchor constraintEqualToConstant:kThumbnailWidth],
        [self.thumbnailImageView.heightAnchor constraintEqualToConstant:kThumbnailHeight],

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.thumbnailImageView.trailingAnchor
                                                      constant:kCellContentSpacing],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.chevronView.leadingAnchor
                                                       constant:-kCellContentSpacing],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.thumbnailImageView.topAnchor],

        [self.timeLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.timeLabel.bottomAnchor constraintEqualToAnchor:self.thumbnailImageView.bottomAnchor],

        [self.chevronView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor
                                                        constant:-kCellPaddingH],
        [self.chevronView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.chevronView.widthAnchor constraintEqualToConstant:16],
        [self.chevronView.heightAnchor constraintEqualToConstant:16],
    ]];
}

- (void)configureWithChapter:(ChapterInfo *)chapter isCurrent:(BOOL)isCurrent {
    self.titleLabel.text = chapter.title;

    if (isCurrent) {
        // 当前章节：白色粗体 + 浅色背景高亮
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        self.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.06];
    } else {
        // 非当前章节：普通字重 + 透明背景
        self.titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        self.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        self.contentView.backgroundColor = [UIColor clearColor];
    }

    self.timeLabel.text = [FormatUtil formatTime:chapter.startMs];

    if (chapter.thumbnailUrl.length > 0) {
        [self.thumbnailImageView sd_setImageWithURL:[NSURL URLWithString:chapter.thumbnailUrl]
                                   placeholderImage:nil];
    } else {
        self.thumbnailImageView.image = nil;
    }
}

@end

#pragma mark - ChapterPanelSlot

@interface ChapterPanelSlot () <UITableViewDataSource, UITableViewDelegate, PlayerNotificationDelegate>

@property (nonatomic, strong) UIView *panelContainer;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *chapterCountLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, copy) NSArray<ChapterInfo *> *chapters;
@property (nonatomic, assign) NSInteger currentChapterIndex;

@end

@implementation ChapterPanelSlot

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        _currentChapterIndex = -1;
    }

    return self;
}

#pragma mark - BasePanelSlot Overrides

/// 面板贴右侧边缘，由基类统一以 transform 滑入滑出
- (nullable UIView *)panelView {
    return self.panelContainer;
}

- (PanelSlideEdge)panelSlideEdge {
    return PanelSlideEdgeRight;
}

/// 宽度固定为 kPanelWidth，直接给出确定尺寸，不依赖布局是否已结算
- (CGSize)panelSize {
    return CGSizeMake(kPanelWidth, self.bounds.size.height);
}

/// 无章节数据时不具备显示条件；有数据则刷新列表
- (BOOL)onPrepareForShow {
    if (self.chapters.count == 0) {
        SLOGW(@"No chapters available, ignoring show request");
        return NO;
    }

    [self reloadChapterData];
    return YES;
}

#pragma mark - Slot Lifecycle

- (void)setupContentView {
    self.hidden = YES;
    self.backgroundColor = [UIColor clearColor];

    // 面板容器
    self.panelContainer = [[UIView alloc] init];
    self.panelContainer.backgroundColor = [UIColor clearColor];
    self.panelContainer.clipsToBounds = YES;
    if (@available(iOS 11.0, *)) {
        self.panelContainer.layer.cornerRadius = 16.0;
        self.panelContainer.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    }
    [self addSubview:self.panelContainer];

    // 毛玻璃背景层
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    UIView *darkOverlay = [[UIView alloc] init];
    darkOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25];
    darkOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [blurView.contentView addSubview:darkOverlay];

    [self.panelContainer insertSubview:blurView atIndex:0];

    // Header
    [self setupHeader];

    // TableView
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = kCellHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    // 消除 layoutMargins 留白
    self.tableView.layoutMargins = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        self.tableView.insetsContentViewsToSafeArea = NO;
    }
    [self.tableView registerClass:[ChapterPanelCell class]
           forCellReuseIdentifier:kChapterCellIdentifier];
    [self.panelContainer addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.panelContainer.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.panelContainer.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.panelContainer.bottomAnchor],
    ]];

    SLOGI(@"ChapterPanelSlot content view setup complete");
}

- (void)setupHeader {
    self.headerView = [[UIView alloc] init];
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerView.backgroundColor = [UIColor clearColor];
    [self.panelContainer addSubview:self.headerView];

    // 标题 + 副标题（水平排列）
    UIView *titleContainer = [[UIView alloc] init];
    titleContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.headerView addSubview:titleContainer];

    self.chapterCountLabel = [[UILabel alloc] init];
    self.chapterCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.chapterCountLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.chapterCountLabel.textColor = [UIColor whiteColor];
    [titleContainer addSubview:self.chapterCountLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.font = [UIFont systemFontOfSize:12];
    self.subtitleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.4];
    self.subtitleLabel.text = LocalizedString(@"ai_education_ai_generated");
    [titleContainer addSubview:self.subtitleLabel];

    // 关闭按钮
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButton.backgroundColor = [UIColor colorWithRed:0.18 green:0.18 blue:0.18 alpha:1.0];
    self.closeButton.layer.cornerRadius = 13;
    UIImage *closeIcon = AiEducationImageNamed(@"ai_education_close_icon");
    [self.closeButton setImage:closeIcon forState:UIControlStateNormal];
    self.closeButton.tintColor = [UIColor colorWithRed:0.56 green:0.56 blue:0.58 alpha:1.0];
    [self.closeButton addTarget:self
                         action:@selector(closeButtonTapped)
               forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.closeButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.headerView.topAnchor constraintEqualToAnchor:self.panelContainer.topAnchor],
        [self.headerView.leadingAnchor constraintEqualToAnchor:self.panelContainer.leadingAnchor],
        [self.headerView.trailingAnchor constraintEqualToAnchor:self.panelContainer.trailingAnchor],
        [self.headerView.heightAnchor constraintEqualToConstant:kHeaderHeight],

        [titleContainer.leadingAnchor constraintEqualToAnchor:self.headerView.leadingAnchor constant:16],
        [titleContainer.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],

        [self.chapterCountLabel.leadingAnchor constraintEqualToAnchor:titleContainer.leadingAnchor],
        [self.chapterCountLabel.centerYAnchor constraintEqualToAnchor:titleContainer.centerYAnchor],

        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.chapterCountLabel.trailingAnchor constant:6],
        [self.subtitleLabel.centerYAnchor constraintEqualToAnchor:titleContainer.centerYAnchor],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:titleContainer.trailingAnchor],

        [self.closeButton.trailingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor constant:-12],
        [self.closeButton.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
        [self.closeButton.widthAnchor constraintEqualToConstant:26],
        [self.closeButton.heightAnchor constraintEqualToConstant:26],
    ]];
}

- (void)onBindData:(AliPlayerModel *)model {
    [super onBindData:model];

    if (model.sceneType == SceneTypeAIVod && model.chapters.count >= 2) {
        self.chapters = model.chapters;
        self.currentChapterIndex = -1;
    } else {
        self.chapters = nil;
        self.currentChapterIndex = -1;
    }
}

- (void)onUnbindData {
    self.chapters = nil;
    self.currentChapterIndex = -1;
    [super onUnbindData];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    // 始终按"已显示"的位置布局，隐藏态由基类通过 transform 平移到屏外，因此无需区分显示状态。
    // 必须走基类的 layoutPanelView:toShownFrame:（内部只写 bounds / center）而不能直接赋值
    // frame——滑动动画进行中面板的 transform 非 identity，此时写 frame 会把它拽回显示位置
    CGFloat parentWidth = self.bounds.size.width;
    CGFloat parentHeight = self.bounds.size.height;
    [self layoutPanelView:self.panelContainer
             toShownFrame:CGRectMake(parentWidth - kPanelWidth, 0, kPanelWidth, parentHeight)];
}

#pragma mark - SlotActionNotificationDelegate

- (void)slotDidRequestShowChapterPanel {
    // 延迟创建与"有无章节数据"的判定均由基类的 showPanel / onPrepareForShow 负责
    [self showPanel];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidUpdateCurrentPosition:(NSInteger)position
                              duration:(NSInteger)duration
                      bufferedPosition:(NSInteger)bufferedPosition {
    if (!self.chapters || self.chapters.count == 0) {
        return;
    }

    NSInteger newIndex = [ChapterInfo findIndexByPosition:self.chapters positionMs:position];
    if (newIndex != self.currentChapterIndex) {
        NSInteger oldIndex = self.currentChapterIndex;
        self.currentChapterIndex = newIndex;

        if (self.isPanelShowing) {
            NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];

            if (oldIndex >= 0 && oldIndex < (NSInteger)self.chapters.count) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:oldIndex inSection:0]];
            }

            if (newIndex >= 0 && newIndex < (NSInteger)self.chapters.count) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:newIndex inSection:0]];
            }

            if (indexPaths.count > 0) {
                [self.tableView reloadRowsAtIndexPaths:indexPaths
                                      withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }
}

#pragma mark - Actions

- (void)closeButtonTapped {
    [self hidePanel];
}

#pragma mark - Private

- (void)reloadChapterData {
    self.chapterCountLabel.text = LocalizedFormat(@"ai_education_chapter_count_format", (long)self.chapters.count);
    [self.tableView reloadData];

    // 滚动到当前章节
    if (self.currentChapterIndex >= 0 && self.currentChapterIndex < (NSInteger)self.chapters.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentChapterIndex inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath
                                  atScrollPosition:UITableViewScrollPositionMiddle
                                          animated:NO];
        });
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.chapters.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChapterPanelCell *cell = [tableView dequeueReusableCellWithIdentifier:kChapterCellIdentifier
                                                             forIndexPath:indexPath];
    ChapterInfo *chapter = self.chapters[indexPath.row];
    BOOL isCurrent = (indexPath.row == self.currentChapterIndex);

    [cell configureWithChapter:chapter isCurrent:isCurrent];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < 0 || indexPath.row >= (NSInteger)self.chapters.count) {
        return;
    }

    ChapterInfo *chapter = self.chapters[indexPath.row];
    [self.host.controller seekTo:chapter.startMs];
    [self hidePanel];
    SLOGI(@"Chapter selected: %@ (startMs=%ld)", chapter.title, (long)chapter.startMs);
}

@end
