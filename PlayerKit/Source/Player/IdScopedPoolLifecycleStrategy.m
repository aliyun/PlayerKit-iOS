//
//  IdScopedPoolLifecycleStrategy.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/22.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "IdScopedPoolLifecycleStrategy.h"
#import "MediaPlayer.h"
#import "Log.h"

static const NSInteger kDefaultMaxPoolSize = 3;

@interface IdScopedPoolLifecycleStrategy ()

/// uniqueId -> player 映射表
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<MediaPlayer>> *playerMap;

/// LRU 访问顺序：最旧在头部，最新在尾部
@property (nonatomic, strong) NSMutableArray<NSString *> *accessOrder;

/// 当前处于活跃状态（已 acquire 未 recycle）的 uniqueId 集合
@property (nonatomic, strong) NSMutableSet<NSString *> *activeKeys;

/// 预加载但尚未绑定 uniqueId 的播放器队列
@property (nonatomic, strong) NSMutableArray<id<MediaPlayer>> *unboundPlayers;

@property (nonatomic, strong) NSLock *lock;

@end

@implementation IdScopedPoolLifecycleStrategy

#pragma mark - Lifecycle

- (instancetype)initWithMaxPoolSize:(NSInteger)maxPoolSize {
    self = [super init];
    if (self) {
        _maxPoolSize = maxPoolSize;
        _playerMap = [NSMutableDictionary dictionary];
        _accessOrder = [NSMutableArray array];
        _activeKeys = [NSMutableSet set];
        _unboundPlayers = [NSMutableArray array];
        _lock = [[NSLock alloc] init];
        _lock.name = @"com.aliplayerkit.idscopedpool";

        SLOGI(@"[LC][init] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
    }
    return self;
}

- (instancetype)init {
    return [self initWithMaxPoolSize:kDefaultMaxPoolSize];
}

- (void)dealloc {
    [self clear];

    SLOGI(@"[LC][dealloc] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
}

#pragma mark - PlayerLifecycleStrategy

- (id<MediaPlayer>)acquirePlayer {
    SLOGW(@"acquirePlayer called without uniqueId, generating UUID fallback");
    return [self acquirePlayerWithUniqueId:[[NSUUID UUID] UUIDString]];
}

- (id<MediaPlayer>)acquirePlayerWithUniqueId:(NSString *)uniqueId {
    NSParameterAssert(uniqueId);

    [self.lock lock];

    // 1. 检查是否已存在该 uniqueId 对应的实例（LRU 命中）
    id<MediaPlayer> existingPlayer = self.playerMap[uniqueId];
    if (existingPlayer) {
        [self touchKey:uniqueId];
        [self.activeKeys addObject:uniqueId];
        [self.lock unlock];
        SLOGI(@"Acquired existing player for uniqueId=%@ (%@)", uniqueId, existingPlayer);
        return existingPlayer;
    }

    // 2. 不存在，优先从预加载队列获取，否则创建新实例
    id<MediaPlayer> newPlayer = self.unboundPlayers.firstObject;
    BOOL isFromUnbound = (newPlayer != nil);
    if (isFromUnbound) {
        [self.unboundPlayers removeObjectAtIndex:0];
    } else {
        [self.lock unlock];
        newPlayer = [self createPlayer];
        [self.lock lock];
    }

    // 3. 放入映射表，可能触发 LRU 淘汰
    self.playerMap[uniqueId] = newPlayer;
    [self.accessOrder addObject:uniqueId];
    [self.activeKeys addObject:uniqueId];
    [self evictIfNeeded];

    [self.lock unlock];

    SLOGI(@"Acquired %@ player for uniqueId=%@ (%@)",
          isFromUnbound ? @"preloaded" : @"new", uniqueId, newPlayer);
    return newPlayer;
}

- (void)recyclePlayer:(nullable id<MediaPlayer>)player force:(BOOL)force {
    if (!player) return;

    [self.lock lock];
    NSString *uniqueId = [self uniqueIdForPlayer:player];
    [self.lock unlock];

    [self recyclePlayer:player uniqueId:(uniqueId ?: @"") force:force];
}

- (void)recyclePlayer:(nullable id<MediaPlayer>)player uniqueId:(NSString *)uniqueId force:(BOOL)force {
    if (!player) return;

    [self.lock lock];

    [self.activeKeys removeObject:uniqueId];

    if (force) {
        [self.playerMap removeObjectForKey:uniqueId];
        [self.accessOrder removeObject:uniqueId];
        [self.lock unlock];
        [self destroyPlayer:player];
        SLOGI(@"Recycled player (force destroyed) for uniqueId=%@ (%@)", uniqueId, player);
        return;
    }

    // 非强制回收：仅停止，保留在映射表中供后续复用
    [self.lock unlock];
    [player stop];
    player.notificationDispatcher = nil;
    SLOGI(@"Recycled player (kept in map) for uniqueId=%@ (%@)", uniqueId, player);
}

- (void)clear {
    [self.lock lock];

    // 1. 销毁预加载的未绑定播放器
    NSArray<id<MediaPlayer>> *unbounds = [self.unboundPlayers copy];
    [self.unboundPlayers removeAllObjects];

    // 2. 销毁映射表中非活跃的空闲播放器
    NSMutableArray<NSString *> *keysToRemove = [NSMutableArray array];
    NSMutableArray<id<MediaPlayer>> *playersToDestroy = [NSMutableArray array];

    for (NSString *key in self.playerMap) {
        if (![self.activeKeys containsObject:key]) {
            [keysToRemove addObject:key];
            [playersToDestroy addObject:self.playerMap[key]];
        }
    }

    for (NSString *key in keysToRemove) {
        [self.playerMap removeObjectForKey:key];
        [self.accessOrder removeObject:key];
    }

    [self.lock unlock];

    for (id<MediaPlayer> player in unbounds) {
        [self destroyPlayer:player];
    }
    for (id<MediaPlayer> player in playersToDestroy) {
        [self destroyPlayer:player];
    }

    SLOGI(@"Cleared %ld unbound + %ld idle players",
          (long)unbounds.count, (long)playersToDestroy.count);
}

- (void)preloadWithCount:(NSInteger)count {
    if (count <= 0) return;

    NSMutableArray<id<MediaPlayer>> *newPlayers = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger i = 0; i < count; i++) {
        [newPlayers addObject:[self createPlayer]];
    }

    [self.lock lock];
    [self.unboundPlayers addObjectsFromArray:newPlayers];
    [self.lock unlock];

    SLOGI(@"Preloaded %ld unbound players (queue size: %ld)",
          (long)count, (long)self.unboundPlayers.count);
}

#pragma mark - Properties

- (void)setMaxPoolSize:(NSInteger)maxPoolSize {
    [self.lock lock];
    _maxPoolSize = maxPoolSize;

    // 如果新容量小于当前数量，按 LRU 顺序淘汰多余实例
    NSMutableArray<id<MediaPlayer>> *evicted = [NSMutableArray array];
    while ((NSInteger)self.playerMap.count > maxPoolSize && self.accessOrder.count > 0) {
        NSString *oldestKey = self.accessOrder.firstObject;
        id<MediaPlayer> player = self.playerMap[oldestKey];
        if (player) {
            [evicted addObject:player];
        }
        [self.playerMap removeObjectForKey:oldestKey];
        [self.accessOrder removeObjectAtIndex:0];
        [self.activeKeys removeObject:oldestKey];
    }

    [self.lock unlock];

    for (id<MediaPlayer> player in evicted) {
        [self destroyPlayer:player];
        SLOGI(@"Pruned player after resize (%@)", player);
    }
}

- (NSInteger)poolCount {
    [self.lock lock];
    NSInteger count = (NSInteger)self.playerMap.count;
    [self.lock unlock];
    return count;
}

#pragma mark - Private

/// 更新 LRU 访问顺序：将 key 移到尾部（最近使用）
- (void)touchKey:(NSString *)key {
    [self.accessOrder removeObject:key];
    [self.accessOrder addObject:key];
}

/// 当映射表超过 maxPoolSize 时，淘汰最旧的非活跃实例
- (void)evictIfNeeded {
    NSInteger maxAttempts = (NSInteger)self.accessOrder.count;
    NSInteger attempts = 0;
    while ((NSInteger)self.playerMap.count > self.maxPoolSize && self.accessOrder.count > 0 && attempts < maxAttempts) {
        NSString *oldestKey = self.accessOrder.firstObject;

        // 跳过活跃实例
        if ([self.activeKeys containsObject:oldestKey]) {
            [self.accessOrder removeObjectAtIndex:0];
            [self.accessOrder addObject:oldestKey];
            attempts++;
            continue;
        }

        id<MediaPlayer> player = self.playerMap[oldestKey];
        [self.playerMap removeObjectForKey:oldestKey];
        [self.accessOrder removeObjectAtIndex:0];

        if (player) {
            [self destroyPlayer:player];
            SLOGI(@"LRU evicted player for uniqueId=%@ (%@)", oldestKey, player);
        }
    }
}

/// 通过 player 实例反查 uniqueId
- (nullable NSString *)uniqueIdForPlayer:(id<MediaPlayer>)player {
    for (NSString *key in self.playerMap) {
        if (self.playerMap[key] == player) {
            return key;
        }
    }
    return nil;
}

@end
