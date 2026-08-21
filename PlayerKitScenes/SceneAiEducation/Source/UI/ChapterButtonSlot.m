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

// 从 SceneAiEducation 资源 bundle 加载图片
static UIImage *AiEducationImageNamed(NSString *name) {
    NSBundle *mainBundle = [NSBundle bundleForClass:[ChapterButtonSlot class]];
    NSURL *bundleURL = [mainBundle URLForResource:@"PlayerKitScenes_SceneAiEducation"
                                    withExtension:@"bundle"];
    NSBundle *resourceBundle = bundleURL ? [NSBundle bundleWithURL:bundleURL] : mainBundle;
    return [UIImage imageNamed:name
                      inBundle:resourceBundle
     compatibleWithTraitCollection:nil];
}

@interface ChapterButtonSlot () <PlayerNotificationDelegate>

// 章节入口按钮
@property (nonatomic, strong) UIButton *chapterButton;

// 章节数据是否可用（由外部显式配置）
@property (nonatomic, assign) BOOL chapterAvailable;

// 控制栏当前是否可见（跟随播放器控制栏显隐）
@property (nonatomic, assign) BOOL controlsVisible;

// 是否处于全屏/横屏模式（全屏时隐藏章节按钮）
@property (nonatomic, assign) BOOL isFullscreen;

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
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    // 从资源 bundle 加载章节图标
    UIImage *chapterIcon = AiEducationImageNamed(@"ai_education_chapter_icon");
    [button setImage:chapterIcon forState:UIControlStateNormal];
    button.contentMode = UIViewContentModeCenter;
    [button addTarget:self
               action:@selector(onButtonTapped)
     forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:button];
    self.chapterButton = button;

    // 布局在左下角，进度条上方
    [NSLayoutConstraint activateConstraints:@[
        [button.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
        [button.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-80],
        [button.widthAnchor constraintEqualToConstant:30],
        [button.heightAnchor constraintEqualToConstant:30],
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

- (void)playerDidChangeFullscreen:(BOOL)isFullscreen {
    self.isFullscreen = isFullscreen;
    [self refreshVisibility];
}

#pragma mark - Private Methods

// 按钮点击：转发外部回调
- (void)onButtonTapped {
    if (self.onChapterButtonTapped) {
        self.onChapterButtonTapped();
    }
}

// 章节可用、控制栏可见且非全屏时显示按钮
- (void)refreshVisibility {
    BOOL shouldShow = self.chapterAvailable && self.controlsVisible && !self.isFullscreen;
    self.chapterButton.hidden = !shouldShow;
}

@end
