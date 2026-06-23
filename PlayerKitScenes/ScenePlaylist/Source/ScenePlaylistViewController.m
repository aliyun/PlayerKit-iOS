//
//  ScenePlaylistViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "ScenePlaylistViewController.h"
#import "AliPlayerView.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "AliPlayerKit.h"
#import "VideoSource.h"
#import "PlayerNotificationDelegate.h"
#import "SingletonLifecycleStrategy.h"
#import "SceneConstants.h"
#import "SceneType.h"

@interface ScenePlaylistViewController () <PlayerNotificationDelegate>

/// 播放器视图（复用，整个生命周期只有一个实例）
@property (nonatomic, strong) AliPlayerView *playerView;

/// 当前播放的控制器
@property (nonatomic, strong, nullable) AliPlayerController *currentController;

/// 下一个预创建的控制器
@property (nonatomic, strong, nullable) AliPlayerController *nextController;

/// 播放器生命周期策略实例
@property (nonatomic, strong) id<PlayerLifecycleStrategy> lifecycleStrategy;

/// 视频源列表
@property (nonatomic, strong) NSArray<VideoSource *> *videoSources;

/// 当前播放的视频索引
@property (nonatomic, assign) NSInteger currentVideoIndex;

/// 列表播放提示标签
@property (nonatomic, strong) UILabel *hintLabel;

@end

@implementation ScenePlaylistViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    [self initVideoSources];
    [self setupUI];
    [self setupPlayerKit];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 通知播放器恢复播放（从后台或其他页面返回时继续播放）
    [self.currentController onResume];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    // 通知播放器暂停（进入后台或离开当前页面时暂停播放）
    [self.currentController onPause];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)dealloc {
    // 销毁播放器控制器，释放资源
    // 注意：VC 销毁时必须销毁控制器，避免内存泄露
    if (_currentController) {
        [_currentController removeNotificationDelegate:self];
        [_currentController destroy];
    }
    if (_nextController) {
        [_nextController destroy];
    }

    // 清理策略持有的播放器实例
    if (_lifecycleStrategy) {
        [_lifecycleStrategy clear];
    }

}

#pragma mark - Video Sources

// 初始化视频源列表
// 集成时请替换为您的视频源获取逻辑，例如从业务接口获取视频列表。
- (void)initVideoSources {
    self.videoSources = @[
        // 视频 1：横屏 VidAuth
        [VideoSource vidAuthSourceWithVid:[SceneConstants landscapeSampleVid]
                                 playAuth:[SceneConstants landscapeSamplePlayAuth]],
        // 视频 2：竖屏 VidAuth
        [VideoSource vidAuthSourceWithVid:[SceneConstants portraitSampleVid]
                                 playAuth:[SceneConstants portraitSamplePlayAuth]],
        // 视频 3：URL 直接播放
        [VideoSource urlSourceWithUrl:[SceneConstants sampleVideoURL]],
    ];
}

#pragma mark - UI Setup

- (void)setupUI {
    // 播放器视图（全屏）
    self.playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.playerView];

    // 列表播放提示标签
    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.text = @"Playlist: auto-advances to the next video on completion";
    self.hintLabel.font = [UIFont systemFontOfSize:14.0];
    self.hintLabel.textColor = [UIColor whiteColor];
    self.hintLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.hintLabel.numberOfLines = 0;
    [self.view addSubview:self.hintLabel];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.playerView.frame = self.view.bounds;

    CGFloat hintPadding = 16.0;
    CGFloat hintTop = 96.0;
    CGFloat hintMaxWidth = self.view.bounds.size.width - hintPadding * 4;
    CGSize hintSize = [self.hintLabel sizeThatFits:CGSizeMake(hintMaxWidth, CGFLOAT_MAX)];
    self.hintLabel.frame = CGRectMake(hintPadding,
                                      hintTop,
                                      hintSize.width + hintPadding * 2,
                                      hintSize.height + hintPadding);
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
}

#pragma mark - PlayerKit Methods

// 初始化 AliPlayerKit 播放组件
- (void)setupPlayerKit {
    // 初始化播放器生命周期策略
    // 当前示例使用 SingletonLifecycleStrategy，在应用进程内全局复用同一个 Player 实例。
    // 在该策略下，Player 实例不会随着页面退出而销毁，而是继续保留在内存中，
    // 供后续页面或场景复用，从而避免频繁创建和销毁 Player 实例带来的性能开销。
    // 注意：这只是一个示例。在实际业务中，可结合具体需求选择合适的生命周期策略。
    // 不同策略的使用方式，可参考 UsageLifecycleStrategy 模块。
    self.lifecycleStrategy = [SingletonLifecycleStrategy sharedInstance];

    // 创建并绑定当前控制器（第一个视频）
    self.currentVideoIndex = 0;
    [self createAndAttachCurrentController];

    // 预创建下一个控制器（如果存在下一个视频）
    [self preloadNextController];
}

// 创建并绑定当前控制器
- (void)createAndAttachCurrentController {
    if (self.currentVideoIndex < 0 || self.currentVideoIndex >= (NSInteger)self.videoSources.count) {
        return;
    }

    VideoSource *videoSource = self.videoSources[self.currentVideoIndex];

    // 1. 创建当前控制器
    self.currentController = [[AliPlayerController alloc] initWithLifecycleStrategy:self.lifecycleStrategy];

    // 2. 注册播放完成通知（用于触发自动播放下一个）
    [self.currentController addNotificationDelegate:self];

    // 3. 准备播放数据
    NSString *videoTitle = [NSString stringWithFormat:@"Playlist - Video %ld", (long)(self.currentVideoIndex + 1)];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
    model.videoTitle = videoTitle;

    // 4. 配置数据并绑定控制器到视图（挂载后自动开始播放）
    [self.currentController configure:model];
    [self.playerView attach:self.currentController];
}

// 预创建下一个控制器（但不配置数据、不绑定视图）
- (void)preloadNextController {
    NSInteger nextIndex = self.currentVideoIndex + 1;
    if (nextIndex < 0 || nextIndex >= (NSInteger)self.videoSources.count) {
        return;
    }

    // 创建下一个控制器（仅预创建，不配置数据）
    self.nextController = [[AliPlayerController alloc] initWithLifecycleStrategy:self.lifecycleStrategy];
    // 后续可在此处进行预加载、预渲染等优化操作
}

// 播放下一个视频
// 通过将 nextController 提升为 currentController 并预创建新的 nextController 实现连续播放。
- (void)playNextVideo {
    NSInteger nextIndex = self.currentVideoIndex + 1;
    if (nextIndex < 0 || nextIndex >= (NSInteger)self.videoSources.count) {
        return;
    }

    // 1. 销毁当前控制器
    if (self.currentController) {
        [self.currentController removeNotificationDelegate:self];
        [self.currentController destroy];
    }

    // 2. 将预创建的下一个控制器提升为当前控制器
    self.currentController = self.nextController;
    self.nextController = nil;

    // 3. 更新视频索引
    self.currentVideoIndex = nextIndex;

    // 4. 为当前控制器准备数据并绑定到视图
    VideoSource *videoSource = self.videoSources[self.currentVideoIndex];
    if (videoSource && self.currentController) {
        // 注册播放完成通知
        [self.currentController addNotificationDelegate:self];

        NSString *videoTitle = [NSString stringWithFormat:@"Playlist - Video %ld", (long)(self.currentVideoIndex + 1)];
        AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
        model.videoTitle = videoTitle;

        // 配置数据并绑定控制器到视图（挂载后自动开始播放）
        [self.currentController configure:model];
        [self.playerView attach:self.currentController];
    }

    // 5. 预创建下一个控制器（如果还有下一个视频）
    [self preloadNextController];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidCompletion {
    // 当前视频播放完成，自动播放下一个
    [self playNextVideo];
}

@end
