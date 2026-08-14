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

    [NSLayoutConstraint activateConstraints:@[
        [self.thumbnailImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor
                                                              constant:kCellPaddingH],
        [self.thumbnailImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.thumbnailImageView.widthAnchor constraintEqualToConstant:kThumbnailWidth],
        [self.thumbnailImageView.heightAnchor constraintEqualToConstant:kThumbnailHeight],

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.thumbnailImageView.trailingAnchor
                                                      constant:kCellContentSpacing],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor
                                                       constant:-kCellPaddingH],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.thumbnailImageView.topAnchor],

        [self.timeLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.timeLabel.bottomAnchor constraintEqualToAnchor:self.thumbnailImageView.bottomAnchor],
    ]];
}

- (void)configureWithChapter:(ChapterInfo *)chapter isCurrent:(BOOL)isCurrent {
    if (isCurrent) {
        self.titleLabel.text = [NSString stringWithFormat:@"▶ %@", chapter.title];
        self.titleLabel.textColor = [UIColor colorWithRed:1.0 green:0.267 blue:0.267 alpha:1.0];
    } else {
        self.titleLabel.text = chapter.title;
        self.titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.6];
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
    self.panelContainer.backgroundColor = [PlayerColor settingPanelBackground];
    self.panelContainer.clipsToBounds = YES;
    [self addSubview:self.panelContainer];

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

    self.chapterCountLabel = [[UILabel alloc] init];
    self.chapterCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.chapterCountLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.chapterCountLabel.textColor = [UIColor whiteColor];
    [self.headerView addSubview:self.chapterCountLabel];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.closeButton setTitle:@"✕" forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0]
                           forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [self.closeButton addTarget:self
                         action:@selector(closeButtonTapped)
               forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.closeButton];

    UIView *separatorLine = [[UIView alloc] init];
    separatorLine.translatesAutoresizingMaskIntoConstraints = NO;
    separatorLine.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    [self.headerView addSubview:separatorLine];

    [NSLayoutConstraint activateConstraints:@[
        [self.headerView.topAnchor constraintEqualToAnchor:self.panelContainer.topAnchor],
        [self.headerView.leadingAnchor constraintEqualToAnchor:self.panelContainer.leadingAnchor],
        [self.headerView.trailingAnchor constraintEqualToAnchor:self.panelContainer.trailingAnchor],
        [self.headerView.heightAnchor constraintEqualToConstant:kHeaderHeight],

        [self.chapterCountLabel.leadingAnchor constraintEqualToAnchor:self.headerView.leadingAnchor constant:16],
        [self.chapterCountLabel.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],

        [self.closeButton.trailingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor constant:-12],
        [self.closeButton.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
        [self.closeButton.widthAnchor constraintEqualToConstant:36],
        [self.closeButton.heightAnchor constraintEqualToConstant:36],

        [separatorLine.leadingAnchor constraintEqualToAnchor:self.headerView.leadingAnchor],
        [separatorLine.trailingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor],
        [separatorLine.bottomAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
        [separatorLine.heightAnchor constraintEqualToConstant:0.5],
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
    self.chapterCountLabel.text = LocalizedFormat(LocaleKeyChapterCountFormat, (long)self.chapters.count);
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
