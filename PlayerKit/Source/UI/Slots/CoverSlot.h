//
//  CoverSlot.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseSlot.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 封面图插槽。
 *
 * @discussion 负责显示视频封面图，覆盖在播放器 Surface 之上。
 *             在视频首帧渲染出来之前作为兜底画面，避免出现黑屏；
 *             首帧渲染完成后立即隐藏，露出视频内容。
 *
 *             封面图有两个来源，优先级和时序都不同：
 *
 *             1. 外部赋值 —— AliPlayerModel.coverUrl。绑定数据时地址就已经前置请求获取到了，
 *                再配合的图片预加载（可提前把封面下载进本地缓存），
 *                封面几乎与页面同时出现，从加载到渲染全程没有黑屏，秒开效果最好。
 *             2. SDK 自动提取 —— Vid 播放方式下，SDK 在 prepare 完成后从媒体信息中拿到地址，
 *                通过 playerDidReadyCoverUrl: 回调进来。接入方只传一个 Vid 即可，
 *                不用另外维护封面地址，且 Vid 比明文 URL 更安全。
 *                代价是取地址这一步发生在 prepare 之后，从绑定到封面出现之间
 *                仍可能有一段短暂黑屏 —— 这是该来源的固有时序，不是缺陷。
 *
 *             两者同时存在时以外部赋值为准。追求秒开选第一种，追求接入简单选第二种。
 *
 *             显示规则：
 *             1. 封面图的缩放方式跟随播放器当前的 scaleMode，与视频画面保持一致，
 *                两者切换时不会出现画面跳变。
 *             2. 首帧渲染后封面图不会再次显示，只有重新绑定数据时才恢复。
 *                播放过程中的 seek、卡顿、切换清晰度、播放结束都不会让封面图盖回画面。
 *
 *             可见性规则：在 Live、Restricted、Minimal 场景中不可见。
 *
 * @note 使用前提：封面图的宽高比需与视频画面一致（通常封面由服务端按视频同源生成）。
 *       若两者宽高比不同，封面与画面的边界无法精确重合，切换时仍会有轻微跳动。
 *
 * @see BaseSlot
 * @see AliPlayerModel
 * @see ScaleMode
 */
@interface CoverSlot : BaseSlot

@end

NS_ASSUME_NONNULL_END
