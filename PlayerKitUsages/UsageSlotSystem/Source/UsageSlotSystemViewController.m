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
#import "FullscreenTransition.h"

// 示例全屏过渡：通过回调让宿主管理播放器外框。
@interface UsageSlotHostFullscreenTransition : NSObject <FullscreenTransition>

@property (nonatomic, readonly) BOOL isInFullscreen;

- (instancetype)initWithLayoutBlock:(void (^)(BOOL fullscreen))layoutBlock;

@end

@interface UsageSlotHostFullscreenTransition ()

@property (nonatomic, readwrite) BOOL isInFullscreen;
@property (nonatomic, copy) void (^layoutBlock)(BOOL fullscreen);

@end

@implementation UsageSlotHostFullscreenTransition

- (instancetype)initWithLayoutBlock:(void (^)(BOOL fullscreen))layoutBlock {
    self = [super init];
    if (self) {
        _layoutBlock = [layoutBlock copy];
    }
    return self;
}

- (void)enterFullscreenWithPlayerView:(AliPlayerView *)playerView
                             animated:(BOOL)animated
                           completion:(void (^ _Nullable)(void))completion {
    (void)playerView;
    (void)animated;
    [self applyFullscreen:YES completion:completion];
}

- (void)exitFullscreenWithPlayerView:(AliPlayerView *)playerView
                            animated:(BOOL)animated
                          completion:(void (^ _Nullable)(void))completion {
    (void)playerView;
    (void)animated;
    [self applyFullscreen:NO completion:completion];
}

- (void)applyFullscreen:(BOOL)fullscreen completion:(void (^ _Nullable)(void))completion {
    // 本示例忽略动画参数，同步完成宿主布局后再通知过渡完成。
    self.isInFullscreen = fullscreen;
    [UIView performWithoutAnimation:^{
        self.layoutBlock(self.isInFullscreen);
    }];
    if (completion) {
        completion();
    }
}

@end

// 布局常量
static const CGFloat kHorizontalPadding = 16.0;
static const CGFloat kSectionSpacing = 20.0;

@interface UsageSlotSystemViewController ()

@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *controller;
@property (nonatomic, strong) UIScrollView *mainScrollView;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UISwitch *hostFullscreenSwitch;
@property (nonatomic, strong) UILabel *hostFullscreenLabel;
@property (nonatomic, strong) UsageSlotHostFullscreenTransition *hostFullscreenTransition;

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
    // 播放器视图（置于顶部）
    self.playerView = [[AliPlayerView alloc] init];
    [self.view addSubview:self.playerView];

    self.mainScrollView = [[UIScrollView alloc] init];
    if (@available(iOS 11.0, *)) {
        self.mainScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:self.mainScrollView];

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
    [self.mainScrollView addSubview:self.infoLabel];

    self.hostFullscreenLabel = [[UILabel alloc] init];
    self.hostFullscreenLabel.text = @"宿主容器全屏（不切换窗口或方向）";
    self.hostFullscreenLabel.font = [UIFont systemFontOfSize:14.0];
    self.hostFullscreenLabel.textColor = [UIColor darkGrayColor];
    self.hostFullscreenLabel.numberOfLines = 0;
    [self.mainScrollView addSubview:self.hostFullscreenLabel];

    self.hostFullscreenSwitch = [[UISwitch alloc] init];
    // 初始不注入自定义过渡，保留 SDK 默认实现。
    self.hostFullscreenSwitch.on = NO;
    [self.hostFullscreenSwitch addTarget:self
                                 action:@selector(hostFullscreenSwitchChanged:)
                       forControlEvents:UIControlEventValueChanged];
    [self.mainScrollView addSubview:self.hostFullscreenSwitch];
}

- (void)hostFullscreenSwitchChanged:(UISwitch *)sender {
    // 仅在非全屏态替换过渡，避免丢失原实现的退出还原路径。
    if (self.playerView.fullscreenTransition.isInFullscreen) {
        sender.on = self.hostFullscreenTransition != nil;
        return;
    }

    if (sender.isOn) {
        __weak typeof(self) weakSelf = self;
        self.hostFullscreenTransition = [[UsageSlotHostFullscreenTransition alloc] initWithLayoutBlock:^(BOOL fullscreen) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            // 由过渡状态驱动宿主布局，避免重复维护全屏状态。
            strongSelf.mainScrollView.hidden = fullscreen;
            [strongSelf.view setNeedsLayout];
            [strongSelf.view layoutIfNeeded];
        }];
        // 注入 fullscreenTransition，将全屏外框布局交由宿主处理。
        self.playerView.fullscreenTransition = self.hostFullscreenTransition;
    } else {
        // nil 恢复 SDK 默认实现。
        self.playerView.fullscreenTransition = nil;
        self.hostFullscreenTransition = nil;
    }
    [self.view setNeedsLayout];
}

// 使用插槽系统初始化播放器
- (void)setupPlayer {
    // 1. 创建 AliPlayerController
    self.controller = [[AliPlayerController alloc] init];

    // 2. 创建 VideoSource 和 AliPlayerModel
    VideoSource *source = [VideoSource vidAuthSourceWithVid:[SceneConstants landscapeSampleVid]
                                                   playAuth:[SceneConstants landscapeSamplePlayAuth]];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];

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

    CGRect safeBounds = self.view.bounds;
    if (@available(iOS 11.0, *)) {
        safeBounds = UIEdgeInsetsInsetRect(safeBounds, self.view.safeAreaInsets);
    }
    CGFloat width = MAX(0, CGRectGetWidth(safeBounds));
    CGFloat availableHeight = MAX(0, CGRectGetHeight(safeBounds));
    CGFloat contentWidth = MAX(0, width - kHorizontalPadding * 2);

    // 宽矮窗口保留下方操作区，画面比例仍由播放器渲染模式控制。
    CGFloat playerHeight = MIN(width * 9.0 / 16.0, availableHeight * 0.5);
    CGRect embeddedPlayerFrame = CGRectMake(CGRectGetMinX(safeBounds), CGRectGetMinY(safeBounds),
                                            width, playerHeight);
    BOOL hostFullscreen = self.hostFullscreenTransition.isInFullscreen;
    if (self.playerView.superview == self.view) {
        // 自定义全屏仅铺满当前宿主容器，不迁移播放器视图，不改变宿主窗口或方向。
        self.playerView.frame = hostFullscreen ? self.view.bounds : embeddedPlayerFrame;
        if (hostFullscreen) {
            [self.view bringSubviewToFront:self.playerView];
        }
    }

    CGFloat scrollTop = CGRectGetMaxY(embeddedPlayerFrame);
    CGFloat scrollHeight = MAX(0, CGRectGetMaxY(safeBounds) - scrollTop);
    self.mainScrollView.frame = CGRectMake(CGRectGetMinX(safeBounds), scrollTop, width, scrollHeight);
    self.mainScrollView.hidden = hostFullscreen;

    // 说明与开关共用滚动区域，短高度窗口仍可访问完整内容。
    CGFloat infoTop = kSectionSpacing;
    CGFloat infoPadding = 12.0;
    CGSize infoSize = [self.infoLabel sizeThatFits:CGSizeMake(MAX(0, contentWidth - infoPadding * 2), CGFLOAT_MAX)];
    CGFloat infoHeight = infoSize.height + infoPadding * 2;
    self.infoLabel.frame = CGRectMake(kHorizontalPadding, infoTop, contentWidth, infoHeight);

    // 开关行按说明实际高度排列，全屏时整体隐藏滚动区域。
    CGSize switchSize = [self.hostFullscreenSwitch sizeThatFits:CGSizeZero];
    CGFloat labelWidth = MAX(0, contentWidth - switchSize.width - infoPadding);
    CGSize labelSize = [self.hostFullscreenLabel sizeThatFits:CGSizeMake(labelWidth, CGFLOAT_MAX)];
    CGFloat rowTop = CGRectGetMaxY(self.infoLabel.frame) + kSectionSpacing;
    CGFloat rowHeight = MAX(switchSize.height, labelSize.height);
    self.hostFullscreenLabel.frame = CGRectMake(kHorizontalPadding, rowTop + (rowHeight - labelSize.height) / 2.0,
                                               labelWidth, labelSize.height);
    self.hostFullscreenSwitch.frame = CGRectMake(MAX(kHorizontalPadding, width - kHorizontalPadding - switchSize.width),
                                                rowTop + (rowHeight - switchSize.height) / 2.0,
                                                switchSize.width, switchSize.height);
    self.mainScrollView.contentSize = CGSizeMake(width, rowTop + rowHeight + kSectionSpacing);
}

@end
