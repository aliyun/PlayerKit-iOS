//
//  ChapterChipView.m
//  AliPlayerKit
//
//  Created by keria on 2026/8/3.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "ChapterChipView.h"
#import "ChapterChipCell.h"
#import "ChapterInfo.h"
#import "FormatUtil.h"

#pragma mark - Constants

/// Chip 列表高度
static const CGFloat kChipViewHeight = 40.0;

/// Chip 间距
static const CGFloat kChipItemSpacing = 4.0;

/// Chip 水平内边距（与 ChapterChipCell 对齐）
static const CGFloat kChipPaddingH = 10.0;

/// Chip 最大宽度
static const CGFloat kChipMaxWidth = 160.0;

/// Chip 文字字号（用于计算 cell 宽度，需与 ChapterChipCell 中的字体保持同步）
static const CGFloat kChipFontSize = 10.0;

/// 列表水平内边距
static const CGFloat kChipContentInsetH = 12.0;

/// Cell 复用标识
static NSString *const kChipCellIdentifier = @"ChapterChipCell";

/// Chip 文案格式
static NSString *const kChipTextFormat = @"%@ %@";

@interface ChapterChipView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, copy) NSArray<ChapterInfo *> *chapters;
@property (nonatomic, assign) NSInteger currentIndex;

@end

@implementation ChapterChipView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentIndex = -1;
        [self setupCollectionView];
    }
    return self;
}

#pragma mark - Setup

- (void)setupCollectionView {
    self.flowLayout = [[UICollectionViewFlowLayout alloc] init];
    self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.flowLayout.minimumInteritemSpacing = kChipItemSpacing;
    self.flowLayout.minimumLineSpacing = kChipItemSpacing;

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:self.flowLayout];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.bounces = NO;
    self.collectionView.clipsToBounds = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, kChipContentInsetH, 0, kChipContentInsetH);
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[ChapterChipCell class]
            forCellWithReuseIdentifier:kChipCellIdentifier];
    [self addSubview:self.collectionView];
}

#pragma mark - Public Methods

- (void)setChapters:(NSArray<ChapterInfo *> *)chapters
           duration:(NSInteger)durationMs {
    (void)durationMs; // 预留参数
    _chapters = [chapters copy];
    _currentIndex = -1;
    [self.collectionView reloadData];
}

- (void)updateCurrentIndex:(NSInteger)index {
    if (index == self.currentIndex) return;

    NSInteger oldIndex = self.currentIndex;
    self.currentIndex = index;

    // 增量刷新 old + new 两项
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
    if (oldIndex >= 0 && oldIndex < (NSInteger)self.chapters.count) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:oldIndex inSection:0]];
    }
    if (index >= 0 && index < (NSInteger)self.chapters.count) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:index inSection:0]];
    }

    if (indexPaths.count > 0) {
        [self.collectionView reloadItemsAtIndexPaths:indexPaths];
    }
}

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index >= (NSInteger)self.chapters.count) return;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionLeft
                                        animated:animated];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return (NSInteger)self.chapters.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ChapterChipCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kChipCellIdentifier
                                                                      forIndexPath:indexPath];
    ChapterInfo *chapter = self.chapters[indexPath.item];
    NSString *timeText = [FormatUtil formatTime:chapter.startMs];
    NSString *chipText = [NSString stringWithFormat:kChipTextFormat, timeText, chapter.title];
    BOOL isCurrent = (indexPath.item == self.currentIndex);
    [cell configureWithText:chipText isCurrent:isCurrent];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < 0 || indexPath.item >= (NSInteger)self.chapters.count) return;
    ChapterInfo *chapter = self.chapters[indexPath.item];
    if (self.onChipSelected) {
        self.onChipSelected(chapter);
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    ChapterInfo *chapter = self.chapters[indexPath.item];
    NSString *timeText = [FormatUtil formatTime:chapter.startMs];
    NSString *chipText = [NSString stringWithFormat:kChipTextFormat, timeText, chapter.title];

    UIFont *font = [UIFont systemFontOfSize:kChipFontSize weight:UIFontWeightMedium];
    CGSize boundingSize = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
    CGFloat textWidth = [chipText boundingRectWithSize:boundingSize
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName: font}
                                               context:nil].size.width;
    CGFloat cellWidth = ceil(textWidth) + 2 * kChipPaddingH;
    cellWidth = MIN(cellWidth, kChipMaxWidth);
    return CGSizeMake(cellWidth, kChipViewHeight - 8);
}

#pragma mark - Intrinsic Content Size

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, kChipViewHeight);
}

@end
