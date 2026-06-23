//
//  UsageLogSystemViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/16.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsageLogSystemViewController.h"
#import "FileLogObserver.h"
#import "Log.h"
#import "ToastUtils.h"
#import "UsageCommon.h"

// 日志条目最大显示数量
static const NSUInteger kMaxLogEntries = 10;

// 布局常量
static const CGFloat kHorizontalPadding = 16.0;
static const CGFloat kSectionSpacing = 20.0;
static const CGFloat kButtonHeight = 44.0;
static const CGFloat kButtonSpacing = 10.0;

@interface UsageLogSystemViewController () <LogObserver>

@property (nonatomic, strong) UIScrollView *mainScrollView;

// 区域 1：描述
@property (nonatomic, strong) UILabel *descriptionLabel;

// 区域 2：操作按钮
@property (nonatomic, strong) UIButton *registerButton;
@property (nonatomic, strong) UIButton *infoLogButton;
@property (nonatomic, strong) UIButton *warnLogButton;
@property (nonatomic, strong) UIButton *errorLogButton;

// 区域 3：日志输出
@property (nonatomic, strong) UILabel *logOutputTitleLabel;
@property (nonatomic, strong) UIScrollView *logScrollView;
@property (nonatomic, strong) UILabel *logOutputLabel;

// 数据
@property (nonatomic, strong) FileLogObserver *fileLogObserver;
@property (nonatomic, strong) NSMutableArray<NSString *> *logEntries;

@end

@implementation UsageLogSystemViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"日志系统";
    self.view.backgroundColor = [UIColor whiteColor];
    self.logEntries = [NSMutableArray array];
    self.fileLogObserver = [[FileLogObserver alloc] init];

    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 注册自身为 UI 日志观察者
    [[LogHub sharedHub] addObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 注销所有观察者以避免循环引用
    [[LogHub sharedHub] removeObserver:self];
    [[LogHub sharedHub] removeObserver:self.fileLogObserver];
}

- (void)dealloc {
    [[LogHub sharedHub] removeObserver:self];
    [[LogHub sharedHub] removeObserver:_fileLogObserver];
}

#pragma mark - Private Methods

// 创建所有 UI 元素
- (void)setupUI {
    // 主滚动视图
    self.mainScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.mainScrollView];

    // 区域 1：描述
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.text = @"演示如何集成日志监听器，并将日志输出到文件。";
    self.descriptionLabel.font = [UIFont systemFontOfSize:14.0];
    self.descriptionLabel.textColor = [UIColor grayColor];
    self.descriptionLabel.numberOfLines = 0;
    [self.mainScrollView addSubview:self.descriptionLabel];

    // 区域 2：操作按钮
    self.registerButton = [self createButtonWithTitle:@"注册文件监听"
                                               color:[UIColor systemBlueColor]
                                              action:@selector(onRegisterFileListener)];
    [self.mainScrollView addSubview:self.registerButton];

    self.infoLogButton = [self createButtonWithTitle:@"测试 INFO 日志"
                                               color:[UIColor systemGreenColor]
                                              action:@selector(onTestInfoLog)];
    [self.mainScrollView addSubview:self.infoLogButton];

    self.warnLogButton = [self createButtonWithTitle:@"测试 WARN 日志"
                                               color:[UIColor systemOrangeColor]
                                              action:@selector(onTestWarnLog)];
    [self.mainScrollView addSubview:self.warnLogButton];

    self.errorLogButton = [self createButtonWithTitle:@"测试 ERROR 日志"
                                                color:[UIColor systemRedColor]
                                               action:@selector(onTestErrorLog)];
    [self.mainScrollView addSubview:self.errorLogButton];

    // 区域 3：日志输出
    self.logOutputTitleLabel = [[UILabel alloc] init];
    self.logOutputTitleLabel.text = @"日志输出";
    self.logOutputTitleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    self.logOutputTitleLabel.textColor = [UIColor blackColor];
    [self.mainScrollView addSubview:self.logOutputTitleLabel];

    self.logScrollView = [[UIScrollView alloc] init];
    self.logScrollView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.logScrollView.layer.cornerRadius = 8.0;
    self.logScrollView.clipsToBounds = YES;
    [self.mainScrollView addSubview:self.logScrollView];

    self.logOutputLabel = [[UILabel alloc] init];
    self.logOutputLabel.font = [UIFont fontWithName:@"Menlo" size:11.0];
    self.logOutputLabel.textColor = [UIColor darkGrayColor];
    self.logOutputLabel.numberOfLines = 0;
    self.logOutputLabel.text = @"(暂无日志)";
    [self.logScrollView addSubview:self.logOutputLabel];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat width = self.view.bounds.size.width;
    CGFloat contentWidth = width - kHorizontalPadding * 2;
    CGFloat top = 0;

    // 主滚动视图
    self.mainScrollView.frame = self.view.bounds;

    top += kSectionSpacing;

    // 区域 1：描述
    CGSize descSize = [self.descriptionLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.descriptionLabel.frame = CGRectMake(kHorizontalPadding, top, contentWidth, descSize.height);
    top += descSize.height + kSectionSpacing;

    // 区域 2：按钮
    NSArray<UIButton *> *buttons = @[self.registerButton, self.infoLogButton, self.warnLogButton, self.errorLogButton];
    for (UIButton *button in buttons) {
        button.frame = CGRectMake(kHorizontalPadding, top, contentWidth, kButtonHeight);
        top += kButtonHeight + kButtonSpacing;
    }
    top += kSectionSpacing - kButtonSpacing;

    // 区域 3：日志输出标题
    CGSize logTitleSize = [self.logOutputTitleLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.logOutputTitleLabel.frame = CGRectMake(kHorizontalPadding, top, contentWidth, logTitleSize.height);
    top += logTitleSize.height + 8.0;

    // 日志滚动视图
    CGFloat logScrollHeight = 200.0;
    self.logScrollView.frame = CGRectMake(kHorizontalPadding, top, contentWidth, logScrollHeight);
    top += logScrollHeight + kSectionSpacing;

    // 滚动视图内的日志输出标签
    [self updateLogOutputLayout];

    // 设置内容大小
    self.mainScrollView.contentSize = CGSizeMake(width, top);
}

// 更新日志滚动视图中日志输出标签的布局
- (void)updateLogOutputLayout {
    CGFloat padding = 8.0;
    CGFloat labelWidth = self.logScrollView.bounds.size.width - padding * 2;
    if (labelWidth <= 0) {
        return;
    }
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
- (void)appendLogEntry:(NSString *)entry {
    [self.logEntries addObject:entry];

    // 仅保留最近的条目（先进先出）
    while (self.logEntries.count > kMaxLogEntries) {
        [self.logEntries removeObjectAtIndex:0];
    }

    self.logOutputLabel.text = [self.logEntries componentsJoinedByString:@"\n"];
    [self updateLogOutputLayout];
}

#pragma mark - Button Actions

// 注册文件日志观察者
- (void)onRegisterFileListener {
    [[LogHub sharedHub] addObserver:self.fileLogObserver];
    [ToastUtils showToast:@"文件监听注册成功" inViewController:self];
}

// 触发 INFO 级别的测试日志
- (void)onTestInfoLog {
    SLOGI(@"This is an info log for testing");
}

// 触发 WARN 级别的测试日志
- (void)onTestWarnLog {
    SLOGW(@"This is a warning log for testing");
}

// 触发 ERROR 级别的测试日志
- (void)onTestErrorLog {
    SLOGE(@"This is an error log for testing");
}

#pragma mark - LogObserver

- (void)onLog:(LogInfo *)logInfo {
    NSString *formatted = [logInfo formattedString];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self appendLogEntry:formatted];
    });
}

@end
