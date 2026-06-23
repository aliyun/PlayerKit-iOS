//
//  FirstFrameStrategy.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "FirstFrameStrategy.h"
#import "StrategyContext.h"
#import "AliPlayerController.h"
#import "Log.h"

@interface FirstFrameStrategy ()

@property (nonatomic, assign) CFAbsoluteTime startTime;
@property (nonatomic, assign) CFAbsoluteTime preparedTime;
@property (nonatomic, assign) BOOL firstFrameCompleted;

@end

@implementation FirstFrameStrategy

#pragma mark - StrategyProtocol

- (NSString *)strategyName {
    return @"FirstFrameStrategy";
}

#pragma mark - Subclass Hooks

- (void)resetInternalState {
    [self resetTiming];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    switch (state) {
        case PlayerStatePreparing:
            [self resetTiming];
            self.startTime = CFAbsoluteTimeGetCurrent();
            break;
        case PlayerStateError:
        case PlayerStateIdle:
        case PlayerStateStopped:
            [self resetTiming];
            break;
        default:
            break;
    }
}

- (void)playerDidPreparedWithDuration:(NSInteger)duration {
    if (self.startTime <= 0) return;
    self.preparedTime = CFAbsoluteTimeGetCurrent();

    NSInteger prepareTimeMs = (NSInteger)((self.preparedTime - self.startTime) * 1000);
    SLOGI(@"准备阶段耗时: %ldms", (long)prepareTimeMs);
}

- (void)playerDidRenderFirstFrame {
    if (self.firstFrameCompleted) return;
    if (self.startTime <= 0) return;

    self.firstFrameCompleted = YES;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();

    NSInteger totalTimeMs = (NSInteger)((now - self.startTime) * 1000);
    NSInteger prepareTimeMs = 0;
    NSInteger renderTimeMs = 0;

    if (self.preparedTime > 0) {
        prepareTimeMs = (NSInteger)((self.preparedTime - self.startTime) * 1000);
        renderTimeMs = (NSInteger)((now - self.preparedTime) * 1000);
    }

    SLOGI(@"首帧渲染完成 - 总耗时: %ldms (准备: %ldms, 渲染: %ldms)",
          (long)totalTimeMs, (long)prepareTimeMs, (long)renderTimeMs);

    if (self.delegate && [self.delegate respondsToSelector:@selector(firstFrameStrategy:didRenderFirstFrameWithPrepareTime:renderTime:totalTime:)]) {
        [self.delegate firstFrameStrategy:self
       didRenderFirstFrameWithPrepareTime:prepareTimeMs
                               renderTime:renderTimeMs
                                totalTime:totalTimeMs];
    }
}

#pragma mark - Private Methods

- (void)resetTiming {
    self.startTime = 0;
    self.preparedTime = 0;
    self.firstFrameCompleted = NO;
}

@end
