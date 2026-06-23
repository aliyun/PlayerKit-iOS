//
//  FileLogObserver.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/16.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "FileLogObserver.h"
#import "LogInfo.h"

@implementation FileLogObserver

#pragma mark - LogObserver

- (void)onLog:(LogInfo *)logInfo {
    // TODO: 在此处实现文件写入逻辑
    // 建议：
    // 1. 使用异步文件 I/O 以避免阻塞日志队列
    // 2. 将 logInfo.formattedString 追加写入日志文件
    // 3. 考虑日志轮转以防止文件体积增长
}

@end
