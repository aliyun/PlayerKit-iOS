//
//  FileLogObserver.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/16.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LogObserver.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 将日志条目写入磁盘的基于文件的日志观察者。
 *
 * @discussion 遵循 LogObserver 协议，将格式化的日志字符串追加到应用程序 Documents 目录下的日志文件中。
 *             通过 [LogHub addObserver:] 注册此观察者以启用文件日志。
 *
 * @see LogObserver
 * @see LogHub
 * @see LogInfo
 */
@interface FileLogObserver : NSObject <LogObserver>

@end

NS_ASSUME_NONNULL_END
