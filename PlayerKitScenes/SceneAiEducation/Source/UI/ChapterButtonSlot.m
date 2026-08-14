//
//  ChapterButtonSlot.m
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "ChapterButtonSlot.h"
#import "PlayerNotificationDelegate.h"
#import "LocaleMacros.h"

@interface ChapterButtonSlot () <PlayerNotificationDelegate>

// 章节入口按钮
@property (nonatomic, strong) UIButton *chapterButton;

// 章节数据是否可用（由外部显式配置）
@property (nonatomic, assign) BOOL chapterAvailable;

// 控制栏当前是否可见（跟随播放器控制栏显隐）
@property (nonatomic, assign) BOOL controlsVisible;

@end

@implementation ChapterButtonSlot

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _chapterAvailable = NO;
        _controlsVisible = YES;
    }
    return self;
}

- (void)setupContentView {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:LocalizedString(@"ai_education_chapter_button")
            forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:13];
    button.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    button.layer.cornerRadius = 14;
    button.contentEdgeInsets = UIEdgeInsetsMake(4, 12, 4, 12);
    [button addTarget:self
               action:@selector(onButtonTapped)
     forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:button];
    self.chapterButton = button;

    // 布局在右上角区域（避开 TopBarSlot 高度，安全区避让由 BaseSlot 默认 safeAreaEdges 处理）
    [NSLayoutConstraint activateConstraints:@[
        [button.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
        [button.topAnchor constraintEqualToAnchor:self.topAnchor constant:56],
        [button.heightAnchor constraintEqualToConstant:28],
    ]];

    [self refreshVisibility];
}

#pragma mark - Public Methods

- (void)updateChapterAvailable:(BOOL)available {
    self.chapterAvailable = available;
    [self refreshVisibility];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeControlsVisible:(BOOL)visible {
    self.controlsVisible = visible;
    [self refreshVisibility];
}

#pragma mark - Private Methods

// 按钮点击：转发外部回调
- (void)onButtonTapped {
    if (self.onChapterButtonTapped) {
        self.onChapterButtonTapped();
    }
}

// 章节可用且控制栏可见时显示按钮
- (void)refreshVisibility {
    BOOL shouldShow = self.chapterAvailable && self.controlsVisible;
    self.chapterButton.hidden = !shouldShow;
}

@end
