//
//  UsageLifecycleStrategyViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsageLifecycleStrategyViewController.h"
#import "AliPlayerView.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "AliPlayerKit.h"
#import "VideoSource.h"
#import "PlayerNotificationDelegate.h"
#import "DefaultLifecycleStrategy.h"
#import "ReusePoolLifecycleStrategy.h"
#import "SingletonLifecycleStrategy.h"
#import "IdScopedPoolLifecycleStrategy.h"
#import "SceneConstants.h"

// 策略枚举
typedef NS_ENUM(NSInteger, StrategyType) {
    StrategyTypeDefault = 0,
    StrategyTypeReusePool,
    StrategyTypeSingleton,
    StrategyTypeIdScopedPool,
};

// 演示用的复用池最大容量
static const NSInteger kDemoMaxPoolSize = 2;

// 日志条目最大显示数量
static const NSUInteger kMaxLogEntries = 50;

// 布局常量
static const CGFloat kHorizontalPadding = 16.0;
static const CGFloat kSectionSpacing = 20.0;
static const CGFloat kButtonHeight = 44.0;
static const CGFloat kButtonSpacing = 10.0;

@interface UsageLifecycleStrategyViewController () <PlayerNotificationDelegate>

// 播放器组件
@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong, nullable) AliPlayerController *controller;

// 当前策略实例
@property (nonatomic, strong, nullable) id<PlayerLifecycleStrategy> lifecycleStrategy;

// 视频源列表
@property (nonatomic, strong) NSArray<VideoSource *> *videoSources;

// 策略内连续播放计数（用于判断 NEW/REUSED/HIT）
@property (nonatomic, assign) NSInteger playCount;

// IdScopedPool 策略下，跟踪已使用过的 uniqueId（用于判断 HIT/NEW）
@property (nonatomic, strong) NSMutableSet<NSString *> *acquiredUniqueIds;

// UI 元素
@property (nonatomic, strong) UIScrollView *mainScrollView;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UISegmentedControl *strategySegment;
@property (nonatomic, strong) UILabel *videoSourceTitleLabel;
@property (nonatomic, strong) UIView *videoButtonContainer;
@property (nonatomic, strong) NSArray<UIButton *> *videoButtons;
@property (nonatomic, strong) UILabel *statusOverlay;
@property (nonatomic, strong) UILabel *logOutputTitleLabel;
@property (nonatomic, strong) UIScrollView *logScrollView;
@property (nonatomic, strong) UILabel *logOutputLabel;

// 日志数据
@property (nonatomic, strong) NSMutableArray<NSString *> *logEntries;

@end

@implementation UsageLifecycleStrategyViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"播放器生命周期策略";
    self.view.backgroundColor = [UIColor whiteColor];
    self.logEntries = [NSMutableArray array];
    self.acquiredUniqueIds = [NSMutableSet set];

    [self initVideoSources];
    [self setupUI];
    [self switchStrategy:StrategyTypeDefault];
}

- (void)dealloc {
    if (_controller) {
        [_controller removeNotificationDelegate:self];
        [_controller destroy];
    }
    if (_lifecycleStrategy) {
        [_lifecycleStrategy clear];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat width = self.view.bounds.size.width;
    CGFloat contentWidth = width - kHorizontalPadding * 2;

    // 播放器视图：固定高度，从顶部开始
    CGFloat safeTop = 0;
    if (@available(iOS 11.0, *)) {
        safeTop = self.view.safeAreaInsets.top;
    }
    CGFloat playerHeight = width * 9.0 / 16.0;
    self.playerView.frame = CGRectMake(0, safeTop, width, playerHeight);

    // 状态覆盖层：右上角
    CGFloat overlayPadding = 12.0;
    [self.statusOverlay sizeToFit];
    CGFloat overlayWidth = self.statusOverlay.bounds.size.width + 16.0;
    CGFloat overlayHeight = self.statusOverlay.bounds.size.height + 8.0;
    self.statusOverlay.frame = CGRectMake(width - overlayWidth - overlayPadding,
                                          overlayPadding,
                                          overlayWidth,
                                          overlayHeight);

    // 主滚动视图
    CGFloat scrollTop = CGRectGetMaxY(self.playerView.frame);
    CGFloat scrollHeight = self.view.bounds.size.height - scrollTop;
    self.mainScrollView.frame = CGRectMake(0, scrollTop, width, scrollHeight);

    CGFloat top = kSectionSpacing;

    // 描述
    CGSize descSize = [self.descriptionLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.descriptionLabel.frame = CGRectMake(kHorizontalPadding, top, contentWidth, descSize.height);
    top += descSize.height + kSectionSpacing;

    // 策略选择器
    self.strategySegment.frame = CGRectMake(kHorizontalPadding, top, contentWidth, kButtonHeight);
    top += kButtonHeight + kSectionSpacing;

    // 视频源标题
    CGSize videoTitleSize = [self.videoSourceTitleLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.videoSourceTitleLabel.frame = CGRectMake(kHorizontalPadding, top, contentWidth, videoTitleSize.height);
    top += videoTitleSize.height + 8.0;

    // 视频按钮（水平排列）
    CGFloat buttonWidth = (contentWidth - kButtonSpacing * 2) / 3.0;
    self.videoButtonContainer.frame = CGRectMake(kHorizontalPadding, top, contentWidth, kButtonHeight);
    for (NSInteger i = 0; i < self.videoButtons.count; i++) {
        self.videoButtons[i].frame = CGRectMake(i * (buttonWidth + kButtonSpacing), 0, buttonWidth, kButtonHeight);
    }
    top += kButtonHeight + kSectionSpacing;

    // 日志输出标题
    CGSize logTitleSize = [self.logOutputTitleLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.logOutputTitleLabel.frame = CGRectMake(kHorizontalPadding, top, contentWidth, logTitleSize.height);
    top += logTitleSize.height + 8.0;

    // 日志滚动视图
    CGFloat logScrollHeight = 200.0;
    self.logScrollView.frame = CGRectMake(kHorizontalPadding, top, contentWidth, logScrollHeight);
    top += logScrollHeight + kSectionSpacing;

    [self updateLogOutputLayout];
    self.mainScrollView.contentSize = CGSizeMake(width, top);
}

#pragma mark - PlayerKit Methods

// 切换生命周期管理策略
- (void)switchStrategy:(StrategyType)type {
    // 1. 清理当前播放环境
    [self cleanup];

    // 2. 根据选择创建新策略
    switch (type) {
        case StrategyTypeDefault: {
            self.lifecycleStrategy = [[DefaultLifecycleStrategy alloc] init];
            break;
        }
        case StrategyTypeReusePool: {
            self.lifecycleStrategy = [[ReusePoolLifecycleStrategy alloc] initWithMaxPoolSize:kDemoMaxPoolSize];
            break;
        }
        case StrategyTypeSingleton: {
            self.lifecycleStrategy = [SingletonLifecycleStrategy sharedInstance];
            break;
        }
        case StrategyTypeIdScopedPool: {
            self.lifecycleStrategy = [[IdScopedPoolLifecycleStrategy alloc] initWithMaxPoolSize:kDemoMaxPoolSize];
            break;
        }
    }

    // 3. 重置计数
    self.playCount = 0;
    [self.acquiredUniqueIds removeAllObjects];

    // 4. 更新 UI
    self.statusOverlay.text = @"READY";
    [self appendLog:@"------------------------------------------"];
    [self appendLog:[NSString stringWithFormat:@"Switch: Strategy -> %@",
                     NSStringFromClass([self.lifecycleStrategy class])]];
}

// 播放指定索引的视频
- (void)playVideo:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.videoSources.count) return;
    VideoSource *source = self.videoSources[index];

    // 推断策略行为：
    // - Default：每次创建新实例（recycle 时直接销毁）
    // - ReusePool：首次创建，后续复用（recycle 时归还池中）
    // - Singleton：首次创建，后续命中已有实例（recycle 时保持存活）
    // - IdScopedPool：同一 uniqueId 命中已有实例，不同 uniqueId 创建新实例
    NSString *status;
    if ([self.lifecycleStrategy isKindOfClass:[IdScopedPoolLifecycleStrategy class]]) {
        NSString *uniqueId = source.uniqueId;
        if (uniqueId && [self.acquiredUniqueIds containsObject:uniqueId]) {
            status = @"HIT";
        } else {
            status = @"NEW";
            if (uniqueId) {
                [self.acquiredUniqueIds addObject:uniqueId];
            }
        }
    } else if (self.playCount == 0) {
        status = @"NEW";
    } else if ([self.lifecycleStrategy isKindOfClass:[ReusePoolLifecycleStrategy class]]) {
        status = @"REUSED";
    } else if ([self.lifecycleStrategy isKindOfClass:[SingletonLifecycleStrategy class]]) {
        status = @"HIT";
    } else {
        status = @"NEW";
    }

    if (!self.controller) {
        // 首次播放：创建控制器
        self.controller = [[AliPlayerController alloc] initWithLifecycleStrategy:self.lifecycleStrategy];
        [self.controller addNotificationDelegate:self];
    }

    // 构造播放模型
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    model.videoTitle = [NSString stringWithFormat:@"播放器生命周期策略 - 视频 %ld", (long)(index + 1)];

    // 核心 API：configure 内部通过当前策略执行 recycle(旧) + acquire(新)
    [self.controller configure:model];
    [self.playerView attach:self.controller];

    self.playCount++;
    self.statusOverlay.text = status;
    [self appendLog:[NSString stringWithFormat:@"Play: Video %ld | Status: %@", (long)(index + 1), status]];
}

// 清理当前播放器和策略资源
- (void)cleanup {
    if (self.controller) {
        [self.controller removeNotificationDelegate:self];
        [self.controller destroy];
        self.controller = nil;
    }
    if (self.lifecycleStrategy) {
        [self.lifecycleStrategy clear];
    }
}

#pragma mark - Private Methods

// 初始化演示用视频源列表
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

- (void)setupUI {
    // 播放器视图（固定高度，置于顶部）
    self.playerView = [[AliPlayerView alloc] init];
    [self.view addSubview:self.playerView];

    // 状态覆盖层（显示 NEW/REUSED/HIT）
    self.statusOverlay = [[UILabel alloc] init];
    self.statusOverlay.font = [UIFont boldSystemFontOfSize:10.0];
    self.statusOverlay.textColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
    self.statusOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.statusOverlay.textAlignment = NSTextAlignmentCenter;
    self.statusOverlay.text = @"READY";
    [self.playerView addSubview:self.statusOverlay];

    // 播放器下方的主滚动视图
    self.mainScrollView = [[UIScrollView alloc] init];
    [self.view addSubview:self.mainScrollView];

    // 描述
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.text =
        @"演示如何通过 AliPlayerKit 自定义播放器生命周期策略，"
        @"实现播放器实例的精细化管理与复用。"
        @"如不提供，则使用默认策略。";
    self.descriptionLabel.font = [UIFont systemFontOfSize:14.0];
    self.descriptionLabel.textColor = [UIColor grayColor];
    self.descriptionLabel.numberOfLines = 0;
    [self.mainScrollView addSubview:self.descriptionLabel];

    // 策略选择器
    self.strategySegment = [[UISegmentedControl alloc] initWithItems:@[
        @"Default", @"ReusePool", @"Singleton", @"IdScoped"
    ]];
    self.strategySegment.selectedSegmentIndex = 0;
    [self.strategySegment addTarget:self
                             action:@selector(onStrategyChanged:)
                   forControlEvents:UIControlEventValueChanged];
    [self.mainScrollView addSubview:self.strategySegment];

    // 视频源切换标题
    self.videoSourceTitleLabel = [[UILabel alloc] init];
    self.videoSourceTitleLabel.text = @"视频源：";
    self.videoSourceTitleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    self.videoSourceTitleLabel.textColor = [UIColor blackColor];
    [self.mainScrollView addSubview:self.videoSourceTitleLabel];

    // 视频源按钮（水平排列）
    self.videoButtonContainer = [[UIView alloc] init];
    [self.mainScrollView addSubview:self.videoButtonContainer];

    NSArray<NSString *> *videoTitles = @[@"视频 1", @"视频 2", @"视频 3"];
    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    for (NSInteger i = 0; i < videoTitles.count; i++) {
        UIButton *button = [self createButtonWithTitle:videoTitles[i]
                                                 color:[UIColor systemBlueColor]
                                                action:@selector(onVideoButtonTapped:)];
        button.tag = i;
        [self.videoButtonContainer addSubview:button];
        [buttons addObject:button];
    }
    self.videoButtons = [buttons copy];

    // 日志输出标题
    self.logOutputTitleLabel = [[UILabel alloc] init];
    self.logOutputTitleLabel.text = @"策略执行日志";
    self.logOutputTitleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    self.logOutputTitleLabel.textColor = [UIColor blackColor];
    [self.mainScrollView addSubview:self.logOutputTitleLabel];

    // 日志滚动视图
    self.logScrollView = [[UIScrollView alloc] init];
    self.logScrollView.backgroundColor = [UIColor blackColor];
    self.logScrollView.layer.cornerRadius = 8.0;
    self.logScrollView.clipsToBounds = YES;
    [self.mainScrollView addSubview:self.logScrollView];

    self.logOutputLabel = [[UILabel alloc] init];
    self.logOutputLabel.font = [UIFont fontWithName:@"Menlo" size:11.0];
    self.logOutputLabel.textColor = [UIColor whiteColor];
    self.logOutputLabel.numberOfLines = 0;
    self.logOutputLabel.text = @"（选择视频源开始播放...）";
    [self.logScrollView addSubview:self.logOutputLabel];
}

- (void)appendLog:(NSString *)entry {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm:ss.SSS";
    });
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    NSString *logLine = [NSString stringWithFormat:@"[%@] %@", timestamp, entry];

    [self.logEntries addObject:logLine];
    while (self.logEntries.count > kMaxLogEntries) {
        [self.logEntries removeObjectAtIndex:0];
    }

    self.logOutputLabel.text = [self.logEntries componentsJoinedByString:@"\n"];
    [self updateLogOutputLayout];
}

- (void)updateLogOutputLayout {
    CGFloat padding = 8.0;
    CGFloat labelWidth = self.logScrollView.bounds.size.width - padding * 2;
    if (labelWidth <= 0) return;

    CGSize labelSize = [self.logOutputLabel sizeThatFits:CGSizeMake(labelWidth, CGFLOAT_MAX)];
    self.logOutputLabel.frame = CGRectMake(padding, padding, labelWidth, labelSize.height);
    self.logScrollView.contentSize = CGSizeMake(self.logScrollView.bounds.size.width, labelSize.height + padding * 2);

    CGFloat offsetY = self.logScrollView.contentSize.height - self.logScrollView.bounds.size.height;
    if (offsetY > 0) {
        [self.logScrollView setContentOffset:CGPointMake(0, offsetY) animated:YES];
    }
}

- (UIButton *)createButtonWithTitle:(NSString *)title
                              color:(UIColor *)color
                             action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.backgroundColor = color;
    button.layer.cornerRadius = 8.0;
    button.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

#pragma mark - Button Actions

- (void)onStrategyChanged:(UISegmentedControl *)sender {
    [self switchStrategy:(StrategyType)sender.selectedSegmentIndex];
}

- (void)onVideoButtonTapped:(UIButton *)sender {
    [self playVideo:sender.tag];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    NSString *stateName;
    switch (state) {
        case PlayerStateIdle:      stateName = @"Idle"; break;
        case PlayerStatePreparing: stateName = @"Preparing"; break;
        case PlayerStatePrepared:  stateName = @"Prepared"; break;
        case PlayerStatePlaying:   stateName = @"Playing"; break;
        case PlayerStatePaused:    stateName = @"Paused"; break;
        case PlayerStateCompleted: stateName = @"Completed"; break;
        case PlayerStateStopped:   stateName = @"Stopped"; break;
        case PlayerStateError:     stateName = @"Error"; break;
        default:                   stateName = @"Unknown"; break;
    }
    [self appendLog:[NSString stringWithFormat:@"State: %@", stateName]];
}

- (void)playerDidPreparedWithDuration:(NSInteger)duration {
    CGFloat seconds = duration / 1000.0;
    [self appendLog:[NSString stringWithFormat:@"Prepared, duration: %.1fs", seconds]];
}

- (void)playerDidRenderFirstFrame {
    [self appendLog:@"First frame rendered"];
}

- (void)playerDidCompletion {
    [self appendLog:@"Playback completed"];
}

- (void)playerDidEncounterError:(NSError *)error {
    [self appendLog:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
}

@end
