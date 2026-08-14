//
//  UsageNotificationSystemViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/19.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsageNotificationSystemViewController.h"
#import "AliPlayerView.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "VideoSource.h"
#import "PlayerNotificationDelegate.h"
#import "SceneConstants.h"

// 日志条目最大显示数量
static const NSUInteger kMaxLogEntries = 20;

// 布局常量
static const CGFloat kHorizontalPadding = 16.0;
static const CGFloat kSectionSpacing = 20.0;
static const CGFloat kButtonHeight = 44.0;
static const CGFloat kButtonSpacing = 10.0;

@interface UsageNotificationSystemViewController () <PlayerNotificationDelegate>

@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *controller;

@property (nonatomic, strong) UIScrollView *mainScrollView;

// 区域：信息
@property (nonatomic, strong) UILabel *descriptionLabel;

// 区域：控制按钮
@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UIButton *clearLogButton;

// 区域：日志输出
@property (nonatomic, strong) UILabel *logOutputTitleLabel;
@property (nonatomic, strong) UIScrollView *logScrollView;
@property (nonatomic, strong) UILabel *logOutputLabel;

// 数据
@property (nonatomic, strong) NSMutableArray<NSString *> *logEntries;
@property (nonatomic, assign) PlayerState playerState;

@end

@implementation UsageNotificationSystemViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"通知系统";
    self.view.backgroundColor = [UIColor whiteColor];
    self.logEntries = [NSMutableArray array];

    [self setupUI];
    [self setupPlayer];
}

- (void)dealloc {
    [_controller removeNotificationDelegate:self];
    [_controller destroy];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat width = self.view.bounds.size.width;
    CGFloat contentWidth = width - kHorizontalPadding * 2;

    // 播放器视图：16:9 比例置于顶部
    CGFloat safeTop = 0;
    if (@available(iOS 11.0, *)) {
        safeTop = self.view.safeAreaInsets.top;
    }
    CGFloat playerHeight = width * 9.0 / 16.0;
    self.playerView.frame = CGRectMake(0, safeTop, width, playerHeight);

    // 播放器下方的主滚动视图
    CGFloat scrollTop = CGRectGetMaxY(self.playerView.frame);
    CGFloat scrollHeight = self.view.bounds.size.height - scrollTop;
    self.mainScrollView.frame = CGRectMake(0, scrollTop, width, scrollHeight);

    CGFloat top = kSectionSpacing;

    // 描述
    CGSize descSize = [self.descriptionLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.descriptionLabel.frame = CGRectMake(kHorizontalPadding, top, contentWidth, descSize.height);
    top += descSize.height + kSectionSpacing;

    // 控制按钮（一行两列）
    CGFloat buttonSpacing = kButtonSpacing;
    CGFloat buttonWidth = (contentWidth - buttonSpacing) / 2.0;

    self.playPauseButton.frame = CGRectMake(kHorizontalPadding, top, buttonWidth, kButtonHeight);
    self.clearLogButton.frame = CGRectMake(kHorizontalPadding + buttonWidth + buttonSpacing, top, buttonWidth, kButtonHeight);
    top += kButtonHeight + kSectionSpacing;

    // 日志输出标题
    CGSize logTitleSize = [self.logOutputTitleLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.logOutputTitleLabel.frame = CGRectMake(kHorizontalPadding, top, contentWidth, logTitleSize.height);
    top += logTitleSize.height + 8.0;

    // 日志滚动视图
    CGFloat logScrollHeight = 200.0;
    self.logScrollView.frame = CGRectMake(kHorizontalPadding, top, contentWidth, logScrollHeight);
    top += logScrollHeight + kSectionSpacing;

    // 日志输出标签
    [self updateLogOutputLayout];

    // 设置内容大小
    self.mainScrollView.contentSize = CGSizeMake(width, top);
}

#pragma mark - PlayerKit Methods

// 初始化播放器并注册通知代理
- (void)setupPlayer {
    // 1. 创建 AliPlayerController
    self.controller = [[AliPlayerController alloc] init];

    // 2. 注册自身为通知代理
    [self.controller addNotificationDelegate:self];

    // 3. 创建 VideoSource 和 AliPlayerModel
    VideoSource *source = [VideoSource vidAuthSourceWithVid:[SceneConstants landscapeSampleVid]
                                                   playAuth:[SceneConstants landscapeSamplePlayAuth]];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];

    // 4. 使用 model 配置 controller
    [self.controller configure:model];

    // 5. 使用默认插槽配置挂载播放器视图
    [self.playerView attach:self.controller];

    [self appendLog:@"播放器已初始化，通知代理已注册"];
}

#pragma mark - Private Methods

// 创建所有 UI 元素
- (void)setupUI {
    // 播放器视图（16:9 比例，置于顶部）
    self.playerView = [[AliPlayerView alloc] init];
    [self.view addSubview:self.playerView];

    // 播放器下方的主滚动视图
    self.mainScrollView = [[UIScrollView alloc] init];
    [self.view addSubview:self.mainScrollView];

    // 区域：描述
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.text = @"演示如何注册 PlayerNotificationDelegate 观察者，接收播放状态变更、进度更新、错误事件等实时通知。";
    self.descriptionLabel.font = [UIFont systemFontOfSize:14.0];
    self.descriptionLabel.textColor = [UIColor grayColor];
    self.descriptionLabel.numberOfLines = 0;
    [self.mainScrollView addSubview:self.descriptionLabel];

    // 区域：控制按钮
    self.playPauseButton = [self createButtonWithTitle:@"播放"
                                                color:[UIColor systemGreenColor]
                                               action:@selector(onPlayPause)];
    [self.mainScrollView addSubview:self.playPauseButton];

    self.clearLogButton = [self createButtonWithTitle:@"清除日志"
                                                color:[UIColor systemGrayColor]
                                               action:@selector(onClearLog)];
    [self.mainScrollView addSubview:self.clearLogButton];

    // 区域：日志输出
    self.logOutputTitleLabel = [[UILabel alloc] init];
    self.logOutputTitleLabel.text = @"通知日志";
    self.logOutputTitleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    self.logOutputTitleLabel.textColor = [UIColor blackColor];
    [self.mainScrollView addSubview:self.logOutputTitleLabel];

    self.logScrollView = [[UIScrollView alloc] init];
    self.logScrollView.backgroundColor = [UIColor blackColor];
    self.logScrollView.layer.cornerRadius = 8.0;
    self.logScrollView.clipsToBounds = YES;
    [self.mainScrollView addSubview:self.logScrollView];

    self.logOutputLabel = [[UILabel alloc] init];
    self.logOutputLabel.font = [UIFont fontWithName:@"Menlo" size:11.0];
    self.logOutputLabel.textColor = [UIColor whiteColor];
    self.logOutputLabel.numberOfLines = 0;
    self.logOutputLabel.text = @"(暂无通知)";
    [self.logScrollView addSubview:self.logOutputLabel];
}

// 更新日志滚动视图中日志输出标签的布局
- (void)updateLogOutputLayout {
    CGFloat padding = 8.0;
    CGFloat labelWidth = self.logScrollView.bounds.size.width - padding * 2;
    if (labelWidth <= 0) return;

    CGSize labelSize = [self.logOutputLabel sizeThatFits:CGSizeMake(labelWidth, CGFLOAT_MAX)];
    self.logOutputLabel.frame = CGRectMake(padding, padding, labelWidth, labelSize.height);
    self.logScrollView.contentSize = CGSizeMake(self.logScrollView.bounds.size.width, labelSize.height + padding * 2);

    // 自动滚动到底部
    CGFloat offsetY = self.logScrollView.contentSize.height - self.logScrollView.bounds.size.height;
    if (offsetY > 0) {
        [self.logScrollView setContentOffset:CGPointMake(0, offsetY) animated:YES];
    }
}

// 创建样式化按钮
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

// 追加日志条目并刷新日志输出显示
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

    // 仅保留最近的条目（先进先出）
    while (self.logEntries.count > kMaxLogEntries) {
        [self.logEntries removeObjectAtIndex:0];
    }

    self.logOutputLabel.text = [self.logEntries componentsJoinedByString:@"\n"];
    [self updateLogOutputLayout];
}

#pragma mark - Button Actions

// 播放/暂停切换
- (void)onPlayPause {
    if (self.playerState == PlayerStatePlaying) {
        [self.controller pause];
        [self appendLog:@"Action: Pause"];
    } else {
        [self.controller play];
        [self appendLog:@"Action: Play"];
    }
}

// 清除通知日志
- (void)onClearLog {
    [self.logEntries removeAllObjects];
    self.logOutputLabel.text = @"(暂无通知)";
    [self updateLogOutputLayout];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    self.playerState = state;
    [self appendLog:[NSString stringWithFormat:@"State Changed: %ld", (long)state]];

    // 根据播放状态更新播放/暂停按钮标题及背景色
    if (state == PlayerStatePlaying) {
        [self.playPauseButton setTitle:@"暂停" forState:UIControlStateNormal];
        self.playPauseButton.backgroundColor = [UIColor systemOrangeColor];
    } else {
        [self.playPauseButton setTitle:@"播放" forState:UIControlStateNormal];
        self.playPauseButton.backgroundColor = [UIColor systemGreenColor];
    }
}

- (void)playerDidPreparedWithDuration:(NSInteger)duration {
    [self appendLog:[NSString stringWithFormat:@"Prepared, duration: %ld", (long)duration]];
}

- (void)playerDidRenderFirstFrame {
    [self appendLog:@"First Frame Rendered"];
}

- (void)playerDidCompletion {
    [self appendLog:@"Playback Completed"];
}

- (void)playerDidUpdateCurrentPosition:(NSInteger)position
                              duration:(NSInteger)duration
                      bufferedPosition:(NSInteger)bufferedPosition {
    [self appendLog:[NSString stringWithFormat:@"Progress: %ld/%ld (buffered: %ld)", (long)position, (long)duration, (long)bufferedPosition]];
}

- (void)playerDidEncounterError:(NSError *)error {
    [self appendLog:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
}

@end
