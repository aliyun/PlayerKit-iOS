//
//  SlotBehavior.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SlotBehavior.h"
#import "SlotHost.h"
#import "PlayerNotificationDelegate.h"
#import "AliPlayerController.h"
#import "Log.h"

/**
 * @brief 通知订阅记录（内部使用）。
 *
 * @discussion 跟踪已注册的代理和对应的控制器，确保 detach 时能正确取消所有订阅。
 */
@interface _SlotBehaviorSubscription : NSObject

@property (nonatomic, weak) id<PlayerNotificationDelegate> delegate;
@property (nonatomic, weak) AliPlayerController *controller;

@end

@implementation _SlotBehaviorSubscription
@end

@interface SlotBehavior ()

@property (nonatomic, weak, readwrite) id<SlotHost> host;
@property (nonatomic, strong) NSMutableArray<_SlotBehaviorSubscription *> *subscriptions;

@end

@implementation SlotBehavior

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _subscriptions = [NSMutableArray array];

        SLOGI(@"[LC][init] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
    }
    return self;
}

- (void)dealloc {
    SLOGI(@"[LC][dealloc] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
}

#pragma mark - Public Methods

- (void)attachToHost:(id<SlotHost>)host {
    self.host = host;
    SLOGI(@"attached to host");
}

- (void)detach {
    [self unsubscribeAll];
    self.host = nil;
    SLOGI(@"detached");
}

- (void)addNotificationDelegate:(id<PlayerNotificationDelegate>)delegate
                   toController:(AliPlayerController *)controller {
    if (!delegate || !controller) {
        return;
    }

    [controller addNotificationDelegate:delegate];

    _SlotBehaviorSubscription *subscription = [[_SlotBehaviorSubscription alloc] init];
    subscription.delegate = delegate;
    subscription.controller = controller;
    [self.subscriptions addObject:subscription];
}

- (void)removeNotificationDelegate:(id<PlayerNotificationDelegate>)delegate
                     fromController:(AliPlayerController *)controller {
    if (!delegate || !controller) {
        return;
    }

    [controller removeNotificationDelegate:delegate];

    NSMutableIndexSet *toRemove = [NSMutableIndexSet indexSet];
    [self.subscriptions enumerateObjectsUsingBlock:^(_SlotBehaviorSubscription *sub, NSUInteger idx, BOOL *stop) {
        if (sub.delegate == delegate && sub.controller == controller) {
            [toRemove addIndex:idx];
        }
    }];
    [self.subscriptions removeObjectsAtIndexes:toRemove];
}

#pragma mark - Private Methods

- (void)unsubscribeAll {
    for (_SlotBehaviorSubscription *subscription in self.subscriptions) {
        AliPlayerController *controller = subscription.controller;
        id<PlayerNotificationDelegate> delegate = subscription.delegate;
        if (controller && delegate) {
            [controller removeNotificationDelegate:delegate];
        }
    }
    [self.subscriptions removeAllObjects];
}

@end
