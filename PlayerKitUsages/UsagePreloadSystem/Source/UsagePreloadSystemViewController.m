//
//  UsagePreloadSystemViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsagePreloadSystemViewController.h"
#import "AliPlayerKit.h"
#import "AliPlayerView.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "VideoSource.h"
#import "PlayerPreloader.h"
#import "PlayerPreloadTask.h"
#import "PlayerPreloadConfig.h"
#import "PreloadDelegate.h"
#import "StrategyManager.h"
#import "FirstFrameStrategy.h"
#import "PlayerNotificationDelegate.h"
#import "SceneConstants.h"

typedef NS_ENUM(NSInteger, PageState) {
    PageStateIdle,
    PageStatePreload,
    PageStatePlaying,
};

static const CGFloat kHorizontalPadding = 16.0;
static const CGFloat kSectionSpacing = 16.0;
static const CGFloat kButtonHeight = 44.0;

@interface UsagePreloadSystemViewController () <PreloadDelegate, PlayerNotificationDelegate, FirstFrameStrategyDelegate>

@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *playerController;

@property (nonatomic, strong) UISwitch *preloadSwitch;
@property (nonatomic, strong) UILabel *switchLabel;
@property (nonatomic, strong) UIButton *actionButton;

@property (nonatomic, strong) UILabel *statusTitleLabel;
@property (nonatomic, strong) UIScrollView *statusScrollView;
@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, assign) PageState pageState;
@property (nonatomic, copy) NSString *preloadTaskId;
@property (nonatomic, assign) BOOL isPreloaded;
@property (nonatomic, assign) BOOL isPlayerAttached;

@end

@implementation UsagePreloadSystemViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"预加载";
    self.view.backgroundColor = [UIColor whiteColor];

    [self setupUI];
    [self clearCacheOnEntry];
    [self updatePageState:PageStateIdle];
}

- (void)dealloc {
    [_playerController removeNotificationDelegate:self];
    [_playerController destroy];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat width = self.view.bounds.size.width;
    CGFloat contentWidth = width - kHorizontalPadding * 2;
    CGFloat safeTop = 0;
    if (@available(iOS 11.0, *)) {
        safeTop = self.view.safeAreaInsets.top;
    }
    CGFloat top = safeTop;

    // Player view (16:9)
    CGFloat playerHeight = width * 9.0 / 16.0;
    self.playerView.frame = CGRectMake(0, top, width, playerHeight);
    top += playerHeight;

    top += kSectionSpacing;

    // Switch row
    CGSize switchSize = [self.preloadSwitch sizeThatFits:CGSizeZero];
    self.preloadSwitch.frame = CGRectMake(width - kHorizontalPadding - switchSize.width,
                                          top + (kButtonHeight - switchSize.height) / 2.0,
                                          switchSize.width, switchSize.height);
    self.switchLabel.frame = CGRectMake(kHorizontalPadding, top,
                                        contentWidth - switchSize.width - 8.0, kButtonHeight);
    top += kButtonHeight + 8.0;

    // Action button
    self.actionButton.frame = CGRectMake(kHorizontalPadding, top, contentWidth, kButtonHeight);
    top += kButtonHeight + kSectionSpacing;

    // Status title
    CGSize titleSize = [self.statusTitleLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.statusTitleLabel.frame = CGRectMake(kHorizontalPadding, top, contentWidth, titleSize.height);
    top += titleSize.height + 8.0;

    // Status scroll view (fill remaining space)
    CGFloat statusHeight = MAX(100, self.view.bounds.size.height - top - 8.0);
    self.statusScrollView.frame = CGRectMake(kHorizontalPadding, top, contentWidth, statusHeight);

    [self updateStatusLayout];
}

#pragma mark - PlayerKit Methods

- (void)attachPlayer {
    self.playerController = [[AliPlayerController alloc] init];
    
    // Register first-frame strategy with delegate
    FirstFrameStrategy *ffStrategy = [[FirstFrameStrategy alloc] init];
    ffStrategy.delegate = self;
    [self.playerController.strategyManager registerStrategy:ffStrategy];

    VideoSource *source = [VideoSource vidAuthSourceWithVid:[SceneConstants landscapeSampleVid]
                                                   playAuth:[SceneConstants landscapeSamplePlayAuth]];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    model.videoTitle = @"预加载示例演示";
    [self.playerController configure:model];

    // Subscribe to state changes
    [self.playerController addNotificationDelegate:self];

    [self.playerView attach:self.playerController];
    self.isPlayerAttached = YES;

    NSString *status = self.isPreloaded
        ? @"播放器已挂载（已预加载）"
        : @"播放器已挂载（未预加载）";
    [self appendStatus:status];
}

- (void)detachPlayer {
    if (!self.isPlayerAttached) {
        return;
    }

    [self.playerView detach];

    if (self.playerController) {
        [self.playerController removeNotificationDelegate:self];
        [self.playerController destroy];
        self.playerController = nil;
    }

    self.isPlayerAttached = NO;
    [self appendStatus:@"播放器已卸载"];
}

#pragma mark - Private Methods

- (void)setupUI {
    // Player view (16:9)
    self.playerView = [[AliPlayerView alloc] init];
    [self.view addSubview:self.playerView];

    // Preload switch row
    self.switchLabel = [[UILabel alloc] init];
    self.switchLabel.text = @"预加载开关";
    self.switchLabel.font = [UIFont systemFontOfSize:15.0];
    self.switchLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.switchLabel];

    self.preloadSwitch = [[UISwitch alloc] init];
    [self.preloadSwitch addTarget:self action:@selector(onPreloadSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.preloadSwitch];

    // Action button
    self.actionButton = [self createButtonWithTitle:@"播放" color:[UIColor systemBlueColor]];
    [self.actionButton addTarget:self action:@selector(onActionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.actionButton];

    // Status log area
    self.statusTitleLabel = [[UILabel alloc] init];
    self.statusTitleLabel.text = @"预加载状态";
    self.statusTitleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    self.statusTitleLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.statusTitleLabel];

    self.statusScrollView = [[UIScrollView alloc] init];
    self.statusScrollView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.statusScrollView.layer.cornerRadius = 8.0;
    self.statusScrollView.clipsToBounds = YES;
    [self.view addSubview:self.statusScrollView];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont fontWithName:@"Menlo" size:11.0];
    self.statusLabel.textColor = [UIColor darkGrayColor];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.text = @"";
    [self.statusScrollView addSubview:self.statusLabel];
}

- (void)updatePageState:(PageState)newState {
    self.pageState = newState;

    switch (newState) {
        case PageStateIdle:
        case PageStatePreload:
            self.preloadSwitch.enabled = YES;
            [self.actionButton setTitle:@"播放" forState:UIControlStateNormal];
            self.actionButton.backgroundColor = [UIColor systemBlueColor];
            break;
        case PageStatePlaying:
            self.preloadSwitch.enabled = NO;
            [self.actionButton setTitle:@"清除缓存" forState:UIControlStateNormal];
            self.actionButton.backgroundColor = [UIColor systemRedColor];
            break;
    }
}

- (void)startPreload {
    VideoSource *source = [VideoSource vidAuthSourceWithVid:[SceneConstants landscapeSampleVid]
                                                   playAuth:[SceneConstants landscapeSamplePlayAuth]];

    PlayerPreloadConfig *config = [[PlayerPreloadConfig alloc] init];
    PlayerPreloadTask *task = [[PlayerPreloadTask alloc] initWithVideoSource:source
                                                              preloadConfig:config];

    self.preloadTaskId = [[AliPlayerKit preloader] addTask:task delegate:self];
    [self appendStatus:[NSString stringWithFormat:@"预加载已启动: taskId=%@", self.preloadTaskId]];
}

- (void)cancelPreload {
    if (!self.preloadTaskId.length) {
        return;
    }

    [self appendStatus:[NSString stringWithFormat:@"正在取消预加载: taskId=%@", self.preloadTaskId]];
    [[AliPlayerKit preloader] cancelTask:self.preloadTaskId];

    self.preloadTaskId = nil;
    self.isPreloaded = NO;
}

- (void)clearCacheOnEntry {
    [AliPlayerKit clearCaches];
    [self appendStatus:@"缓存已清除"];
}

- (void)clearCache {
    if (self.isPlayerAttached) {
        [self detachPlayer];
    }

    [self cancelPreload];
    [AliPlayerKit clearCaches];

    BOOL wasPreloadEnabled = self.preloadSwitch.isOn;
    self.isPreloaded = NO;

    if (wasPreloadEnabled) {
        [self appendStatus:@"缓存已清除，正在重启预加载"];
        [self startPreload];
        [self updatePageState:PageStatePreload];
    } else {
        [self appendStatus:@"缓存已清除"];
        [self updatePageState:PageStateIdle];
    }
}

- (void)appendStatus:(NSString *)message {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm:ss.SSS";
    });

    NSString *time = [formatter stringFromDate:[NSDate date]];
    NSString *line = [NSString stringWithFormat:@"[%@] %@\n", time, message];
    NSString *current = self.statusLabel.text ?: @"";
    self.statusLabel.text = [current stringByAppendingString:line];
    [self updateStatusLayout];
}

- (void)updateStatusLayout {
    CGFloat padding = 8.0;
    CGFloat labelWidth = self.statusScrollView.bounds.size.width - padding * 2;
    if (labelWidth <= 0) {
        return;
    }
    CGSize labelSize = [self.statusLabel sizeThatFits:CGSizeMake(labelWidth, CGFLOAT_MAX)];
    self.statusLabel.frame = CGRectMake(padding, padding, labelWidth, labelSize.height);
    self.statusScrollView.contentSize = CGSizeMake(self.statusScrollView.bounds.size.width, labelSize.height + padding * 2);

    CGFloat offsetY = self.statusScrollView.contentSize.height - self.statusScrollView.bounds.size.height;
    if (offsetY > 0) {
        [self.statusScrollView setContentOffset:CGPointMake(0, offsetY) animated:YES];
    }
}

- (UIButton *)createButtonWithTitle:(NSString *)title color:(UIColor *)color {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.backgroundColor = color;
    button.layer.cornerRadius = 8.0;
    button.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
    return button;
}

#pragma mark - Button Actions

- (void)onPreloadSwitchChanged:(UISwitch *)sender {
    [self clearCache];

    if (!sender.isOn) {
        [self appendStatus:@"预加载已关闭"];
        return;
    }
}

- (void)onActionButtonTapped {
    switch (self.pageState) {
        case PageStateIdle:
        case PageStatePreload:
            if (!self.isPlayerAttached) {
                [self attachPlayer];
            }
            break;
        case PageStatePlaying:
            [self clearCache];
            break;
    }
}

#pragma mark - PreloadDelegate

- (void)preloadTaskDidComplete:(NSString *)taskId source:(VideoSource *)source {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self appendStatus:[NSString stringWithFormat:@"预加载完成: taskId=%@", taskId]];
        self.isPreloaded = YES;
    });
}

- (void)preloadTaskDidFail:(NSString *)taskId source:(VideoSource *)source error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self appendStatus:[NSString stringWithFormat:@"预加载失败: taskId=%@, error=%@",
                            taskId, error.localizedDescription]];
        self.isPreloaded = NO;
        self.preloadTaskId = nil;
        [self.preloadSwitch setOn:NO animated:YES];
        [self updatePageState:PageStateIdle];
    });
}

- (void)preloadTaskDidCancel:(NSString *)taskId source:(VideoSource *)source {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self appendStatus:[NSString stringWithFormat:@"预加载已取消: taskId=%@", taskId]];
        self.isPreloaded = NO;
        self.preloadTaskId = nil;
        [self.preloadSwitch setOn:NO animated:YES];
        [self updatePageState:PageStateIdle];
    });
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    if (state == PlayerStatePlaying) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updatePageState:PageStatePlaying];
        });
    }
}

#pragma mark - FirstFrameStrategyDelegate

- (void)firstFrameStrategy:(FirstFrameStrategy *)strategy
       didRenderFirstFrameWithPrepareTime:(NSInteger)prepareTimeMs
                               renderTime:(NSInteger)renderTimeMs
                                totalTime:(NSInteger)totalTimeMs {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf appendStatus:[NSString stringWithFormat:
            @"首帧耗时 - 总计: %ldms | 准备: %ldms | 渲染: %ldms",
            (long)totalTimeMs, (long)prepareTimeMs, (long)renderTimeMs]];
    });
}

@end
