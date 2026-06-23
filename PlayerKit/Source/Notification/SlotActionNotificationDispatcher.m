//
//  SlotActionNotificationDispatcher.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/24.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SlotActionNotificationDispatcher.h"
#import "SlotActionNotificationDelegate.h"
#import "Log.h"

@interface SlotActionNotificationDispatcher ()

@property (nonatomic, strong) NSHashTable<id<SlotActionNotificationDelegate>> *observers;
@property (nonatomic, strong) dispatch_queue_t internalQueue;

@end

@implementation SlotActionNotificationDispatcher

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _observers = [NSHashTable weakObjectsHashTable];
        _internalQueue = dispatch_queue_create("com.aliyun.playerkit.slot.action.notification.dispatcher", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Public Methods

- (void)addObserver:(id<SlotActionNotificationDelegate>)observer {
    if (!observer) return;
    dispatch_sync(self.internalQueue, ^{
        if (![self.observers containsObject:observer]) {
            [self.observers addObject:observer];
        }
    });
}

- (void)removeObserver:(id<SlotActionNotificationDelegate>)observer {
    if (!observer) return;
    dispatch_sync(self.internalQueue, ^{
        [self.observers removeObject:observer];
    });
}

- (void)removeAllObservers {
    dispatch_sync(self.internalQueue, ^{
        [self.observers removeAllObjects];
    });
}

- (void)notifyObservers:(void(^)(id<SlotActionNotificationDelegate> observer))block {
    if (!block) return;

    // 以线程安全方式获取当前观察者快照
    __block NSArray<id<SlotActionNotificationDelegate>> *snapshot = nil;
    dispatch_sync(self.internalQueue, ^{
        snapshot = [self.observers allObjects];
    });

    if (snapshot.count == 0) return;

    // 始终异步分发，避免在按钮事件处理链中同步执行重量级 UI 操作
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<SlotActionNotificationDelegate> observer in snapshot) {
            @try {
                block(observer);
            } @catch (NSException *exception) {
                SLOGW(@"observer exception - %@", exception);
            }
        }
    });
}

- (NSUInteger)observerCount {
    __block NSUInteger count = 0;
    dispatch_sync(self.internalQueue, ^{
        count = self.observers.count;
    });
    return count;
}

@end
