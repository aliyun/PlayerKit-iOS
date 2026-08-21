//
//  SceneLiveViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SceneLiveViewController.h"
#import "AliPlayerView.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "VideoSource.h"
#import "SceneConstants.h"
#import "SlotManager.h"
#import "SlotElements.h"
#import "SlotType.h"
#import "UserDefaultsManager.h"
#import "LinkConstants.h"
#import "LinkViewController.h"

@interface SceneLiveViewController ()

@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *playerController;
@property (nonatomic, assign) BOOL isPlayerReady;

@end

@implementation SceneLiveViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setupPlayerKit];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.isPlayerReady) {
        // 通知播放器恢复播放（从后台或其他页面返回时继续播放）
        [self.playerController onResume];
    } else {
        [self tryStartPlayback];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    // 通知播放器暂停（进入后台或离开当前页面时暂停播放）
    [self.playerController onPause];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)dealloc {
    // 销毁播放器控制器，释放资源
    // 注意：VC 销毁时必须销毁控制器，避免内存泄露
    [self.playerController destroy];
}

#pragma mark - PlayerKit Methods

// 初始化 AliPlayerKit 播放组件
- (void)setupPlayerKit {
    // 1. 创建播放器组件视图
    self.playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.playerView];

    // 2. 创建播放器组件控制器
    self.playerController = [[AliPlayerController alloc] init];
}

// 尝试启动直播播放
- (void)tryStartPlayback {
    // 未配置地址时引导用户扫码配置
    NSString *liveUrl = [self getLiveUrl];
    if (!liveUrl || liveUrl.length == 0) {
        [self showScanDialog];
        return;
    }

    // 3. 配置播放器组件数据
    VideoSource *source = [VideoSource urlSourceWithUrl:liveUrl];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    model.sceneType = SceneTypeLive;

    // 4. 配置播放源并将控制器挂载到视图（挂载后自动开始播放）
    [self.playerController configure:model];
    [self.playerView attach:self.playerController];
    self.isPlayerReady = YES;
}

#pragma mark - Live Source Methods

/**
 * @brief 获取直播地址。
 *
 * @discussion Demo 演示：从 DemoSettings 中读取直播地址，如果没有设置则返回 nil。
 *
 *             集成 FAQ：
 *             请替换为您的直播源获取逻辑，例如：
 *             @code
 *             - (NSString *)getLiveUrl {
 *                 return @"您的直播地址";  // 或从您的业务接口获取
 *             }
 *             @endcode
 *
 * @return 直播地址，如果没有设置则返回 nil。
 */
- (nullable NSString *)getLiveUrl {
    NSString *savedUrl = [[UserDefaultsManager sharedInstance] stringForKey:LinkKeyVideoLiveURL];
    return (savedUrl.length > 0) ? savedUrl : nil;
}

/**
 * @brief 显示扫码提示对话框。
 *
 * @discussion 提示用户未设置直播地址，引导用户跳转到扫码页面进行配置。
 */
- (void)showScanDialog {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"直播地址"
                         message:@"未设置直播地址，请先扫码配置"
                  preferredStyle:UIAlertControllerStyleAlert];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction
        actionWithTitle:@"去扫码"
                  style:UIAlertActionStyleDefault
                handler:^(UIAlertAction *action) {
        [weakSelf navigateToLinkSettings];
    }]];

    [alert addAction:[UIAlertAction
        actionWithTitle:@"取消"
                  style:UIAlertActionStyleCancel
                handler:^(UIAlertAction *action) {
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)navigateToLinkSettings {
    LinkViewController *linkVC = [[LinkViewController alloc] init];
    linkVC.filterKeys = @[LinkKeyVideoLiveURL];
    [self.navigationController pushViewController:linkVC animated:YES];
}

@end
