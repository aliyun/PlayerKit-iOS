//
//  ChapterContentView.m
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "ChapterContentView.h"
#import "FormatUtil.h"
#import "AiVideoContent.h"
#import "AiContentType.h"
#import "AiSummary.h"
#import "AiSegment.h"
#import "AiEducationMarkdownRenderer.h"
#import "AiEducationColorConstants.h"
#import "ChapterInfo.h"
#import "LocaleMacros.h"

#import <SDWebImage/UIImageView+WebCache.h>

static NSString * const kChapterCellIdentifier = @"AiEducationChapterCell";
static NSString * const kSegmentCellIdentifier = @"AiEducationSegmentCell";

#pragma mark - Chapter Cell

// 章节列表 cell：缩略图 + 标题 + 时间区间
@interface AiEducationChapterCell : UITableViewCell

@property (nonatomic, strong) UIImageView *thumbnailView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *timeLabel;

@end

@implementation AiEducationChapterCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];

        _thumbnailView = [[UIImageView alloc] init];
        _thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
        _thumbnailView.clipsToBounds = YES;
        _thumbnailView.layer.cornerRadius = 4;
        _thumbnailView.backgroundColor = AiEducationThumbnailBgColor();
        _thumbnailView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_thumbnailView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:14];
        _titleLabel.textColor = AiEducationTextPrimaryColor();
        _titleLabel.numberOfLines = 2;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_titleLabel];

        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = AiEducationTextSecondaryColor();
        _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_timeLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_thumbnailView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [_thumbnailView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_thumbnailView.widthAnchor constraintEqualToConstant:80],
            [_thumbnailView.heightAnchor constraintEqualToConstant:45],

            [_titleLabel.leadingAnchor constraintEqualToAnchor:_thumbnailView.trailingAnchor constant:12],
            [_titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [_titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10],

            [_timeLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_timeLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:4],
            [_timeLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-10],
        ]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.thumbnailView sd_cancelCurrentImageLoad];
    self.thumbnailView.image = nil;
    self.titleLabel.text = nil;
    self.timeLabel.text = nil;
}

@end

#pragma mark - Segment Cell

// AI 解析分段卡片 cell：标题 + 时间徽标 + 文字摘要或 Markdown 富文本
@interface AiEducationSegmentCell : UITableViewCell

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *contentLabel;

// 时间徽标点击回调（由面板在 cell 绑定时注入）
@property (nonatomic, copy, nullable) void (^onTimeTapped)(void);

@end

@implementation AiEducationSegmentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];

        _cardView = [[UIView alloc] init];
        _cardView.backgroundColor = AiEducationCardBgNormalColor();
        _cardView.layer.cornerRadius = 8;
        _cardView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_cardView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _titleLabel.textColor = AiEducationTextPrimaryColor();
        _titleLabel.numberOfLines = 0;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_cardView addSubview:_titleLabel];

        // 时间徽标：仅时间戳可点击触发 seek
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = AiEducationTextSecondaryColor();
        _timeLabel.userInteractionEnabled = YES;
        _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_timeLabel setContentHuggingPriority:UILayoutPriorityRequired
                                      forAxis:UILayoutConstraintAxisHorizontal];
        [_timeLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                    forAxis:UILayoutConstraintAxisHorizontal];
        UITapGestureRecognizer *timeTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(onTimeLabelTapped:)];
        [_timeLabel addGestureRecognizer:timeTap];
        [_cardView addSubview:_timeLabel];

        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:13];
        _contentLabel.textColor = AiEducationBodyTextColor();
        _contentLabel.numberOfLines = 0;
        _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_cardView addSubview:_contentLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [_cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [_cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6],
            [_cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6],

            [_titleLabel.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:12],
            [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_timeLabel.leadingAnchor constant:-8],
            [_titleLabel.topAnchor constraintEqualToAnchor:_cardView.topAnchor constant:12],

            [_timeLabel.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-12],
            [_timeLabel.firstBaselineAnchor constraintEqualToAnchor:_titleLabel.firstBaselineAnchor],

            [_contentLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_contentLabel.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-12],
            [_contentLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:8],
            [_contentLabel.bottomAnchor constraintEqualToAnchor:_cardView.bottomAnchor constant:-12],
        ]];
    }
    return self;
}

// 时间徽标点击：透传给外部回调
- (void)onTimeLabelTapped:(UITapGestureRecognizer *)recognizer {
    if (self.onTimeTapped) {
        self.onTimeTapped();
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    // 复用前清空富文本与回调，避免样式串行和误触旧回调
    self.titleLabel.text = nil;
    self.timeLabel.text = nil;
    self.timeLabel.textColor = AiEducationTextSecondaryColor();
    self.contentLabel.text = nil;
    self.contentLabel.attributedText = nil;
    self.onTimeTapped = nil;
}

@end

#pragma mark - Panel Content View

@interface ChapterContentView () <UITableViewDataSource, UITableViewDelegate>

// AI 视频内容数据
@property (nonatomic, strong) AiVideoContent *content;

// 顶部标题
@property (nonatomic, strong) UILabel *panelTitleLabel;

// 双 Tab 切换控件（仅一类内容时隐藏）
@property (nonatomic, strong) UISegmentedControl *tabControl;

// 章节列表
@property (nonatomic, strong) UITableView *chapterTableView;

// AI 解析列表
@property (nonatomic, strong) UITableView *segmentTableView;

// 是否有章节数据
@property (nonatomic, assign) BOOL hasChapters;

// 是否有 AI 解析数据
@property (nonatomic, assign) BOOL hasAnalysis;

// 当前高亮章节索引
@property (nonatomic, assign) NSInteger currentChapterIndex;

// 当前高亮分段索引
@property (nonatomic, assign) NSInteger currentSegmentIndex;

// 构建摘要头部时所用的宽度（0 表示尚未构建）
@property (nonatomic, assign) CGFloat headerLayoutWidth;

@end

@implementation ChapterContentView

#pragma mark - Lifecycle

- (instancetype)initWithContent:(AiVideoContent *)content {
    // frame 由容器在挂载时设定，这里只需零 frame
    self = [super initWithFrame:CGRectZero];

    if (self) {
        _content = content;
        _currentChapterIndex = -1;
        _currentSegmentIndex = -1;
        _hasChapters = content.chapters.count > 0;
        // 有 AI 解析：summary 或 segments 有内容，且类型达到文字解析
        BOOL hasAnalysisContent = (content.summary != nil) || (content.segments.count > 0);
        _hasAnalysis = hasAnalysisContent && content.type >= AiContentTypeTextAnalysis;

        // 面板内容背景（蒙层与圆角由外部容器处理，对齐 SettingMenuSlot 纯 UIView 模式）
        self.backgroundColor = AiEducationPanelBgColor();
        [self setupSubviews];
        [self switchToTab:_hasChapters ? 0 : 1];
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutControlsForSize:self.bounds.size];
    [self refreshSummaryHeaderForWidth:self.bounds.size.width];
}

#pragma mark - Public Methods

- (void)updateCurrentPosition:(NSInteger)positionMs {
    // 章节高亮：二分定位，仅索引变化时刷新变化行
    if (self.hasChapters) {
        NSInteger chapterIndex = [ChapterInfo findIndexByPosition:self.content.chapters
                                                       positionMs:positionMs];
        if (chapterIndex != self.currentChapterIndex) {
            NSInteger oldIndex = self.currentChapterIndex;
            self.currentChapterIndex = chapterIndex;
            [self reloadRow:oldIndex newRow:chapterIndex inTableView:self.chapterTableView];
        }
    }
    // 分段高亮：二分定位，仅索引变化时刷新变化行
    if (self.hasAnalysis && self.content.segments.count > 0) {
        NSInteger segmentIndex = [self.content findSegmentIndexByPosition:positionMs];
        if (segmentIndex != self.currentSegmentIndex) {
            NSInteger oldIndex = self.currentSegmentIndex;
            self.currentSegmentIndex = segmentIndex;
            [self reloadRow:oldIndex newRow:segmentIndex inTableView:self.segmentTableView];
        }
    }
}

#pragma mark - Private Methods - Setup

// 创建标题、Tab 与两个列表控件
- (void)setupSubviews {
    self.panelTitleLabel = [[UILabel alloc] init];
    self.panelTitleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.panelTitleLabel.textColor = AiEducationTextPrimaryColor();
    if (self.hasChapters) {
        self.panelTitleLabel.text =
            [NSString stringWithFormat:LocalizedString(@"ai_education_chapter_count_format"),
                                       (long)self.content.chapters.count];
    } else {
        self.panelTitleLabel.text = LocalizedString(@"ai_education_tab_analysis");
    }
    [self addSubview:self.panelTitleLabel];

    // 双 Tab：有章节且有 AI 解析时显示
    self.tabControl = [[UISegmentedControl alloc] initWithItems:@[
        LocalizedString(@"ai_education_tab_chapters"),
        LocalizedString(@"ai_education_tab_analysis"),
    ]];
    self.tabControl.selectedSegmentIndex = 0;
    [self.tabControl addTarget:self
                        action:@selector(onTabChanged:)
              forControlEvents:UIControlEventValueChanged];
    self.tabControl.hidden = !(self.hasChapters && self.hasAnalysis);
    [self addSubview:self.tabControl];

    self.chapterTableView = [self buildTableView];
    [self.chapterTableView registerClass:[AiEducationChapterCell class]
                  forCellReuseIdentifier:kChapterCellIdentifier];
    [self addSubview:self.chapterTableView];

    self.segmentTableView = [self buildTableView];
    [self.segmentTableView registerClass:[AiEducationSegmentCell class]
                  forCellReuseIdentifier:kSegmentCellIdentifier];
    [self addSubview:self.segmentTableView];
    // 摘要头部依赖最终宽度，留到首次布局时构建（见 refreshSummaryHeaderForWidth:）
}

// 创建通用列表控件
- (UITableView *)buildTableView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                          style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.rowHeight = UITableViewAutomaticDimension;
    tableView.estimatedRowHeight = 72;
    return tableView;
}

/**
 * 按当前宽度构建 AI 解析列表的头部卡片。
 * tableHeaderView 必须带显式 frame，而本视图的宽度由容器挂载后才确定，
 * 因此头部只能在首次布局时构建，并在宽度变化（横竖屏形态不同）时按新宽度重建。
 */
- (void)refreshSummaryHeaderForWidth:(CGFloat)width {
    if (!self.content.summary || width <= 0 || width == self.headerLayoutWidth) {
        return;
    }

    self.headerLayoutWidth = width;
    self.segmentTableView.tableHeaderView = [self buildSummaryHeaderViewForWidth:width];
}

// AI 解析列表头部：浅灰圆角卡片内渲染视频标题 + 标签徽标行 + 整体摘要
- (nullable UIView *)buildSummaryHeaderViewForWidth:(CGFloat)width {
    AiSummary *summary = self.content.summary;
    if (!summary) {
        return nil;
    }
    CGFloat cardMargin = 16;
    CGFloat cardPadding = 12;
    CGFloat cardWidth = width - cardMargin * 2;
    CGFloat innerWidth = cardWidth - cardPadding * 2;

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 10)];

    // 摘要卡片容器：summaryBg 圆角背景
    UIView *cardView = [[UIView alloc] init];
    cardView.backgroundColor = AiEducationSummaryBgColor();
    cardView.layer.cornerRadius = 8;
    [header addSubview:cardView];

    CGFloat cursorY = cardPadding;

    UILabel *headerTitleLabel = [[UILabel alloc] init];
    headerTitleLabel.font = [UIFont boldSystemFontOfSize:15];
    headerTitleLabel.textColor = AiEducationTextPrimaryColor();
    headerTitleLabel.numberOfLines = 0;
    NSString *headerTitle = summary.title.length > 0
        ? summary.title
        : LocalizedString(@"ai_education_summary_header_title");
    headerTitleLabel.text = headerTitle;
    CGSize titleSize = [headerTitleLabel sizeThatFits:CGSizeMake(innerWidth, CGFLOAT_MAX)];
    headerTitleLabel.frame = CGRectMake(cardPadding, cursorY, innerWidth, titleSize.height);
    [cardView addSubview:headerTitleLabel];
    cursorY += titleSize.height;

    // 标签徽标行：红字浅红底圆角，水平排列超宽换行；无 tags 时不占位
    if (summary.tags.count > 0) {
        cursorY += 8;
        CGFloat tagX = cardPadding;
        CGFloat tagHeight = 20;
        CGFloat tagSpacing = 8;
        UIFont *tagFont = [UIFont systemFontOfSize:11];
        for (NSString *tag in summary.tags) {
            if (tag.length == 0) {
                continue;
            }
            UILabel *tagLabel = [[UILabel alloc] init];
            tagLabel.font = tagFont;
            tagLabel.textColor = AiEducationTagTextColor();
            tagLabel.backgroundColor = AiEducationTagBgColor();
            tagLabel.textAlignment = NSTextAlignmentCenter;
            tagLabel.layer.cornerRadius = tagHeight / 2;
            tagLabel.clipsToBounds = YES;
            tagLabel.text = tag;
            CGFloat textWidth = ceil([tagLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, tagHeight)].width);
            CGFloat tagWidth = MIN(textWidth + 16, innerWidth);
            // 超出当前行宽度时换行
            if (tagX + tagWidth > cardPadding + innerWidth && tagX > cardPadding) {
                tagX = cardPadding;
                cursorY += tagHeight + 6;
            }
            tagLabel.frame = CGRectMake(tagX, cursorY, tagWidth, tagHeight);
            [cardView addSubview:tagLabel];
            tagX += tagWidth + tagSpacing;
        }
        cursorY += tagHeight;
    }

    UILabel *summaryLabel = [[UILabel alloc] init];
    summaryLabel.font = [UIFont systemFontOfSize:13];
    summaryLabel.textColor = AiEducationBodyTextColor();
    summaryLabel.numberOfLines = 0;
    summaryLabel.text = summary.summaryText ?: @"";
    CGSize summarySize = [summaryLabel sizeThatFits:CGSizeMake(innerWidth, CGFLOAT_MAX)];
    summaryLabel.frame = CGRectMake(cardPadding, cursorY + 8, innerWidth, summarySize.height);
    [cardView addSubview:summaryLabel];
    cursorY += 8 + summarySize.height + cardPadding;

    // 回填卡片与头部 frame（tableHeaderView 需要显式 frame）
    cardView.frame = CGRectMake(cardMargin, 12, cardWidth, cursorY);
    header.frame = CGRectMake(0, 0, width, cursorY + 12 + 8);
    return header;
}

#pragma mark - Private Methods - Layout

// 标题与 Tab 顺次排布，两个列表占据剩余区域（自身已铺满外部容器）
- (void)layoutControlsForSize:(CGSize)size {
    CGFloat width = size.width;
    CGFloat height = size.height;
    CGFloat contentTop = 16;

    self.panelTitleLabel.frame = CGRectMake(16, contentTop, width - 32, 22);
    contentTop += 30;

    if (!self.tabControl.hidden) {
        self.tabControl.frame = CGRectMake(16, contentTop, width - 32, 30);
        contentTop += 40;
    }

    CGRect listFrame = CGRectMake(0, contentTop, width, height - contentTop);
    self.chapterTableView.frame = listFrame;
    self.segmentTableView.frame = listFrame;
}

#pragma mark - Private Methods - Actions

// Tab 切换
- (void)onTabChanged:(UISegmentedControl *)control {
    [self switchToTab:control.selectedSegmentIndex];
}

// 切换显示章节列表 / AI 解析列表；index: 0=章节 1=AI 解析
- (void)switchToTab:(NSInteger)index {
    BOOL showChapters = (index == 0) && self.hasChapters;
    self.chapterTableView.hidden = !showChapters;
    self.segmentTableView.hidden = showChapters;
}

// 只刷新高亮变化的行
- (void)reloadRow:(NSInteger)oldRow newRow:(NSInteger)newRow inTableView:(UITableView *)tableView {
    if (!tableView.window) {
        return;
    }
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
    NSInteger rowCount = [tableView numberOfRowsInSection:0];
    if (oldRow >= 0 && oldRow < rowCount) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:oldRow inSection:0]];
    }
    if (newRow >= 0 && newRow < rowCount && newRow != oldRow) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:newRow inSection:0]];
    }
    if (indexPaths.count > 0) {
        [tableView reloadRowsAtIndexPaths:indexPaths
                         withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.chapterTableView) {
        return (NSInteger)self.content.chapters.count;
    }
    return (NSInteger)self.content.segments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.chapterTableView) {
        return [self chapterCellForTableView:tableView indexPath:indexPath];
    }
    return [self segmentCellForTableView:tableView indexPath:indexPath];
}

// 章节 cell 绑定
- (UITableViewCell *)chapterCellForTableView:(UITableView *)tableView
                                   indexPath:(NSIndexPath *)indexPath {
    AiEducationChapterCell *cell =
        [tableView dequeueReusableCellWithIdentifier:kChapterCellIdentifier
                                        forIndexPath:indexPath];
    ChapterInfo *chapter = self.content.chapters[(NSUInteger)indexPath.row];
    cell.titleLabel.text = chapter.title;
    cell.timeLabel.text = [FormatUtil formatTime:chapter.startMs];
    BOOL highlighted = indexPath.row == self.currentChapterIndex;
    cell.titleLabel.textColor = highlighted
        ? AiEducationHighlightRedColor()
        : AiEducationTextPrimaryColor();
    if (chapter.thumbnailUrl.length > 0) {
        [cell.thumbnailView sd_setImageWithURL:[NSURL URLWithString:chapter.thumbnailUrl]];
    }
    return cell;
}

// 分段 cell 绑定：文字摘要或 Markdown 渲染
- (UITableViewCell *)segmentCellForTableView:(UITableView *)tableView
                                   indexPath:(NSIndexPath *)indexPath {
    AiEducationSegmentCell *cell =
        [tableView dequeueReusableCellWithIdentifier:kSegmentCellIdentifier
                                        forIndexPath:indexPath];
    AiSegment *segment = self.content.segments[(NSUInteger)indexPath.row];
    cell.titleLabel.text = segment.title;
    cell.timeLabel.text = [NSString stringWithFormat:@"▷ %@", [FormatUtil formatTime:segment.startMs]];

    // 时间徽标点击 → 透传分段起始时间给外部 seek（仅时间戳可点）
    NSInteger startMs = segment.startMs;
    __weak typeof(self) weakSelf = self;
    cell.onTimeTapped = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.onSegmentSelected) {
            strongSelf.onSegmentSelected(startMs);
        }
    };

    if (segment.markdown.length > 0) {
        cell.contentLabel.attributedText =
            [[AiEducationMarkdownRenderer sharedRenderer] renderMarkdown:segment.markdown];
    } else {
        cell.contentLabel.text = segment.summary ?: @"";
    }

    // 高亮：时间徽标变红，保留卡片背景高亮
    BOOL highlighted = indexPath.row == self.currentSegmentIndex;
    cell.timeLabel.textColor = highlighted
        ? AiEducationHighlightRedColor()
        : AiEducationTextSecondaryColor();
    cell.cardView.backgroundColor = highlighted
        ? AiEducationCardBgHighlightColor()
        : AiEducationCardBgNormalColor();
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView != self.chapterTableView) {
        return;
    }
    ChapterInfo *chapter = self.content.chapters[(NSUInteger)indexPath.row];
    if (self.onChapterSelected) {
        self.onChapterSelected(chapter.startMs);
    }
}

@end
