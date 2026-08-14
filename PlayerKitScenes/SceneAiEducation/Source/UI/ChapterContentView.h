//
//  ChapterContentView.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AiVideoContent;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 章节 / AI 解析面板的内容视图。
 *
 * @discussion 展示 AI 内容理解结果，只负责内容渲染：
 *             - 有章节且有 AI 解析时顶部显示双 Tab（章节 / AI 解析），
 *               仅一类内容时不显示 Tab；
 *             - 章节列表项点击后通过 onChapterSelected 回调外部 seek 并关闭面板；
 *             - 分段时间徽标点击后通过 onSegmentSelected 回调外部 seek，不关闭面板。
 *
 *             自身铺满所在容器，不做尺寸与横竖屏适配：frame、圆角、弹出方向、
 *             动画与蒙层由 ChapterContentPanelSlot 统一决定（竖屏自底部弹出约 60% 高，
 *             横屏自右侧弹出定宽 345pt），显示期间切换全屏则直接关闭面板。
 *
 * @see AiVideoContent
 * @see ChapterContentPanelSlot
 */
@interface ChapterContentView : UIView

/**
 * @brief 章节点击回调。
 *
 * @discussion 参数为章节起始时间（毫秒），由外部执行 seek 并关闭面板。
 */
@property (nonatomic, copy, nullable) void (^onChapterSelected)(NSInteger startMs);

/**
 * @brief 分段时间徽标点击回调。
 *
 * @discussion 参数为分段起始时间（毫秒），由外部执行 seek；seek 后不关闭面板。
 */
@property (nonatomic, copy, nullable) void (^onSegmentSelected)(NSInteger startMs);

/**
 * @brief 通过 AI 视频内容创建内容视图。
 *
 * @discussion 初始 frame 为 CGRectZero，由容器负责设定。
 *
 * @param content AI 视频内容业务模型。
 *
 * @return 已初始化的内容视图实例。
 */
- (instancetype)initWithContent:(AiVideoContent *)content;

/**
 * @brief 更新当前播放位置，驱动章节 / 分段高亮。
 *
 * @discussion 内部二分查找定位当前章节与分段，仅在索引变化时刷新对应行。
 *
 * @param positionMs 当前播放位置，单位毫秒。
 */
- (void)updateCurrentPosition:(NSInteger)positionMs;

@end

NS_ASSUME_NONNULL_END
