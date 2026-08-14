//
//  UsageLocaleSystemViewController.m
//  PlayerKitUsages
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsageLocaleSystemViewController.h"
#import "AliPlayerView.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "AliPlayerKit.h"
#import "VideoSource.h"
#import "LocaleManager.h"
#import "LocaleProvider.h"
#import "LocaleKeys.h"
#import "SceneConstants.h"

static const CGFloat kHorizontalPadding = 16.0;
static const CGFloat kSectionSpacing = 20.0;
static const CGFloat kButtonHeight = 44.0;
static const CGFloat kButtonSpacing = 10.0;

#pragma mark - DemoLocaleProvider

@interface DemoLocaleProvider : NSObject <LocaleProvider>
@end

@implementation DemoLocaleProvider

- (nullable NSString *)localizedStringForKey:(NSString *)key {
    return [NSString stringWithFormat:@"[CUSTOM] %@", key];
}

@end

#pragma mark - UsageLocaleSystemViewController

@interface UsageLocaleSystemViewController ()

@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *controller;

@property (nonatomic, strong) UIScrollView *mainScrollView;

@property (nonatomic, strong) UILabel *descriptionLabel;

@property (nonatomic, strong) UIButton *chineseButton;
@property (nonatomic, strong) UIButton *englishButton;
@property (nonatomic, strong) UIButton *systemButton;
@property (nonatomic, strong) UIButton *providerButton;

@property (nonatomic, strong) UILabel *statusTitleLabel;
@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, strong) DemoLocaleProvider *demoProvider;

@end

@implementation UsageLocaleSystemViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"多语言";
    self.view.backgroundColor = [UIColor whiteColor];

    [self setupUI];
    [self setupPlayer];
    [self updateStatusLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLocaleDidChange:)
                                                 name:LocaleDidChangeNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:LocaleDidChangeNotification
                                                  object:nil];
}

- (void)dealloc {
    [_controller destroy];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat width = self.view.bounds.size.width;
    CGFloat contentWidth = width - kHorizontalPadding * 2;

    // 播放器视图 16:9
    CGFloat safeTop = 0;
    if (@available(iOS 11.0, *)) {
        safeTop = self.view.safeAreaInsets.top;
    }
    CGFloat playerHeight = width * 9.0 / 16.0;
    self.playerView.frame = CGRectMake(0, safeTop, width, playerHeight);

    // 主滚动视图
    CGFloat scrollTop = CGRectGetMaxY(self.playerView.frame);
    CGFloat scrollHeight = self.view.bounds.size.height - scrollTop;
    self.mainScrollView.frame = CGRectMake(0, scrollTop, width, scrollHeight);

    CGFloat top = kSectionSpacing;

    // 描述
    CGSize descSize = [self.descriptionLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.descriptionLabel.frame = CGRectMake(kHorizontalPadding, top, contentWidth, descSize.height);
    top += descSize.height + kSectionSpacing;

    // 语言切换按钮（一行三列）
    CGFloat langButtonSpacing = kButtonSpacing;
    CGFloat langButtonWidth = (contentWidth - langButtonSpacing * 2) / 3.0;

    self.chineseButton.frame = CGRectMake(kHorizontalPadding, top, langButtonWidth, kButtonHeight);
    self.englishButton.frame = CGRectMake(kHorizontalPadding + langButtonWidth + langButtonSpacing, top, langButtonWidth, kButtonHeight);
    self.systemButton.frame = CGRectMake(kHorizontalPadding + (langButtonWidth + langButtonSpacing) * 2, top, langButtonWidth, kButtonHeight);
    top += kButtonHeight + kButtonSpacing;

    // Provider 按钮（独占一行）
    self.providerButton.frame = CGRectMake(kHorizontalPadding, top, contentWidth, kButtonHeight);
    top += kButtonHeight + kSectionSpacing;

    // 状态标题
    CGSize statusTitleSize = [self.statusTitleLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.statusTitleLabel.frame = CGRectMake(kHorizontalPadding, top, contentWidth, statusTitleSize.height);
    top += statusTitleSize.height + 8.0;

    // 状态标签
    CGFloat statusPadding = 12.0;
    CGSize statusSize = [self.statusLabel sizeThatFits:CGSizeMake(contentWidth - statusPadding * 2, CGFLOAT_MAX)];
    CGFloat statusHeight = MAX(statusSize.height + statusPadding * 2, 100.0);
    self.statusLabel.frame = CGRectMake(kHorizontalPadding, top, contentWidth, statusHeight);
    top += statusHeight + kSectionSpacing;

    self.mainScrollView.contentSize = CGSizeMake(width, top);
}

#pragma mark - PlayerKit Methods

- (void)setupPlayer {
    self.controller = [[AliPlayerController alloc] init];

    VideoSource *source = [VideoSource vidAuthSourceWithVid:[SceneConstants landscapeSampleVid]
                                                  playAuth:[SceneConstants landscapeSamplePlayAuth]];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];

    [self.controller configure:model];
    [self.playerView attach:self.controller];
}

#pragma mark - Private Methods

- (void)setupUI {
    // 播放器视图
    self.playerView = [[AliPlayerView alloc] init];
    [self.view addSubview:self.playerView];

    // 主滚动视图
    self.mainScrollView = [[UIScrollView alloc] init];
    [self.view addSubview:self.mainScrollView];

    // 描述
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.text = @"演示 PlayerKit 多语言系统：动态切换语言、注入自定义 Provider、观察播放器 UI 文案实时变化。";
    self.descriptionLabel.font = [UIFont systemFontOfSize:14.0];
    self.descriptionLabel.textColor = [UIColor grayColor];
    self.descriptionLabel.numberOfLines = 0;
    [self.mainScrollView addSubview:self.descriptionLabel];

    // 控制按钮
    self.chineseButton = [self createButtonWithTitle:@"中文"
                                              color:[UIColor systemBlueColor]
                                             action:@selector(onSwitchToChinese)];
    [self.mainScrollView addSubview:self.chineseButton];

    self.englishButton = [self createButtonWithTitle:@"English"
                                              color:[UIColor systemIndigoColor]
                                             action:@selector(onSwitchToEnglish)];
    [self.mainScrollView addSubview:self.englishButton];

    self.systemButton = [self createButtonWithTitle:@"跟随系统"
                                             color:[UIColor systemGreenColor]
                                            action:@selector(onFollowSystem)];
    [self.mainScrollView addSubview:self.systemButton];

    self.providerButton = [self createButtonWithTitle:@"切换自定义 Provider"
                                               color:[UIColor systemOrangeColor]
                                              action:@selector(onToggleProvider)];
    [self.mainScrollView addSubview:self.providerButton];

    // 状态显示
    self.statusTitleLabel = [[UILabel alloc] init];
    self.statusTitleLabel.text = @"当前状态";
    self.statusTitleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    self.statusTitleLabel.textColor = [UIColor blackColor];
    [self.mainScrollView addSubview:self.statusTitleLabel];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont fontWithName:@"Menlo" size:12.0];
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    self.statusLabel.layer.cornerRadius = 8.0;
    self.statusLabel.clipsToBounds = YES;
    [self.mainScrollView addSubview:self.statusLabel];
}

- (void)updateStatusLabel {
    LocaleManager *manager = [LocaleManager sharedManager];
    NSString *modeStr;
    switch (manager.localeMode) {
        case LocaleModeSystem: modeStr = @"系统"; break;
        case LocaleModeManual: modeStr = @"手动"; break;
        default: modeStr = @"Unknown"; break;
    }

    NSString *providerStr = manager.localeProvider ? @"已激活" : @"无";

    self.statusLabel.text = [NSString stringWithFormat:
        @"  Language: %@\n"
        @"  Mode: %@\n"
        @"  Provider: %@\n\n"
        @"  Sample strings:\n"
        @"  • Settings = \"%@\"\n"
        @"  • Speed = \"%@\"\n"
        @"  • Error = \"%@\"\n"
        @"  • Cancel = \"%@\"",
        manager.currentLanguageCode,
        modeStr,
        providerStr,
        [[LocaleManager sharedManager] localizedStringForKey:LocaleKeySettingMenuTitle],
        [[LocaleManager sharedManager] localizedStringForKey:LocaleKeySettingSpeed],
        [[LocaleManager sharedManager] localizedStringForKey:LocaleKeyPlayStateErrorMessageDefault],
        [[LocaleManager sharedManager] localizedStringForKey:LocaleKeySettingCancel]
    ];

    [self.view setNeedsLayout];
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

- (void)onSwitchToChinese {
    [AliPlayerKit setLanguageCode:@"zh-Hans"];
}

- (void)onSwitchToEnglish {
    [AliPlayerKit setLanguageCode:@"en"];
}

- (void)onFollowSystem {
    [AliPlayerKit resetLocaleToSystemLanguage];
}

- (void)onToggleProvider {
    if (self.demoProvider) {
        self.demoProvider = nil;
        [AliPlayerKit setLocaleProvider:nil];
    } else {
        self.demoProvider = [[DemoLocaleProvider alloc] init];
        [AliPlayerKit setLocaleProvider:self.demoProvider];
    }
}

#pragma mark - Notification Handlers

- (void)onLocaleDidChange:(NSNotification *)notification {
    [self updateStatusLabel];
}

@end
