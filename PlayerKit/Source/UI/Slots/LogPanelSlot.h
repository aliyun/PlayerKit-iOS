//
//  LogPanelSlot.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseSlot.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 日志面板插槽。
 *
 * @discussion 实时展示 PlayerKit 内部的关键日志信息，便于调试和问题排查。
 *             通过 LogObserver 协议订阅 LogHub 日志输出，仅显示 DEBUG 及以上级别的日志。
 *
 *             面板支持以下交互：
 *             - 点击标题栏展开/折叠日志内容区。
 *             - 展开后可点击"清除"按钮清空日志。
 *             - 长按日志区域将内容拷贝到剪贴板。
 *
 *             可见性受 AliPlayerKit.isLogPanelEnabled 控制：
 *             - 启用时，面板在 SlotTypeLogPanel 位置展示。
 *             - 禁用时（默认），面板不响应日志。
 *
 *             在 Minimal 场景中不可见。
 *
 * @see BaseSlot
 * @see LogObserver
 * @see LogHub
 * @see AliPlayerKit
 */
@interface LogPanelSlot : BaseSlot

@end

NS_ASSUME_NONNULL_END
