//
//  ReusePoolLifecycleStrategy.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "ReusePoolLifecycleStrategy.h"
#import "MediaPlayer.h"
#import "Log.h"

static const NSInteger kDefaultMaxPoolSize = 3;

@interface ReusePoolLifecycleStrategy ()

@property (nonatomic, strong) NSMutableArray<id<MediaPlayer>> *idlePlayers;
@property (nonatomic, strong) NSHashTable<id<MediaPlayer>> *activePlayers;
@property (nonatomic, strong) NSLock *lock;

@end

@implementation ReusePoolLifecycleStrategy

#pragma mark - Lifecycle

- (instancetype)initWithMaxPoolSize:(NSInteger)maxPoolSize {
    self = [super init];
    if (self) {
        _maxPoolSize = maxPoolSize;
        _idlePlayers = [NSMutableArray array];
        _activePlayers = [NSHashTable hashTableWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality];
        _lock = [[NSLock alloc] init];
        _lock.name = @"com.aliplayerkit.reusepool";

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
    [self.lock lock];
    id<MediaPlayer> player = self.idlePlayers.lastObject;
    if (player) {
        [self.idlePlayers removeLastObject];
        [self.activePlayers addObject:player];
        [self.lock unlock];
        SLOGI(@"Acquired player from pool (%@, remaining: %ld)", player, (long)self.idlePlayers.count);
        return player;
    }
    [self.lock unlock];

    player = [self createPlayer];

    [self.lock lock];
    [self.activePlayers addObject:player];
    [self.lock unlock];

    SLOGI(@"Acquired new player (%@, pool was empty)", player);
    return player;
}

- (void)recyclePlayer:(nullable id<MediaPlayer>)player force:(BOOL)force {
    if (!player) return;

    [self.lock lock];
    [self.activePlayers removeObject:player];
    [self.lock unlock];

    if (force) {
        [self destroyPlayer:player];
        SLOGI(@"Recycled player (force destroyed) (%@)", player);
        return;
    }

    [player stop];
    player.notificationDispatcher = nil;

    [self.lock lock];
    if ((NSInteger)self.idlePlayers.count < self.maxPoolSize) {
        [self.idlePlayers addObject:player];
        SLOGI(@"Recycled player to pool (%@, pool size: %ld)", player, (long)self.idlePlayers.count);
    } else {
        [self.lock unlock];
        [self destroyPlayer:player];
        SLOGI(@"Recycled player (pool full, destroyed) (%@)", player);
        return;
    }
    [self.lock unlock];
}

- (void)clear {
    [self.lock lock];
    NSArray<id<MediaPlayer>> *players = [self.idlePlayers copy];
    [self.idlePlayers removeAllObjects];
    [self.lock unlock];

    for (id<MediaPlayer> player in players) {
        [self destroyPlayer:player];
    }
    SLOGI(@"Cleared pool (%ld idle players destroyed, %ld active players kept)",
          (long)players.count, (long)self.activePlayers.count);
}

- (void)preloadWithCount:(NSInteger)count {
    if (count <= 0) return;

    [self.lock lock];
    NSInteger toCreate = MIN(count, self.maxPoolSize) - (NSInteger)self.idlePlayers.count;
    [self.lock unlock];

    if (toCreate <= 0) return;

    NSMutableArray<id<MediaPlayer>> *newPlayers = [NSMutableArray arrayWithCapacity:toCreate];
    for (NSInteger i = 0; i < toCreate; i++) {
        [newPlayers addObject:[self createPlayer]];
    }

    [self.lock lock];
    NSInteger spaceLeft = self.maxPoolSize - (NSInteger)self.idlePlayers.count;
    NSInteger toAdd = MIN((NSInteger)newPlayers.count, spaceLeft);
    for (NSInteger i = 0; i < toAdd; i++) {
        [self.idlePlayers addObject:newPlayers[i]];
    }
    [self.lock unlock];

    for (NSInteger i = toAdd; i < (NSInteger)newPlayers.count; i++) {
        [self destroyPlayer:newPlayers[i]];
    }

    SLOGI(@"Preloaded %ld players (pool size: %ld)", (long)toAdd, (long)self.idlePlayers.count);
}

#pragma mark - Properties

- (NSInteger)idleCount {
    [self.lock lock];
    NSInteger count = (NSInteger)self.idlePlayers.count;
    [self.lock unlock];
    return count;
}

- (NSInteger)activeCount {
    [self.lock lock];
    NSInteger count = (NSInteger)self.activePlayers.count;
    [self.lock unlock];
    return count;
}

@end
