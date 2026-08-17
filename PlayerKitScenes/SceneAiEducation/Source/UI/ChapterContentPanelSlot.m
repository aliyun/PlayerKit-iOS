//
//  ChapterContentPanelSlot.m
//  AliPlayerKit
//
//  Created by keria on 2026/8/13.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "ChapterContentPanelSlot.h"
#import "ChapterContentView.h"
#import "AiAnalysisResponse.h"
#import "AiContentAssembler.h"
#import "AiContentViewModel.h"
#import "AliPlayerController.h"
#import "PlayerViewState.h"
#import "PlayerNotificationDelegate.h"

// 横屏面板宽度
static const CGFloat kLandscapePanelWidth = 345.0;

// 竖屏面板高度占窗口高度的比例
static const CGFloat kPortraitPanelHeightRatio = 0.6;

// 竖屏面板顶部圆角
static const CGFloat kPortraitCornerRadius = 16.0;

@interface ChapterContentPanelSlot () <PlayerNotificationDelegate>

// 场景层推入的 AI 响应
@property (nonatomic, strong, nullable) AiAnalysisResponse *aiResponse;

// 面板内容视图（仅在面板显示期间存在）
@property (nonatomic, strong, nullable) ChapterContentView *panelContentView;

// 挂在窗口上的承载容器（每次显示时重建、隐藏后销毁）
@property (nonatomic, strong, nullable) UIView *popupContainer;

// 本次显示时捕获的全屏形态（不在退场时重新读取，避免方向判断与进场不一致）
@property (nonatomic, assign) BOOL isFullscreen;

@end

@implementation ChapterContentPanelSlot

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }

    return self;
}

- (void)onDetach {
    [self teardownCurrentViews];
    [super onDetach];
}

#pragma mark - Public

- (void)updateAiContent:(nullable AiAnalysisResponse *)response {
    if (self.aiResponse == response) {
        return;
    }

    self.aiResponse = response;

    // 内容视图按当前内容一次性构建，显示期间换内容只能先收起，下次打开时重建
    if (self.isPanelShowing) {
        [self hidePanel];
    }
}

#pragma mark - BasePanelSlot Overrides

/**
 * 竖屏时播放器只占据屏幕顶部一小块区域，底部弹窗必须覆盖整个屏幕，
 * 因此面板与蒙层统一承载在挂到窗口上的 popupContainer 内，而非插槽自身的视图层级。
 * 该容器每次显示时重建、每次隐藏后销毁（见 onPrepareForShow / onPanelHidden）。
 */
- (UIView *)panelHostView {
    return self.popupContainer ?: self;
}

- (nullable UIView *)panelView {
    return self.panelContentView;
}

/// 横屏为右侧抽屉，竖屏为底部弹窗
- (PanelSlideEdge)panelSlideEdge {
    return self.isFullscreen ? PanelSlideEdgeRight : PanelSlideEdgeBottom;
}

/// 面板 frame 由 mountPopupContainerInWindow: 手动设定，这里直接给出对应的确定尺寸
- (CGSize)panelSize {
    return [self panelSizeForHostBounds:self.popupContainer.bounds];
}

/// 动画期间容器已禁用交互，此处放开触摸以免阻塞其他手势
- (UIViewAnimationOptions)showAnimationOptions {
    return [super showAnimationOptions] | UIViewAnimationOptionAllowUserInteraction;
}

- (UIViewAnimationOptions)hideAnimationOptions {
    return [super hideAnimationOptions] | UIViewAnimationOptionAllowUserInteraction;
}

/// 按当前横竖屏形态重建容器与面板；无 AI 内容或无可用窗口时取消本次显示
- (BOOL)onPrepareForShow {
    // 形态可能已切换，先彻底清理上一次的残留视图
    [self teardownCurrentViews];

    if (!self.aiResponse) {
        return NO;
    }

    UIWindow *window = [self resolveWindow];

    if (!window) {
        return NO;
    }

    // 只在此处读取全屏态：退场动画沿用同一值，方向不会与进场相反
    self.isFullscreen = self.host.viewState.isFullscreen;
    [self buildPanelViews];
    [self mountPopupContainerInWindow:window];
    return YES;
}

- (void)onPanelShown {
    self.popupContainer.userInteractionEnabled = YES;
}

/// 退场动画期间先冻结交互，避免面板在滑出过程中被再次点击
- (void)onPerformHideAnimation {
    self.popupContainer.userInteractionEnabled = NO;
    [super onPerformHideAnimation];
}

- (void)onPanelHidden {
    [super onPanelHidden];
    [self teardownCurrentViews];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidUpdateCurrentPosition:(NSInteger)position
                              duration:(NSInteger)duration
                      bufferedPosition:(NSInteger)bufferedPosition {
    // 内容视图仅在面板显示期间存在，无需额外判断可见性
    [self.panelContentView updateCurrentPosition:position];
}

- (void)playerDidChangeFullscreen:(BOOL)isFullscreen {
    // 形态切换后窗口与面板尺寸均已失效，直接关闭（对齐 Android onConfigurationChanged）
    if (self.isPanelShowing) {
        [self hidePanel];
    }
}

#pragma mark - Private Methods - Panel Mounting

/// 优先取宿主视图所在窗口，其次退化到应用主窗口
- (nullable UIWindow *)resolveWindow {
    UIWindow *window = [self.host hostView].window;

    if (!window) {
        window = UIApplication.sharedApplication.keyWindow;
    }

    return window;
}

/// 建容器与面板内容视图，并接线章节 / 分段两个回调
- (void)buildPanelViews {
    // 蒙层由基类持有，并在显示时插入到 panelHostView（即 popupContainer）的最底层
    self.popupContainer = [[UIView alloc] init];
    self.popupContainer.backgroundColor = [UIColor clearColor];

    // 通过 Assembler 组装视图模型
    AiContentViewModel *viewModel = [AiContentAssembler buildViewModelFromResponse:self.aiResponse];

    ChapterContentView *contentView = [[ChapterContentView alloc] initWithViewModel:viewModel];
    __weak typeof(self) weakSelf = self;
    contentView.onChapterSelected = ^(NSInteger startMs) {
        // 点击章节：seek 到章节起点并关闭面板
        [weakSelf.host.controller seekTo:startMs];
        [weakSelf hidePanel];
    };
    self.panelContentView = contentView;

    contentView.clipsToBounds = YES;

    if (!self.isFullscreen) {
        // 竖屏底部弹窗只在顶部两角切圆角
        contentView.layer.cornerRadius = kPortraitCornerRadius;
        if (@available(iOS 11.0, *)) {
            contentView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        }
    }

    [self.popupContainer addSubview:contentView];
    // 显示瞬间即对齐当前进度的高亮，不必等下一次进度回调
    [contentView updateCurrentPosition:self.host.controller.currentPosition];
}

/**
 * 把承载容器铺满窗口并挂载，同时把面板摆到"已显示"的终态位置。
 * 隐藏态由基类通过 transform 平移到屏外，因此这里无需预置屏外 frame。
 */
- (void)mountPopupContainerInWindow:(UIWindow *)window {
    CGRect windowBounds = window.bounds;
    self.popupContainer.frame = windowBounds;
    // 进场动画结束后再放开交互（见 onPanelShown）
    self.popupContainer.userInteractionEnabled = NO;
    [window addSubview:self.popupContainer];

    CGSize panelSize = [self panelSizeForHostBounds:windowBounds];

    if (self.isFullscreen) {
        self.panelContentView.frame = CGRectMake(CGRectGetWidth(windowBounds) - panelSize.width, 0,
                                                panelSize.width, panelSize.height);
    } else {
        self.panelContentView.frame = CGRectMake(0, CGRectGetHeight(windowBounds) - panelSize.height,
                                                panelSize.width, panelSize.height);
    }
}

/// 横屏为定宽右侧抽屉，竖屏为按比例取高的底部弹窗
- (CGSize)panelSizeForHostBounds:(CGRect)hostBounds {
    if (self.isFullscreen) {
        return CGSizeMake(kLandscapePanelWidth, CGRectGetHeight(hostBounds));
    }

    return CGSizeMake(CGRectGetWidth(hostBounds),
                      CGRectGetHeight(hostBounds) * kPortraitPanelHeightRatio);
}

#pragma mark - Private Methods - Teardown

/// 销毁本次显示创建的容器与面板；重复调用是幂等的
- (void)teardownCurrentViews {
    // 强制取消任何正在进行的动画，防止动画 completion 回来后再次操作已被释放的视图引用
    if (self.popupContainer) {
        [self.popupContainer.layer removeAllAnimations];
        [self.popupContainer removeFromSuperview];
        self.popupContainer = nil;
    }

    if (self.panelContentView) {
        [self.panelContentView.layer removeAllAnimations];
        [self.panelContentView removeFromSuperview];
        // 面板的两个回调块随内容视图一并释放
        self.panelContentView = nil;
    }
}

@end
