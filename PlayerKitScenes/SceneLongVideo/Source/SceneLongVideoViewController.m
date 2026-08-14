//
//  SceneLongVideoViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SceneLongVideoViewController.h"
#import "AliPlayerView.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "VideoSource.h"
#import "SceneConstants.h"

@interface SceneLongVideoViewController ()

@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *playerController;

@end

@implementation SceneLongVideoViewController

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
    // 通知播放器恢复播放（从后台或其他页面返回时继续播放）
    [self.playerController onResume];
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

    // 可选：设置返回键回调（播放器内部返回按钮/手势触发时通知此处）
    __weak typeof(self) weakSelf = self;
    self.playerView.onBackPressed = ^{
        [weakSelf showExitConfirmation];
    };

    // 2. 创建播放器组件控制器
    self.playerController = [[AliPlayerController alloc] init];

    // 3. 配置播放器组件数据
    VideoSource *source = [VideoSource vidAuthSourceWithVid:[SceneConstants landscapeSampleVid]
                                                   playAuth:[SceneConstants landscapeSamplePlayAuth]];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];

    // 4. 配置播放源并将控制器挂载到视图（挂载后自动开始播放）
    [self.playerController configure:model];
    [self.playerView attach:self.playerController];
}

#pragma mark - Private Methods

// 弹窗确认是否退出当前页面
- (void)showExitConfirmation {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                   message:@"确定要退出播放吗？"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"退出" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
