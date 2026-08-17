//
//  ChapterContentView.m
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "ChapterContentView.h"
#import "FormatUtil.h"
#import "AiContentViewModel.h"
#import "KnowledgeInfo.h"
#import "SummaryInfo.h"
#import "AiAnalysisResponse.h"
#import "AiContentType.h"
#import "AiEducationMarkdownRenderer.h"
#import "AiEducationColorConstants.h"
#import "ChapterInfo.h"
#import "LocaleMacros.h"

#import <SDWebImage/UIImageView+WebCache.h>

static NSString * const kChapterCellIdentifier = @"AiEducationChapterCell";
static NSString * const kTextAnalysisCellIdentifier = @"AiEducationTextAnalysisCell";

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

#pragma mark - Text Analysis Cell

// 文字解析 cell：章节标题 + 时间徽标 + 知识点/摘要 markdown 渲染
@interface AiEducationTextAnalysisCell : UITableViewCell

@property (nonatomic, strong) UILabel *chapterTitleLabel;
@property (nonatomic, strong) UILabel *timeBadgeLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIView *cardContainer;

@end

@implementation AiEducationTextAnalysisCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];

        _cardContainer = [[UIView alloc] init];
        _cardContainer.backgroundColor = AiEducationSummaryBgColor();
        _cardContainer.layer.cornerRadius = 8;
        _cardContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_cardContainer];

        _chapterTitleLabel = [[UILabel alloc] init];
        _chapterTitleLabel.font = [UIFont boldSystemFontOfSize:15];
        _chapterTitleLabel.textColor = AiEducationTextPrimaryColor();
        _chapterTitleLabel.numberOfLines = 2;
        _chapterTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_cardContainer addSubview:_chapterTitleLabel];

        _timeBadgeLabel = [[UILabel alloc] init];
        _timeBadgeLabel.font = [UIFont systemFontOfSize:11];
        _timeBadgeLabel.textColor = AiEducationTagTextColor();
        _timeBadgeLabel.backgroundColor = AiEducationTagBgColor();
        _timeBadgeLabel.textAlignment = NSTextAlignmentCenter;
        _timeBadgeLabel.layer.cornerRadius = 10;
        _timeBadgeLabel.clipsToBounds = YES;
        _timeBadgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_cardContainer addSubview:_timeBadgeLabel];

        _contentLabel = [[UILabel alloc] init];
        _contentLabel.numberOfLines = 0;
        _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_cardContainer addSubview:_contentLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_cardContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [_cardContainer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [_cardContainer.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6],
            [_cardContainer.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6],

            [_chapterTitleLabel.leadingAnchor constraintEqualToAnchor:_cardContainer.leadingAnchor constant:12],
            [_chapterTitleLabel.topAnchor constraintEqualToAnchor:_cardContainer.topAnchor constant:12],
            [_chapterTitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_timeBadgeLabel.leadingAnchor constant:-8],

            [_timeBadgeLabel.trailingAnchor constraintEqualToAnchor:_cardContainer.trailingAnchor constant:-12],
            [_timeBadgeLabel.centerYAnchor constraintEqualToAnchor:_chapterTitleLabel.centerYAnchor],
            [_timeBadgeLabel.widthAnchor constraintGreaterThanOrEqualToConstant:48],
            [_timeBadgeLabel.heightAnchor constraintEqualToConstant:20],

            [_contentLabel.leadingAnchor constraintEqualToAnchor:_cardContainer.leadingAnchor constant:12],
            [_contentLabel.trailingAnchor constraintEqualToAnchor:_cardContainer.trailingAnchor constant:-12],
            [_contentLabel.topAnchor constraintEqualToAnchor:_chapterTitleLabel.bottomAnchor constant:8],
            [_contentLabel.bottomAnchor constraintEqualToAnchor:_cardContainer.bottomAnchor constant:-12],
        ]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.chapterTitleLabel.text = nil;
    self.timeBadgeLabel.text = nil;
    self.contentLabel.attributedText = nil;
}

@end

#pragma mark - Panel Content View

@interface ChapterContentView () <UITableViewDataSource, UITableViewDelegate>

// 视图模型（持有全部展示数据）
@property (nonatomic, strong) AiContentViewModel *viewModel;

// 顶部标题
@property (nonatomic, strong) UILabel *panelTitleLabel;

// 双 Tab 切换控件（无 TAB 时隐藏）
@property (nonatomic, strong) UISegmentedControl *tabControl;

// 章节列表（ChaptersOnly）
@property (nonatomic, strong) UITableView *chapterTableView;

// 文字解析列表（TextAnalysis）
@property (nonatomic, strong) UITableView *textAnalysisTableView;

// 图解分析列表（GraphicAnalysis，内容位于 tableHeaderView）
@property (nonatomic, strong) UITableView *graphicTableView;

// TAB 组合配置
@property (nonatomic, assign) AiContentType tab0Type;
@property (nonatomic, assign) AiContentType tab1Type;
@property (nonatomic, assign) BOOL showTabs;

// 当前激活的内容类型
@property (nonatomic, assign) AiContentType activeType;

// 当前高亮章节索引（ChaptersOnly / TextAnalysis 共用）
@property (nonatomic, assign) NSInteger currentChapterIndex;

// 构建摘要头部时所用的宽度（0 表示尚未构建）
@property (nonatomic, assign) CGFloat headerLayoutWidth;

@end

@implementation ChapterContentView

#pragma mark - Lifecycle

- (instancetype)initWithViewModel:(AiContentViewModel *)viewModel {
    // frame 由容器在挂载时设定，这里只需零 frame
    self = [super initWithFrame:CGRectZero];

    if (self) {
        _viewModel = viewModel;
        _currentChapterIndex = -1;

        // 确定 TAB 组合逻辑
        BOOL hasChapter = viewModel.hasChapterData;
        BOOL hasSummary = viewModel.hasSummaryData;

        if (hasChapter && hasSummary) {
            // 双 TAB：ChaptersOnly + GraphicAnalysis
            _tab0Type = AiContentTypeChaptersOnly;
            _tab1Type = AiContentTypeGraphicAnalysis;
            _showTabs = YES;
        } else if (hasChapter) {
            // 双 TAB：ChaptersOnly + TextAnalysis
            _tab0Type = AiContentTypeChaptersOnly;
            _tab1Type = AiContentTypeTextAnalysis;
            _showTabs = YES;
        } else {
            // 无 TAB：GraphicAnalysis 直接展示
            _tab0Type = AiContentTypeGraphicAnalysis;
            _tab1Type = AiContentTypeGraphicAnalysis; // unused
            _showTabs = NO;
        }

        // 面板内容背景（蒙层与圆角由外部容器处理，对齐 SettingMenuSlot 纯 UIView 模式）
        self.backgroundColor = AiEducationPanelBgColor();
        [self setupSubviews];
        [self switchToTab:0];
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutControlsForSize:self.bounds.size];
    [self refreshGraphicHeaderForWidth:self.bounds.size.width];
}

#pragma mark - Public Methods

- (void)updateCurrentPosition:(NSInteger)positionMs {
    // 章节高亮：二分定位，仅索引变化时刷新变化行
    NSArray<ChapterInfo *> *chapters = self.viewModel.chapters;
    if (chapters.count == 0) {
        return;
    }
    NSInteger chapterIndex = [ChapterInfo findIndexByPosition:chapters positionMs:positionMs];
    if (chapterIndex != self.currentChapterIndex) {
        NSInteger oldIndex = self.currentChapterIndex;
        self.currentChapterIndex = chapterIndex;
        // 刷新 ChaptersOnly 列表（仅当 ChaptersOnly 在当前 TAB 组合中时）
        if (self.tab0Type == AiContentTypeChaptersOnly || self.tab1Type == AiContentTypeChaptersOnly) {
            [self reloadRow:oldIndex newRow:chapterIndex inTableView:self.chapterTableView];
        }
        // 刷新 TextAnalysis 列表（仅当 TextAnalysis 在当前 TAB 组合中时）
        if (self.tab0Type == AiContentTypeTextAnalysis || self.tab1Type == AiContentTypeTextAnalysis) {
            [self reloadRow:oldIndex newRow:chapterIndex inTableView:self.textAnalysisTableView];
        }
    }
}

#pragma mark - Private Methods - Setup

// 创建标题、Tab 与列表控件
- (void)setupSubviews {
    self.panelTitleLabel = [[UILabel alloc] init];
    self.panelTitleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.panelTitleLabel.textColor = AiEducationTextPrimaryColor();

    // 标题文案
    if (self.viewModel.chapters.count > 0) {
        self.panelTitleLabel.text =
            [NSString stringWithFormat:LocalizedString(@"ai_education_chapter_count_format"),
                                       (long)self.viewModel.chapters.count];
    } else {
        self.panelTitleLabel.text = LocalizedString(@"ai_education_tab_analysis");
    }
    [self addSubview:self.panelTitleLabel];

    // 双 Tab 控件：根据组合类型设置标题
    NSString *tab0Title = [self tabTitleForContentType:self.tab0Type];
    NSString *tab1Title = [self tabTitleForContentType:self.tab1Type];
    self.tabControl = [[UISegmentedControl alloc] initWithItems:@[tab0Title, tab1Title]];
    self.tabControl.selectedSegmentIndex = 0;
    [self.tabControl addTarget:self
                        action:@selector(onTabChanged:)
              forControlEvents:UIControlEventValueChanged];
    self.tabControl.hidden = !self.showTabs;
    [self addSubview:self.tabControl];

    // ChaptersOnly 列表
    self.chapterTableView = [self buildTableView];
    [self.chapterTableView registerClass:[AiEducationChapterCell class]
                  forCellReuseIdentifier:kChapterCellIdentifier];
    [self addSubview:self.chapterTableView];

    // TextAnalysis 列表
    self.textAnalysisTableView = [self buildTableView];
    [self.textAnalysisTableView registerClass:[AiEducationTextAnalysisCell class]
                       forCellReuseIdentifier:kTextAnalysisCellIdentifier];
    [self addSubview:self.textAnalysisTableView];

    // GraphicAnalysis 列表（内容全部位于 tableHeaderView，列表体始终 0 行）
    self.graphicTableView = [self buildTableView];
    [self addSubview:self.graphicTableView];
    // 摘要头部依赖最终宽度，留到首次布局时构建（见 refreshGraphicHeaderForWidth:）
}

// 返回 TAB 标题文案
- (NSString *)tabTitleForContentType:(AiContentType)type {
    switch (type) {
        case AiContentTypeChaptersOnly:
            return LocalizedString(@"ai_education_tab_chapters");
        case AiContentTypeTextAnalysis:
            return LocalizedString(@"ai_education_tab_analysis");
        case AiContentTypeGraphicAnalysis:
            return LocalizedString(@"ai_education_tab_analysis");
    }
    return @"";
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
 * 按当前宽度构建图解分析列表的头部卡片。
 * tableHeaderView 必须带显式 frame，而本视图的宽度由容器挂载后才确定，
 * 因此头部只能在首次布局时构建，并在宽度变化（横竖屏形态不同）时按新宽度重建。
 */
- (void)refreshGraphicHeaderForWidth:(CGFloat)width {
    if (!self.viewModel.summaryInfo || width <= 0 || width == self.headerLayoutWidth) {
        return;
    }

    self.headerLayoutWidth = width;
    self.graphicTableView.tableHeaderView = [self buildSummaryHeaderViewForWidth:width];
}

// 图解分析头部：ParagraphSummary + Tags 徽标行 + MarkdownContent
- (nullable UIView *)buildSummaryHeaderViewForWidth:(CGFloat)width {
    SummaryInfo *summary = self.viewModel.summaryInfo;
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

    // 整体摘要文字：paragraphSummary 为空时跳过
    if (summary.paragraphSummary.length > 0) {
        UILabel *summaryLabel = [[UILabel alloc] init];
        summaryLabel.font = [UIFont systemFontOfSize:13];
        summaryLabel.textColor = AiEducationBodyTextColor();
        summaryLabel.numberOfLines = 0;
        summaryLabel.text = summary.paragraphSummary;
        CGSize summarySize = [summaryLabel sizeThatFits:CGSizeMake(innerWidth, CGFLOAT_MAX)];
        summaryLabel.frame = CGRectMake(cardPadding, cursorY, innerWidth, summarySize.height);
        [cardView addSubview:summaryLabel];
        cursorY += summarySize.height;
    }

    // 标签徽标行：圆角，水平排列超宽换行；无 mindMapItems 时不占位
    if (summary.mindMapItems.count > 0) {
        cursorY += 8;
        CGFloat tagX = cardPadding;
        CGFloat tagHeight = 20;
        CGFloat tagSpacing = 8;
        UIFont *tagFont = [UIFont systemFontOfSize:11];
        for (MindMapItem *item in summary.mindMapItems) {
            NSString *tag = item.title;
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

    cursorY += cardPadding;

    // 回填卡片 frame
    cardView.frame = CGRectMake(cardMargin, 12, cardWidth, cursorY);
    CGFloat headerHeight = cursorY + 12 + 8;

    // 在卡片下方渲染完整 Markdown 内容（markdownContent 为空时跳过）
    if (summary.markdownContent.length > 0) {
        CGFloat mdTop = headerHeight;
        NSAttributedString *renderedMarkdown =
            [[AiEducationMarkdownRenderer sharedRenderer] renderMarkdown:summary.markdownContent];
        UILabel *mdLabel = [[UILabel alloc] init];
        mdLabel.numberOfLines = 0;
        mdLabel.attributedText = renderedMarkdown;
        CGSize mdSize = [mdLabel sizeThatFits:CGSizeMake(innerWidth, CGFLOAT_MAX)];
        mdLabel.frame = CGRectMake(cardMargin + cardPadding, mdTop, innerWidth, mdSize.height);
        [header addSubview:mdLabel];
        headerHeight = mdTop + mdSize.height + 16;
    }

    // 回填头部 frame（tableHeaderView 需要显式 frame）
    header.frame = CGRectMake(0, 0, width, headerHeight);
    return header;
}

#pragma mark - Private Methods - Layout

// 标题与 Tab 顺次排布，列表控件占据剩余区域（自身已铺满外部容器）
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
    self.textAnalysisTableView.frame = listFrame;
    self.graphicTableView.frame = listFrame;
}

#pragma mark - Private Methods - Actions

// Tab 切换
- (void)onTabChanged:(UISegmentedControl *)control {
    [self switchToTab:control.selectedSegmentIndex];
}

// 切换显示对应内容视图
- (void)switchToTab:(NSInteger)index {
    AiContentType type = (index == 0) ? self.tab0Type : self.tab1Type;
    self.activeType = type;

    self.chapterTableView.hidden = (type != AiContentTypeChaptersOnly);
    self.textAnalysisTableView.hidden = (type != AiContentTypeTextAnalysis);
    self.graphicTableView.hidden = (type != AiContentTypeGraphicAnalysis);
}

// 只刷新高亮变化的行
- (void)reloadRow:(NSInteger)oldRow newRow:(NSInteger)newRow inTableView:(UITableView *)tableView {
    if (!tableView.window || tableView.hidden) {
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
        return (NSInteger)self.viewModel.chapters.count;
    }
    if (tableView == self.textAnalysisTableView) {
        return (NSInteger)self.viewModel.knowledgeItems.count;
    }
    // GraphicAnalysis：内容全部位于 tableHeaderView，列表体无行
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.chapterTableView) {
        return [self chapterCellForTableView:tableView indexPath:indexPath];
    }
    if (tableView == self.textAnalysisTableView) {
        return [self textAnalysisCellForTableView:tableView indexPath:indexPath];
    }
    // GraphicAnalysis 始终 0 行，不会到达此处
    return [[UITableViewCell alloc] init];
}

// 章节 cell 绑定
- (UITableViewCell *)chapterCellForTableView:(UITableView *)tableView
                                   indexPath:(NSIndexPath *)indexPath {
    AiEducationChapterCell *cell =
        [tableView dequeueReusableCellWithIdentifier:kChapterCellIdentifier
                                        forIndexPath:indexPath];
    ChapterInfo *chapter = self.viewModel.chapters[(NSUInteger)indexPath.row];
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

// 文字解析 cell 绑定
- (UITableViewCell *)textAnalysisCellForTableView:(UITableView *)tableView
                                        indexPath:(NSIndexPath *)indexPath {
    AiEducationTextAnalysisCell *cell =
        [tableView dequeueReusableCellWithIdentifier:kTextAnalysisCellIdentifier
                                        forIndexPath:indexPath];
    KnowledgeInfo *item = self.viewModel.knowledgeItems[(NSUInteger)indexPath.row];

    cell.chapterTitleLabel.text = item.title;
    cell.timeBadgeLabel.text = [NSString stringWithFormat:@" %@ ",
                                [FormatUtil formatTime:item.startMs]];

    // 高亮状态
    BOOL highlighted = indexPath.row == self.currentChapterIndex;
    cell.chapterTitleLabel.textColor = highlighted
        ? AiEducationHighlightRedColor()
        : AiEducationTextPrimaryColor();
    cell.cardContainer.backgroundColor = highlighted
        ? AiEducationCardBgHighlightColor()
        : AiEducationSummaryBgColor();

    // 渲染预组装的 Markdown 内容
    if (item.contentMarkdown.length > 0) {
        cell.contentLabel.attributedText =
            [[AiEducationMarkdownRenderer sharedRenderer] renderMarkdown:item.contentMarkdown];
    } else {
        cell.contentLabel.attributedText = nil;
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.chapterTableView) {
        ChapterInfo *chapter = self.viewModel.chapters[(NSUInteger)indexPath.row];
        if (self.onChapterSelected) {
            self.onChapterSelected(chapter.startMs);
        }
    } else if (tableView == self.textAnalysisTableView) {
        KnowledgeInfo *item = self.viewModel.knowledgeItems[(NSUInteger)indexPath.row];
        if (self.onChapterSelected) {
            self.onChapterSelected(item.startMs);
        }
    }
}

@end
