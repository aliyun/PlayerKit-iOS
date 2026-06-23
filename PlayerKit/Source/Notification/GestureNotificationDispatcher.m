//
//  GestureNotificationDispatcher.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "GestureNotificationDispatcher.h"
#import "GestureNotificationDelegate.h"
#import "Log.h"

@interface GestureNotificationDispatcher ()

@property (nonatomic, strong) NSHashTable<id<GestureNotificationDelegate>> *observers;
@property (nonatomic, strong) dispatch_queue_t internalQueue;

@end

@implementation GestureNotificationDispatcher

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _observers = [NSHashTable weakObjectsHashTable];
        _internalQueue = dispatch_queue_create("com.aliyun.playerkit.gesture.notification.dispatcher", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Public Methods

- (void)addObserver:(id<GestureNotificationDelegate>)observer {
    if (!observer) return;
    dispatch_sync(self.internalQueue, ^{
        if (![self.observers containsObject:observer]) {
            [self.observers addObject:observer];
        }
    });
}

- (void)removeObserver:(id<GestureNotificationDelegate>)observer {
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

- (void)notifyObservers:(void(^)(id<GestureNotificationDelegate> observer))block {
    if (!block) return;

    // 以线程安全方式获取当前观察者快照
    __block NSArray<id<GestureNotificationDelegate>> *snapshot = nil;
    dispatch_sync(self.internalQueue, ^{
        snapshot = [self.observers allObjects];
    });

    if (snapshot.count == 0) return;

    // 在主线程上分发通知
    if ([NSThread isMainThread]) {
        for (id<GestureNotificationDelegate> observer in snapshot) {
            @try {
                block(observer);
            } @catch (NSException *exception) {
                SLOGW(@"observer exception - %@", exception);
            }
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<GestureNotificationDelegate> observer in snapshot) {
                @try {
                    block(observer);
                } @catch (NSException *exception) {
                    SLOGW(@"observer exception - %@", exception);
                }
            }
        });
    }
}

- (NSUInteger)observerCount {
    __block NSUInteger count = 0;
    dispatch_sync(self.internalQueue, ^{
        count = self.observers.count;
    });
    return count;
}

@end
