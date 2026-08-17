//
//  AiContentLoader.m
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "AiContentLoader.h"
#import "AiContentConstants.h"
#import "PlayAuthResponse.h"
#import "AiAnalysisResponse.h"

@interface AiContentLoader ()

// App Server 基础地址
@property (nonatomic, copy) NSString *baseURL;

// 私有网络会话，连接/读取超时均为 5s
@property (nonatomic, strong) NSURLSession *session;

// 串行后台队列，所有请求发起与解析在此执行
@property (nonatomic, strong) dispatch_queue_t workQueue;

// 取消标记，置位后不再触发任何回调
@property (atomic, assign) BOOL cancelled;

// 进行中的任务集合，cancel 时统一取消
@property (nonatomic, strong) NSMutableArray<NSURLSessionDataTask *> *activeTasks;

// activeTasks 访问锁
@property (nonatomic, strong) NSLock *taskLock;

@end

@implementation AiContentLoader

#pragma mark - Lifecycle

- (instancetype)initWithBaseURL:(nullable NSString *)baseURL {
    self = [super init];
    if (self) {
        // 确保 baseURL 末尾不带斜杠
        if ([baseURL hasSuffix:@"/"]) {
            baseURL = [baseURL substringToIndex:baseURL.length - 1];
        }
        _baseURL = baseURL.length > 0 ? [baseURL copy] : AiContentAppServerBaseURL;
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 5;
        config.timeoutIntervalForResource = 5;
        _session = [NSURLSession sessionWithConfiguration:config];
        _workQueue = dispatch_queue_create("PlayerKit-AiContentLoader", DISPATCH_QUEUE_SERIAL);
        _cancelled = NO;
        _activeTasks = [NSMutableArray array];
        _taskLock = [[NSLock alloc] init];
    }
    return self;
}

- (instancetype)init {
    return [self initWithBaseURL:nil];
}

#pragma mark - Public Methods

- (void)loadPlayAuthWithVideoId:(NSString *)videoId
                     completion:(void (^)(NSString * _Nullable playAuth))completion {
    NSString *urlString = [AiContentConstants buildPlayAuthURLWithBaseURL:self.baseURL
                                                                  videoId:videoId];
    __weak typeof(self) weakSelf = self;
    [self fetchJSONWithURLString:urlString completion:^(NSDictionary * _Nullable json) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        PlayAuthResponse *response = [PlayAuthResponse responseWithDictionary:json];
        NSString *playAuth = response.data.playAuth;
        NSString *result = playAuth.length > 0 ? playAuth : nil;
        [strongSelf dispatchToMain:^{
            completion(result);
        }];
    }];
}

- (void)loadAiAnalysisWithMediaId:(NSString *)mediaId
                       completion:(void (^)(AiAnalysisResponse * _Nullable response))completion {
    // 省略 ResultType 参数，一次拉取全部结果（推荐）
    NSString *urlString = [AiContentConstants buildAiAnalysisURLWithBaseURL:self.baseURL
                                                                    mediaId:mediaId
                                                                 resultType:nil];
    __weak typeof(self) weakSelf = self;
    [self fetchJSONWithURLString:urlString completion:^(NSDictionary * _Nullable json) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        AiAnalysisResponse *response = [AiAnalysisResponse responseWithDictionary:json];
        response.mediaId = mediaId;
        [strongSelf dispatchToMain:^{
            completion(response);
        }];
    }];
}

- (void)cancel {
    self.cancelled = YES;
    [self.taskLock lock];
    NSArray<NSURLSessionDataTask *> *tasks = [self.activeTasks copy];
    [self.activeTasks removeAllObjects];
    [self.taskLock unlock];
    for (NSURLSessionDataTask *task in tasks) {
        [task cancel];
    }
}

#pragma mark - Private Methods - Networking

// 在串行队列发起 GET 请求并解析 JSON，回调在 workQueue 执行；已取消时不回调
- (void)fetchJSONWithURLString:(nullable NSString *)urlString
                    completion:(void (^)(NSDictionary * _Nullable json))completion {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.workQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.cancelled) {
            return;
        }
        NSURL *url = urlString.length > 0 ? [NSURL URLWithString:urlString] : nil;
        if (!url) {
            completion(nil);
            return;
        }
        __block NSURLSessionDataTask *task = nil;
        task = [strongSelf.session dataTaskWithURL:url
                                 completionHandler:^(NSData * _Nullable data,
                                                     NSURLResponse * _Nullable response,
                                                     NSError * _Nullable error) {
            __strong typeof(weakSelf) innerSelf = weakSelf;
            // 无论是否已取消，均先从 activeTasks 移除当前任务，保证集合只含进行中任务
            if (innerSelf && task) {
                [innerSelf.taskLock lock];
                [innerSelf.activeTasks removeObjectIdenticalTo:task];
                [innerSelf.taskLock unlock];
            }
            task = nil;
            if (!innerSelf || innerSelf.cancelled) {
                return;
            }
            NSDictionary *json = nil;
            NSHTTPURLResponse *httpResponse =
                [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
            if (!error && data.length > 0 && httpResponse.statusCode == 200) {
                id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([parsed isKindOfClass:[NSDictionary class]]) {
                    json = (NSDictionary *)parsed;
                }
            }
            completion(json);
        }];
        [strongSelf.taskLock lock];
        [strongSelf.activeTasks addObject:task];
        [strongSelf.taskLock unlock];
        [task resume];
    });
}

// 切回主队列派发回调，派发前后均检查取消标记
- (void)dispatchToMain:(dispatch_block_t)block {
    if (self.cancelled) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.cancelled) {
            return;
        }
        block();
    });
}

@end
