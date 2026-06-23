//
//  TrafficProtectionStrategy.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "TrafficProtectionStrategy.h"
#import "StrategyContext.h"
#import "AliPlayerController.h"
#import "Log.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

static void OnReachabilityDelegate(SCNetworkReachabilityRef target,
                                   SCNetworkReachabilityFlags flags,
                                   void *info);

static const void *ReachabilityContextRetain(const void *info) {
    return CFRetain(info);
}

static void ReachabilityContextRelease(const void *info) {
    CFBridgingRelease(info);
}

@interface TrafficProtectionStrategy ()

@property (nonatomic, assign, readwrite) BOOL isOnCellularNetwork;
@property (nonatomic, assign) BOOL mobileHintShown;
@property (nonatomic, assign) SCNetworkReachabilityRef reachabilityRef;

@end

@implementation TrafficProtectionStrategy

#pragma mark - Lifecycle

- (void)dealloc {
    [self stopNetworkMonitoring];
}

#pragma mark - StrategyProtocol

- (NSString *)strategyName {
    return @"TrafficProtectionStrategy";
}

- (void)strategyDidStart:(StrategyContext *)context {
    [super strategyDidStart:context];
    [self startNetworkMonitoring];
    [self updateNetworkStatus];
}

- (void)strategyDidStop {
    [self stopNetworkMonitoring];
    [super strategyDidStop];
}

#pragma mark - Subclass Hooks

- (void)resetInternalState {
    self.mobileHintShown = NO;
    [self updateNetworkStatus];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    if (state == PlayerStatePlaying) {
        [self checkAndWarnIfCellular];
    }
}

#pragma mark - Private Methods

// 根据 Reachability flags 更新网络状态
- (void)updateNetworkStatusWithFlags:(SCNetworkReachabilityFlags)flags {
    BOOL isReachable = (flags & kSCNetworkReachabilityFlagsReachable) != 0;
    BOOL isWWAN = (flags & kSCNetworkReachabilityFlagsIsWWAN) != 0;

    BOOL wasCellular = self.isOnCellularNetwork;
    self.isOnCellularNetwork = isReachable && isWWAN;

    // 从 Wi-Fi 切换到蜂窝
    if (!wasCellular && self.isOnCellularNetwork) {
        self.mobileHintShown = NO;
        [self checkAndWarnIfCellular];
    }
    // 从蜂窝切换回 Wi-Fi
    else if (wasCellular && !self.isOnCellularNetwork) {
        self.mobileHintShown = NO;
        SLOGI(@"已切换到 Wi-Fi 网络");
        if (self.delegate && [self.delegate respondsToSelector:@selector(trafficProtectionStrategyDidDetectWifiNetwork:)]) {
            [self.delegate trafficProtectionStrategyDidDetectWifiNetwork:self];
        }
    }
}

// 同步检查当前网络状态
- (void)updateNetworkStatus {
    if (self.reachabilityRef) {
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
            BOOL isReachable = (flags & kSCNetworkReachabilityFlagsReachable) != 0;
            BOOL isWWAN = (flags & kSCNetworkReachabilityFlagsIsWWAN) != 0;
            self.isOnCellularNetwork = isReachable && isWWAN;
            return;
        }
    }
    self.isOnCellularNetwork = NO;
}

// 如果在蜂窝网络下播放则发出警告
- (void)checkAndWarnIfCellular {
    [self updateNetworkStatus];
    if (self.isOnCellularNetwork && !self.mobileHintShown) {
        self.mobileHintShown = YES;
        SLOGW(@"当前使用蜂窝网络播放，请注意流量消耗");
        if (self.delegate && [self.delegate respondsToSelector:@selector(trafficProtectionStrategyDidDetectCellularNetwork:)]) {
            [self.delegate trafficProtectionStrategyDidDetectCellularNetwork:self];
        }
    }
}

// 创建 SCNetworkReachability 并注册回调到主 RunLoop
- (void)startNetworkMonitoring {
    if (self.reachabilityRef) return;

    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;

    self.reachabilityRef = SCNetworkReachabilityCreateWithAddress(
        kCFAllocatorDefault,
        (const struct sockaddr *)&zeroAddress
    );

    if (!self.reachabilityRef) return;

    SCNetworkReachabilityContext ctx = {
        0,
        (__bridge void *)self,
        ReachabilityContextRetain,
        ReachabilityContextRelease,
        NULL
    };
    if (SCNetworkReachabilitySetCallback(self.reachabilityRef, OnReachabilityDelegate, &ctx)) {
        SCNetworkReachabilityScheduleWithRunLoop(
            self.reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    }
}

// 注销回调并释放 SCNetworkReachability
- (void)stopNetworkMonitoring {
    if (!self.reachabilityRef) return;

    // 先注销回调（触发 context release），防止悬垂指针
    SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);
    SCNetworkReachabilityUnscheduleFromRunLoop(
        self.reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    CFRelease(self.reachabilityRef);
    self.reachabilityRef = NULL;
}

@end

#pragma mark - Reachability Delegate

static void OnReachabilityDelegate(SCNetworkReachabilityRef target,
                                   SCNetworkReachabilityFlags flags,
                                   void *info) {
    TrafficProtectionStrategy *strategy = (__bridge TrafficProtectionStrategy *)info;
    [strategy updateNetworkStatusWithFlags:flags];
}
