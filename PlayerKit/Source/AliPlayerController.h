//
//  AliPlayerController.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MediaPlayer.h"
#import "MirrorMode.h"
#import "ScaleMode.h"
#import "RotateMode.h"
#import "PlayerNotificationDelegate.h"

@class TrackQuality;

@class AliPlayerModel;
@class PlayerStateStore;
@class StrategyManager;

@protocol PlayerLifecycleStrategy;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器控制器，作为播放操作的统一入口。
 *
 * @discussion 封装播放器的创建、配置和控制逻辑，提供简洁的播放控制 API。
 *             支持前后台切换时的状态保存与恢复。
 *
 * @see AliPlayerModel
 * @see MediaPlayer
 */
@interface AliPlayerController : NSObject

/** @brief 当前播放配置模型。 */
@property (nonatomic, strong, readonly, nullable) AliPlayerModel *playerModel;

/** @brief 当前播放器状态。 */
@property (nonatomic, assign, readonly) PlayerState playerState;

/** @brief 当前播放位置，单位毫秒。 */
@property (nonatomic, assign, readonly) NSInteger currentPosition;

/** @brief 视频总时长，单位毫秒。 */
@property (nonatomic, assign, readonly) NSInteger duration;

/** @brief 状态存储，提供对当前播放状态的只读访问。 */
@property (nonatomic, strong, readonly, nullable) PlayerStateStore *stateStore;

/**
 * @brief 策略管理器，负责协调绑定到此控制器的所有播放策略。
 *
 * @discussion 在控制器初始化时自动创建，并应用 StrategyRegistry 中注册的全局默认策略。
 *             可通过此属性注册或注销自定义策略。
 *
 * @see StrategyManager
 * @see StrategyRegistry
 */
@property (nonatomic, strong, readonly) StrategyManager *strategyManager;

/** @brief 当前使用的生命周期策略（只读）。 */
@property (nonatomic, strong, readonly) id<PlayerLifecycleStrategy> lifecycleStrategy;

/**
 * @brief 是否启用自动前后台生命周期管理，默认为 YES。
 *
 * @discussion 启用后，控制器自动监听 UIApplication 的前后台切换通知：
 *             - 进入后台时自动暂停播放（等同于调用 onPause）。
 *             - 回到前台时自动恢复播放（等同于调用 onResume）。
 *             设为 NO 时由调用方手动管理 onResume / onPause。
 *
 * @see onResume
 * @see onPause
 */
@property (nonatomic, assign) BOOL autoLifecycleManagement;

/**
 * @brief 使用指定生命周期策略初始化控制器。
 * @param strategy 遵循 PlayerLifecycleStrategy 协议的策略实例。
 * @discussion 控制器会自动调用 setupWithFactory: 注入默认工厂，调用方无需手动初始化策略。
 *             对齐 Android 的 AliPlayerController(context, lifecycleStrategy) 构造函数。
 */
- (instancetype)initWithLifecycleStrategy:(id<PlayerLifecycleStrategy>)strategy NS_DESIGNATED_INITIALIZER;

/**
 * @brief 配置播放器并准备播放。
 *
 * @param model 播放配置模型，包含视频源和播放参数。
 *
 * @discussion 内部通过工厂创建播放器实例，设置数据源并准备播放。
 *             如果 model.autoPlay 为 YES，准备完成后会自动开始播放。
 */
- (void)configure:(AliPlayerModel *)model;

/**
 * @brief 开始或恢复播放。
 */
- (void)play;

/**
 * @brief 暂停播放。
 */
- (void)pause;

/**
 * @brief 跳转到指定位置。
 *
 * @param position 目标位置，单位毫秒。
 */
- (void)seekTo:(NSInteger)position;

/**
 * @brief 设置播放速度。
 *
 * @param rate 播放速度，1.0 为正常速度，0.5 为半速，2.0 为倍速。
 */
- (void)setRate:(float)rate;

/**
 * @brief 设置是否循环播放。
 *
 * @param loop YES 为循环播放，NO 为单次播放。
 */
- (void)setLoop:(BOOL)loop;

/**
 * @brief 设置是否静音。
 *
 * @param muted YES 为静音，NO 为恢复音量。
 */
- (void)setMuted:(BOOL)muted;

/**
 * @brief 设置镜像模式。
 *
 * @param mirrorMode 镜像模式。
 */
- (void)setMirrorMode:(MirrorMode)mirrorMode;

/**
 * @brief 设置缩放模式。
 *
 * @param scaleMode 缩放模式。
 */
- (void)setScaleMode:(ScaleMode)scaleMode;

/**
 * @brief 设置旋转角度。
 *
 * @param rotateMode 旋转角度。
 */
- (void)setRotateMode:(RotateMode)rotateMode;

/**
 * @brief 设置控制栏可见性。
 *
 * @param visible YES 显示控制栏，NO 隐藏控制栏。
 *
 * @discussion 更新 PlayerStateStore.controlsVisible 并通过 PlayerNotificationDelegate
 *             的 playerDidChangeControlsVisible: 同步通知所有观察者。
 *             确保 TopBar 和 BottomBar 始终保持一致的显隐状态。
 */
- (void)setControlsVisible:(BOOL)visible;

/**
 * @brief 控制栏可见性锁定标志。
 *
 * @discussion 设为 YES 时，setControlsVisible:NO 请求会被忽略，
 *             控制栏持续保持可见状态。用于进度条拖动等需要
 *             操作栏始终显示的交互场景。
 */
@property (nonatomic, assign) BOOL controlsVisibilityLocked;

/**
 * @brief 设置全屏模式。
 *
 * @param fullscreen YES 进入全屏，NO 退出全屏。
 *
 * @discussion 默认带动画过渡，等同于调用 setFullscreen:animated: 并传入 YES。
 *
 * @see setFullscreen:animated:
 */
- (void)setFullscreen:(BOOL)fullscreen;

/**
 * @brief 设置全屏模式（支持动画控制）。
 *
 * @param fullscreen YES 进入全屏，NO 退出全屏。
 * @param animated   是否使用动画过渡。
 *
 * @discussion 全屏过渡由关联的 AliPlayerView 持有的 FullscreenTransition 实现。
 *             过渡完成后通过 PlayerNotificationDelegate 的
 *             playerDidChangeFullscreen: 回调通知观察者。
 */
- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated;

/**
 * @brief 切换清晰度。
 *
 * @param quality 目标清晰度。
 */
- (void)selectTrack:(TrackQuality *)quality;

/**
 * @brief 截取当前视频画面。
 *
 * @discussion 截取播放器渲染视图的当前帧内容。
 *             截图完成后通过 PlayerNotificationDelegate 的
 *             playerDidCompleteSnapshot: 回调返回结果。
 *             如果播放器未绑定渲染视图则不执行任何操作。
 */
- (void)snapshot;

/**
 * @brief 切换播放/暂停状态。
 *
 * @discussion 根据当前播放状态自动执行相应操作：
 *             - Playing → 暂停播放。
 *             - Paused / Prepared → 开始或恢复播放。
 *             - 其他状态 → 不执行任何操作。
 */
- (void)toggle;

/**
 * @brief 从头重新播放。
 *
 * @discussion 将播放位置重置为起始位置并开始播放。
 *             如果播放器处于已停止或错误状态，将使用当前模型重新配置。
 */
- (void)replay;

/**
 * @brief 停止播放。
 */
- (void)stop;

/**
 * @brief 恢复播放（从后台回到前台时调用）。
 *
 * @discussion 如果进入后台前正在播放，则恢复播放。
 *
 * @see onPause
 */
- (void)onResume;

/**
 * @brief 暂停播放（进入后台时调用）。
 *
 * @discussion 如果正在播放，则暂停并记录状态，以便 onResume 时恢复。
 *
 * @see onResume
 */
- (void)onPause;

/**
 * @brief 销毁播放器，释放所有资源。
 *
 * @discussion 调用后播放器不可再使用，需重新 configure 才能播放。
 */
- (void)destroy;

#pragma mark - Notification

/**
 * @brief 添加通知代理以接收播放器通知。
 *
 * @param delegate 遵循 PlayerNotificationDelegate 协议的代理对象。
 *                 以弱引用方式持有。
 *
 * @see PlayerNotificationDelegate
 * @see removeNotificationDelegate:
 */
- (void)addNotificationDelegate:(id<PlayerNotificationDelegate>)delegate;

/**
 * @brief 移除之前添加的通知代理。
 *
 * @param delegate 要移除的代理对象。
 *
 * @see addNotificationDelegate:
 */
- (void)removeNotificationDelegate:(id<PlayerNotificationDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
