//
//  SceneAiEducationViewController.m
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "SceneAiEducationViewController.h"
#import "AliPlayerView.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "VideoSource.h"
#import "ChapterInfo.h"
#import "SlotManager.h"
#import "CustomSlotType.h"
#import "ToastUtils.h"
#import "LocaleMacros.h"
#import "AiContentConstants.h"
#import "AiContentLoader.h"
#import "AiAnalysisResponse.h"
#import "AiContentAssembler.h"
#import "ChapterButtonSlot.h"
#import "ChapterContentPanelSlot.h"

// 章节按钮自定义插槽 key
static NSString * const kChapterButtonSlotKey = @"ai_education_chapter_button";
static const NSInteger kChapterButtonSlotOrder = 85;

// 章节内容面板自定义插槽 key
static NSString * const kChapterContentPanelSlotKey = @"ai_education_chapter_content_panel";
static const NSInteger kChapterContentPanelSlotOrder = 120;

// 播放凭证失败后延迟关闭页面的时间（秒），避免 Toast 未展示
static const NSTimeInterval kExitDelayOnAuthFailure = 1.5;

@interface SceneAiEducationViewController ()

@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *playerController;

// AI 内容加载器（dealloc 时必须 cancel）
@property (nonatomic, strong) AiContentLoader *contentLoader;

// 缓存的 AI 响应，供 UI 组件按需读取
@property (nonatomic, strong, nullable) AiAnalysisResponse *aiResponse;

// 章节按钮插槽（provider 创建后弱引用持有）
@property (nonatomic, weak, nullable) ChapterButtonSlot *chapterButtonSlot;

// 章节内容面板插槽（provider 创建后弱引用持有）
@property (nonatomic, weak, nullable) ChapterContentPanelSlot *chapterContentPanelSlot;

// 生效的媒资 ID
@property (nonatomic, copy) NSString *mediaId;

@end

@implementation SceneAiEducationViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self loadConfigurationAndStart];
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
    // 取消所有进行中的网络请求，避免回调访问已销毁对象
    [_contentLoader cancel];
    // 销毁播放器控制器，释放资源
    [_playerController destroy];
}

#pragma mark - PlayerKit Methods

// 请求播放凭证 → 请求 AI 内容 → 起播
- (void)loadConfigurationAndStart {
    self.mediaId = AiContentDefaultMediaId;
    self.contentLoader = [[AiContentLoader alloc] initWithBaseURL:AiContentAppServerBaseURL];

    __weak typeof(self) weakSelf = self;
    [self.contentLoader loadPlayAuthWithVideoId:self.mediaId
                                     completion:^(NSString * _Nullable playAuth) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (playAuth.length == 0) {
            // 播放凭证失败：Toast 提示后延迟关闭页面（避免黑屏卡死）
            [strongSelf handlePlayAuthFailure];
            return;
        }
        [strongSelf loadAiContentWithPlayAuth:playAuth];
    }];
}

// 请求 AI 内容：失败降级为无 AI 内容的普通播放
- (void)loadAiContentWithPlayAuth:(NSString *)playAuth {
    __weak typeof(self) weakSelf = self;
    [self.contentLoader loadAiAnalysisWithMediaId:self.mediaId
                                       completion:^(AiAnalysisResponse * _Nullable response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        // 判断是否有 AI 内容，chapter 和 summary 有其一即可
        BOOL hasContent = response.chapterResult || response.summaryResult;
        if (!hasContent) {
            // AI 内容失败：Toast 提示，仍用 playAuth 正常起播
            [ToastUtils showToast:LocalizedString(@"ai_education_error_ai_content_load_failed")
                 inViewController:strongSelf];
        }
        strongSelf.aiResponse = hasContent ? response : nil;
        [strongSelf setupPlayerKitWithPlayAuth:playAuth response:strongSelf.aiResponse];
    }];
}

// 初始化 AliPlayerKit 播放组件并起播
- (void)setupPlayerKitWithPlayAuth:(NSString *)playAuth
                          response:(nullable AiAnalysisResponse *)response {
    // 1. 创建播放器组件视图
    self.playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.playerView];

    // 可选：设置返回键回调（播放器内部返回按钮/手势触发时通知此处）
    __weak typeof(self) weakSelf = self;
    self.playerView.onBackPressed = ^{
        [weakSelf.navigationController popViewControllerAnimated:YES];
    };

    // 2. 创建播放器组件控制器
    self.playerController = [[AliPlayerController alloc] init];

    // 3. 配置播放器组件数据（场景类型 AI_VOD，注入章节列表）
    VideoSource *source = [VideoSource vidAuthSourceWithVid:self.mediaId
                                                   playAuth:playAuth];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    model.sceneType = SceneTypeAIVod;

    // 当 AI 分析结果中包含有效章节数据时，将章节列表注入播放器，用于展示章节入口及章节内容。
    NSArray<ChapterInfo *> *chapters = [AiContentAssembler buildChaptersFromResponse:response];
    if (response && chapters.count > 0) {
        model.chapters = chapters;
    }

    // 4. 注册章节入口按钮与章节内容面板两个自定义插槽
    [self registerChapterButtonSlot];
    [self registerChapterContentPanelSlot];

    // 5. 配置播放源并将控制器挂载到视图（挂载后自动开始播放）
    [self.playerController configure:model];
    [self.playerView attach:self.playerController];

    // 6. attach 后显式配置两个插槽的数据与回调（本 VC 作组合根，插槽之间互不感知）
    [self configureSlots];
}

#pragma mark - Private Methods - Slot

// 注册章节按钮自定义插槽类型与 Provider
- (void)registerChapterButtonSlot {
    CustomSlotType *slotType = [CustomSlotType typeWithKey:kChapterButtonSlotKey
                                                     order:kChapterButtonSlotOrder];
    __weak typeof(self) weakSelf = self;
    [self.playerView.slotManager registerCustomSlotType:slotType
                                               provider:^UIView<SlotProtocol> *(UIView *parentView) {
        ChapterButtonSlot *slot = [[ChapterButtonSlot alloc] initWithFrame:parentView.bounds];
        weakSelf.chapterButtonSlot = slot;
        return slot;
    }];
}

// 注册章节内容面板自定义插槽类型与 Provider（面板自身持有全部呈现逻辑）
- (void)registerChapterContentPanelSlot {
    CustomSlotType *slotType = [CustomSlotType typeWithKey:kChapterContentPanelSlotKey
                                                     order:kChapterContentPanelSlotOrder];
    __weak typeof(self) weakSelf = self;
    [self.playerView.slotManager registerCustomSlotType:slotType
                                               provider:^UIView<SlotProtocol> *(UIView *parentView) {
        ChapterContentPanelSlot *slot =
            [[ChapterContentPanelSlot alloc] initWithFrame:parentView.bounds];
        weakSelf.chapterContentPanelSlot = slot;
        return slot;
    }];
}

// attach 后配置两个插槽：按钮可用状态、面板内容，以及按钮点击到面板的接线
- (void)configureSlots {
    BOOL chapterAvailable = (self.aiResponse.chapterResult != nil || self.aiResponse.summaryResult != nil);
    [self.chapterButtonSlot updateChapterAvailable:chapterAvailable];

    // 将 AI 响应（章节 / 摘要）更新到 ChapterContentPanelSlot（章节内容面板插槽）
    [self.chapterContentPanelSlot updateAiContent:self.aiResponse];

    __weak typeof(self) weakSelf = self;
    // 点按钮切换面板显示
    self.chapterButtonSlot.onChapterButtonTapped = ^{
        ChapterContentPanelSlot *panelSlot = weakSelf.chapterContentPanelSlot;
        if (panelSlot.isPanelShowing) {
            [panelSlot hidePanel];
        } else {
            [panelSlot showPanel];
        }
    };
}

#pragma mark - Private Methods - Error Handling

// 播放凭证失败：Toast 提示后延迟关闭页面
- (void)handlePlayAuthFailure {
    [ToastUtils showToast:LocalizedString(@"ai_education_error_server_unreachable")
         inViewController:self];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(kExitDelayOnAuthFailure * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [weakSelf.navigationController popViewControllerAnimated:YES];
    });
}

@end
