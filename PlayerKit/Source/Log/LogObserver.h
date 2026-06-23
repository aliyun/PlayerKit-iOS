//
//  LogObserver.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/16.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LogInfo;

/**
 * @brief 日志监听器协议。
 *
 * @discussion 实现此协议可接收所有日志输出回调，
 *             用于自定义日志处理（如写入文件、上报服务器等）。
 *
 * @warning onLog: 方法在子线程调用，请勿直接更新 UI。
 * @see LogHub
 * @see LogInfo
 */
@protocol LogObserver <NSObject>

@required

/**
 * @brief 日志输出回调。
 *
 * @param logInfo 日志信息对象，包含级别、标签、消息和时间戳。
 *
 * @discussion 每条日志输出时都会触发此回调。
 *             回调在子线程执行，如有 UI 操作需 dispatch 到主线程。
 */
- (void)onLog:(LogInfo *)logInfo;

@end
