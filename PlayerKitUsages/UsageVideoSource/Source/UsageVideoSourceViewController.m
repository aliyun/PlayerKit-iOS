//
//  UsageVideoSourceViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsageVideoSourceViewController.h"
#import "AliPlayerView.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "VideoSource.h"
#import "UserDefaultsManager.h"
#import "LinkConstants.h"
#import "LinkViewController.h"

/**
 * @brief 视频源类型选项。
 *
 * @discussion 对应 PlayerKit 的三种视频源接入方式。
 *
 * @see VideoSource
 * @see VideoSourceType
 */
typedef NS_ENUM(NSInteger, SourceOption) {
    /** URL 直接播放源 */
    SourceOptionURL = 0,
    /** VID + PlayAuth 播放凭证 */
    SourceOptionVidAuth,
    /** VID + STS 临时凭证 */
    SourceOptionVidSts,
};

static NSString * const kSourceTitles[] = {
    [SourceOptionURL]     = @"URL 视频源",
    [SourceOptionVidAuth] = @"VidAuth 视频源",
    [SourceOptionVidSts]  = @"VidSts 视频源",
};

static const NSInteger kSourceOptionCount = 3;

@interface UsageVideoSourceViewController ()

@property (nonatomic, strong) UIView *selectionContainer;
@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *playerController;

@end

@implementation UsageVideoSourceViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"视频源使用示例";
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupSelectionView];
    [self setupPlayerView];
}

- (void)dealloc {
    [_playerController destroy];
}

#pragma mark - UI Setup

- (void)setupSelectionView {
    self.selectionContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.selectionContainer];

    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.text =
        @"演示 PlayerKit 支持的三种视频源类型：\n\n"
        @"  \u2022 URL：通过直接 URL 播放，适用于公开视频\n"
        @"  \u2022 VidAuth：通过 VID + PlayAuth 播放（推荐）\n"
        @"  \u2022 VidSts：通过 VID + STS 临时凭证播放\n\n"
        @"选择视频源类型后，将从「设置」中读取对应参数。\n"
        @"若配置不完整，会引导前往配置页面。";
    descLabel.font = [UIFont systemFontOfSize:13.0];
    descLabel.textColor = [UIColor grayColor];
    descLabel.numberOfLines = 0;
    descLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.selectionContainer addSubview:descLabel];

    [NSLayoutConstraint activateConstraints:@[
        [descLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:100],
        [descLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [descLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
    ]];

    // 创建三个视频源按钮
    UIView *previousAnchor = descLabel;
    for (NSInteger i = 0; i < kSourceOptionCount; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setTitle:kSourceTitles[i] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:16.0];
        button.tag = i;
        button.layer.cornerRadius = 8.0;
        button.layer.borderWidth = 1.0;
        button.layer.borderColor = button.tintColor.CGColor;
        button.contentEdgeInsets = UIEdgeInsetsMake(12, 0, 12, 0);
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button addTarget:self action:@selector(sourceButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.selectionContainer addSubview:button];

        CGFloat topSpacing = (i == 0) ? 32 : 16;
        [NSLayoutConstraint activateConstraints:@[
            [button.topAnchor constraintEqualToAnchor:previousAnchor.bottomAnchor constant:topSpacing],
            [button.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
            [button.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        ]];
        previousAnchor = button;
    }
}

#pragma mark - PlayerKit Methods

- (void)setupPlayerView {
    self.playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
    self.playerView.hidden = YES;
    [self.view addSubview:self.playerView];

    self.playerController = [[AliPlayerController alloc] init];
}

- (void)playWithSource:(VideoSource *)source {
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    model.videoTitle = @"视频源使用示例";

    [self.playerController configure:model];
    [self.playerView attach:self.playerController];

    self.selectionContainer.hidden = YES;
    self.playerView.hidden = NO;
}

#pragma mark - Private Methods

// 根据选项类型创建视频源，从 UserDefaultsManager 读取已配置的参数
- (nullable VideoSource *)createVideoSource:(SourceOption)option {
    switch (option) {
        case SourceOptionURL: {
            NSString *url = [[UserDefaultsManager sharedInstance] stringForKey:LinkKeyVideoURL];
            if (url.length == 0) return nil;
            return [VideoSource urlSourceWithUrl:url];
        }
        case SourceOptionVidAuth: {
            NSString *vid = [[UserDefaultsManager sharedInstance] stringForKey:LinkKeyVideoVid];
            NSString *playAuth = [[UserDefaultsManager sharedInstance] stringForKey:LinkKeyVideoPlayAuth];
            if (vid.length == 0 || playAuth.length == 0) return nil;
            return [VideoSource vidAuthSourceWithVid:vid playAuth:playAuth];
        }
        case SourceOptionVidSts: {
            NSString *vid = [[UserDefaultsManager sharedInstance] stringForKey:LinkKeyVideoVidStsVid];
            NSString *akId = [[UserDefaultsManager sharedInstance] stringForKey:LinkKeyVideoVidStsAccessKeyId];
            NSString *akSecret = [[UserDefaultsManager sharedInstance] stringForKey:LinkKeyVideoVidStsAccessKeySecret];
            NSString *token = [[UserDefaultsManager sharedInstance] stringForKey:LinkKeyVideoVidStsSecurityToken];
            NSString *region = [[UserDefaultsManager sharedInstance] stringForKey:LinkKeyVideoVidStsRegion];
            if (vid.length == 0 || akId.length == 0 || akSecret.length == 0 || token.length == 0) return nil;
            return [VideoSource vidStsSourceWithVid:vid
                                        accessKeyId:akId
                                    accessKeySecret:akSecret
                                      securityToken:token
                                             region:region];
        }
    }
    return nil;
}

// 返回指定视频源类型对应的 LinkConstants key 列表，用于跳转配置页时过滤
- (NSArray<NSString *> *)filterKeysForOption:(SourceOption)option {
    switch (option) {
        case SourceOptionURL:
            return @[LinkKeyVideoURL];
        case SourceOptionVidAuth:
            return @[LinkKeyVideoVid, LinkKeyVideoPlayAuth];
        case SourceOptionVidSts:
            return @[
                LinkKeyVideoVidStsVid,
                LinkKeyVideoVidStsAccessKeyId,
                LinkKeyVideoVidStsAccessKeySecret,
                LinkKeyVideoVidStsSecurityToken,
                LinkKeyVideoVidStsRegion,
            ];
    }
    return @[];
}

- (void)checkAndPlay:(SourceOption)option {
    VideoSource *source = [self createVideoSource:option];
    if (!source || ![source isValid]) {
        [self showConfigDialogForOption:option];
        return;
    }
    [self playWithSource:source];
}

// 配置不完整时，弹窗引导用户跳转到配置页
- (void)showConfigDialogForOption:(SourceOption)option {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"视频源配置"
                         message:@"视频源配置不完整，请先前往设置页面配置对应参数。"
                  preferredStyle:UIAlertControllerStyleAlert];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction
        actionWithTitle:@"去配置"
                  style:UIAlertActionStyleDefault
                handler:^(UIAlertAction *action) {
        [weakSelf navigateToLinkSettingsForOption:option];
    }]];

    [alert addAction:[UIAlertAction
        actionWithTitle:@"取消"
                  style:UIAlertActionStyleCancel
                handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)navigateToLinkSettingsForOption:(SourceOption)option {
    LinkViewController *linkVC = [[LinkViewController alloc] init];
    linkVC.filterKeys = [self filterKeysForOption:option];
    [self.navigationController pushViewController:linkVC animated:YES];
}

#pragma mark - Button Actions

- (void)sourceButtonTapped:(UIButton *)sender {
    [self checkAndPlay:(SourceOption)sender.tag];
}

@end
