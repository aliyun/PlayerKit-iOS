//
//  UsageSlotSystemViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsageSlotSystemViewController.h"
#import "AliPlayerView.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "VideoSource.h"
#import "SceneConstants.h"

// 布局常量
static const CGFloat kHorizontalPadding = 16.0;
static const CGFloat kSectionSpacing = 20.0;

@interface UsageSlotSystemViewController ()

@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *controller;
@property (nonatomic, strong) UILabel *infoLabel;

@end

@implementation UsageSlotSystemViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"插槽系统";
    self.view.backgroundColor = [UIColor whiteColor];

    [self setupUI];
    [self setupPlayer];
}

- (void)dealloc {
    [_playerView detach];
    [_controller destroy];
}

#pragma mark - Private Methods

// 创建所有 UI 元素
- (void)setupUI {
    // 播放器视图（16:9 比例，置于顶部）
    self.playerView = [[AliPlayerView alloc] init];
    [self.view addSubview:self.playerView];

    // 播放器视图下方的信息标签
    self.infoLabel = [[UILabel alloc] init];
    self.infoLabel.text = @"插槽系统使用示例\n\n"
        @"本示例演示如何使用插槽系统：\n"
        @"1. 使用 attach: 即可获得默认插槽配置\n"
        @"2. 插槽系统自动管理渲染视图的生命周期\n"
        @"3. 在 attach: 之前通过 playerView.slotManager 自定义配置";
    self.infoLabel.font = [UIFont systemFontOfSize:14.0];
    self.infoLabel.textColor = [UIColor darkGrayColor];
    self.infoLabel.numberOfLines = 0;
    self.infoLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.infoLabel.layer.cornerRadius = 8.0;
    self.infoLabel.clipsToBounds = YES;
    [self.view addSubview:self.infoLabel];
}

// 使用插槽系统初始化播放器
- (void)setupPlayer {
    // 1. 创建 AliPlayerController
    self.controller = [[AliPlayerController alloc] init];

    // 2. 创建 VideoSource 和 AliPlayerModel
    VideoSource *source = [VideoSource vidAuthSourceWithVid:[SceneConstants landscapeSampleVid]
                                                   playAuth:[SceneConstants landscapeSamplePlayAuth]];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    model.videoTitle = @"插槽系统演示";

    // 3. 使用 model 配置 controller
    [self.controller configure:model];

    // 4. 使用默认插槽配置（开箱即用）
    // 如需自定义，在 attach 前通过 slotManager 配置：
//    [self.playerView.slotManager registerSlotType:SlotTypeTopBar provider:^UIView<SlotProtocol> * _Nullable(UIView * _Nonnull parentView) {
//        // 返回 nil 表示移除该插槽；返回自定义 UIView<SlotProtocol> 实例可替换默认实现
//        return nil;
//    }];
//    [self.playerView.slotManager hideSlot:SlotTypeCover];
    [self.playerView attach:self.controller];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat width = self.view.bounds.size.width;
    CGFloat contentWidth = width - kHorizontalPadding * 2;

    // 计算安全区域顶部
    CGFloat safeTop = 0;
    if (@available(iOS 11.0, *)) {
        safeTop = self.view.safeAreaInsets.top;
    }

    // 播放器视图：16:9 比例置于顶部
    CGFloat playerHeight = width * 9.0 / 16.0;
    self.playerView.frame = CGRectMake(0, safeTop, width, playerHeight);

    // 播放器视图下方的信息标签
    CGFloat infoTop = CGRectGetMaxY(self.playerView.frame) + kSectionSpacing;
    CGFloat infoPadding = 12.0;
    CGSize infoSize = [self.infoLabel sizeThatFits:CGSizeMake(contentWidth - infoPadding * 2, CGFLOAT_MAX)];
    CGFloat infoHeight = infoSize.height + infoPadding * 2;
    self.infoLabel.frame = CGRectMake(kHorizontalPadding, infoTop, contentWidth, infoHeight);
}

@end
