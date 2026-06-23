//
//  MediaPlayer.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MirrorMode.h"
#import "ScaleMode.h"
#import "RotateMode.h"

@class AliPlayerModel;
@class TrackQuality;
@protocol MediaPlayer;
@class PlayerStateStore;
@class PlayerNotificationDispatcher;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器状态枚举。
 *
 * @discussion 定义播放器生命周期中的各种状态。
 *             状态流转：Idle -> Preparing -> Prepared -> Playing <-> Paused -> Stopped。
 *             Error 状态可从任何状态进入。
 *             Stopped 状态表示播放器已停止，需重新 prepare 才能继续播放。
 */
typedef NS_ENUM(NSInteger, PlayerState) {
    /**
     * 空闲状态
     * 初始化完成但未加载任何资源
     */
    PlayerStateIdle = 0,

    /**
     * 准备中
     * 正在异步加载视频资源和元数据
     */
    PlayerStatePreparing,

    /**
     * 已准备就绪
     * 资源加载完成，可以开始播放
     */
    PlayerStatePrepared,

    /**
     * 播放中
     * 音频/视频正在渲染输出
     */
    PlayerStatePlaying,

    /**
     * 已暂停
     * 保留当前播放进度，可恢复播放
     */
    PlayerStatePaused,

    /**
     * 已完播
     * 播放到达媒体末尾，需调用 replay 才能重新播放
     */
    PlayerStateCompleted,

    /**
     * 已停止
     * 播放器已停止，需重新 prepare 才能继续播放
     */
    PlayerStateStopped,

    /**
     * 错误状态
     * 播放过程中发生不可恢复的错误
     */
    PlayerStateError
};

/**
 * @brief 媒体播放器抽象协议。
 *
 * @discussion 定义播放器的核心操作接口，包括播放控制、状态查询和视图获取。
 *             具体播放器实现（如 AliMediaPlayer）需遵循此协议。
 *
 *             标准调用流程：
 *             1. createPlayer（通过 PlayerFactory）
 *             2. setDataSource: 设置视频源
 *             3. prepare 异步加载资源
 *             4. start / pause / seekTo: 播放控制
 *             5. stop 停止播放
 *             6. destroy 释放资源
 *
 * @see AliMediaPlayer
 * @see PlayerFactory
 */
@protocol MediaPlayer <NSObject>

/** @brief 播放器实例唯一标识符，创建时自动分配，生命周期内不变。 */
@property (nonatomic, copy, readonly) NSString *playerId;

/** @brief 当前播放器状态。 */
@property (nonatomic, assign, readonly) PlayerState state;

/** @brief 当前播放位置，单位毫秒。 */
@property (nonatomic, assign, readonly) NSInteger currentPosition;

/** @brief 视频总时长，单位毫秒。 */
@property (nonatomic, assign, readonly) NSInteger duration;

/** @brief 当前播放速率，默认为 1.0（正常速度）。 */
@property (nonatomic, assign, readonly) float speed;

/** @brief 是否开启循环播放，默认为 NO。 */
@property (nonatomic, assign, readonly, getter=isLoop) BOOL loop;

/** @brief 是否静音，默认为 NO。 */
@property (nonatomic, assign, readonly, getter=isMuted) BOOL muted;

/** @brief 当前镜像模式，默认为 MirrorModeNone。 */
@property (nonatomic, assign, readonly) MirrorMode mirrorMode;

/** @brief 当前缩放模式，默认为 ScaleModeCenterCrop。 */
@property (nonatomic, assign, readonly) ScaleMode scaleMode;

/** @brief 当前旋转角度，默认为 RotateModeDegree0。 */
@property (nonatomic, assign, readonly) RotateMode rotateMode;

/** @brief 播放器渲染视图，用于显示视频画面。由外部创建并注入。 */
@property (nonatomic, strong, nullable) UIView *playerView;

/** @brief 事件通知分发器，播放器事件通过此对象直接派发给观察者。 */
@property (nonatomic, strong, nullable) PlayerNotificationDispatcher *notificationDispatcher;

/** @brief 与此播放器关联的状态存储。 */
@property (nonatomic, strong, readonly) PlayerStateStore *stateStore;

/**
 * @brief 设置播放数据源。
 *
 * @param model 包含视频源和播放配置的模型对象。
 *
 * @discussion 设置数据源后需调用 prepare 进行资源加载。
 *
 * @see prepare
 */
- (void)setDataSource:(AliPlayerModel *)model;

/**
 * @brief 准备播放器资源。
 *
 * @discussion 异步加载视频资源，准备完成后状态变为 PlayerStatePrepared。
 *             **前置条件**：必须先调用 setDataSource: 设置数据源。
 *
 * @see setDataSource:
 */
- (void)prepare;

/**
 * @brief 开始播放。
 *
 * @discussion **前置条件**：播放器状态为 Prepared 或 Paused。
 */
- (void)start;

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
 * @brief 设置播放速率。
 * @param speed 播放速率。1.0 为正常速度，0.5 为半速，2.0 为倍速。
 *              有效范围通常为 0.5 到 2.0。
 */
- (void)setSpeed:(float)speed;

/**
 * @brief 启用或禁用循环播放。
 * @param loop YES 启用循环播放，NO 禁用。
 */
- (void)setLoop:(BOOL)loop;

/**
 * @brief 设置播放器静音或取消静音。
 * @param muted YES 静音，NO 取消静音。
 */
- (void)setMuted:(BOOL)muted;

/**
 * @brief 设置镜像模式。
 * @param mirrorMode 镜像模式。
 */
- (void)setMirrorMode:(MirrorMode)mirrorMode;

/**
 * @brief 设置缩放模式。
 * @param scaleMode 缩放模式。
 */
- (void)setScaleMode:(ScaleMode)scaleMode;

/**
 * @brief 设置旋转角度。
 * @param rotateMode 旋转角度。
 */
- (void)setRotateMode:(RotateMode)rotateMode;

/**
 * @brief 切换清晰度。
 * @param quality 目标清晰度。
 */
- (void)selectTrack:(TrackQuality *)quality;

/**
 * @brief 截取当前视频画面。
 *
 * @discussion 异步截取当前播放帧。截图完成后通过
 *             notificationDispatcher 的 dispatchDidCaptureScreenImage: 派发。
 */
- (void)snapshot;

/**
 * @brief 切换播放/暂停状态。
 *
 * @discussion 根据当前状态自动执行相应操作：
 *             - Playing → 暂停。
 *             - Paused / Prepared → 开始播放。
 *             - Stopped → 重播（等同于调用 replay）。
 *             - 其他状态 → 不执行任何操作。
 */
- (void)toggle;

/**
 * @brief 从头重新播放。
 *
 * @discussion 重新准备并开始播放当前数据源，不销毁播放器实例。
 */
- (void)replay;

/**
 * @brief 停止播放。
 *
 * @discussion 停止后需重新 prepare 才能再次播放。
 */
- (void)stop;

/**
 * @brief 销毁播放器，释放所有资源。
 *
 * @discussion 调用此方法后，播放器实例将无法继续使用。
 *             内部会先执行 stop 再释放底层资源。
 *
 * @warning 销毁后请勿再对播放器实例进行任何操作。
 *
 * @see PlayerFactory.destroyPlayer:
 */
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
