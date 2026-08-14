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
#import "AiVideoContent.h"
#import "AiSummary.h"
#import "AiSegment.h"
#import "ChapterInfo.h"

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

- (void)loadWithMediaId:(NSString *)mediaId
             completion:(void (^)(AiVideoContent * _Nullable content))completion {
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
        AiVideoContent *content = [strongSelf convertToAiVideoContent:response mediaId:mediaId];
        [strongSelf dispatchToMain:^{
            completion(content);
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

#pragma mark - Private Methods - Conversion

// DTO → 业务模型转换
- (nullable AiVideoContent *)convertToAiVideoContent:(nullable AiAnalysisResponse *)response
                                             mediaId:(NSString *)mediaId {
    if (!response || response.aiAnalysisResult.count == 0) {
        return nil;
    }

    // 按 ResultType 分拣章节结果与摘要结果
    ResultItem *chapterResult = nil;
    ResultItem *summaryResult = nil;
    for (ResultItem *item in response.aiAnalysisResult) {
        if ([AiContentResultTypeChapter isEqualToString:item.resultType] && !chapterResult) {
            chapterResult = item;
        } else if ([AiContentResultTypeSummary isEqualToString:item.resultType] && !summaryResult) {
            summaryResult = item;
        }
    }
    if (!chapterResult && !summaryResult) {
        return nil;
    }

    NSMutableArray<ChapterInfo *> *chapters = [NSMutableArray array];
    NSMutableArray<AiSegment *> *segments = [NSMutableArray array];
    BOOL hasAnalysis = NO;

    for (ChapterContentItem *contentItem in chapterResult.chapterContentItems) {
        NSInteger startTime = contentItem.startTime;
        NSInteger endTime = contentItem.endTime;
        NSString *chapterTitle = contentItem.chapterTitle ?: @"";
        NSString *chapterId = contentItem.chapterId.length > 0 ? contentItem.chapterId : @"0";

        ChapterInfo *chapter = [[ChapterInfo alloc] initWithChapterId:chapterId
                                                              startMs:startTime
                                                                endMs:endTime
                                                                title:chapterTitle
                                                         thumbnailUrl:contentItem.thumbnailUrl];
        [chapters addObject:chapter];

        // 知识点拼接 Markdown 列表："- **{Point}**: {Description}\n"
        NSMutableString *markdown = [NSMutableString string];
        if (contentItem.knowledgePoints.count > 0) {
            hasAnalysis = YES;
            for (KnowledgePointItem *point in contentItem.knowledgePoints) {
                NSString *pointName = point.point ?: @"";
                NSString *description = point.pointDescription ?: @"";
                [markdown appendFormat:@"- **%@**: %@\n", pointName, description];
            }
        }
        if (contentItem.summary.length > 0) {
            hasAnalysis = YES;
        }
        NSString *mdContent = markdown.length > 0 ? [markdown copy] : nil;

        AiSegment *segment = [[AiSegment alloc] initWithSegmentId:chapterId
                                                          startMs:startTime
                                                            endMs:endTime
                                                            title:chapterTitle
                                                          summary:contentItem.summary
                                                         markdown:mdContent];
        [segments addObject:segment];
    }

    // 摘要：优先取 Summary 项的 ParagraphSummary，降级解析 Chapter 项 Extra JSON 中的 "Summary"；
    // 标签取自对应结果项的 tags 字段
    AiSummary *summary = nil;
    NSString *paragraphSummary = summaryResult.summaryContent.paragraphSummary;
    if (paragraphSummary.length > 0) {
        summary = [[AiSummary alloc] initWithTitle:summaryResult.title
                                       summaryText:paragraphSummary
                                          markdown:nil
                                              tags:summaryResult.tags];
        hasAnalysis = YES;
    } else if (chapterResult.extra.length > 0) {
        NSData *extraData = [chapterResult.extra dataUsingEncoding:NSUTF8StringEncoding];
        id extraJson = extraData ? [NSJSONSerialization JSONObjectWithData:extraData
                                                                   options:0
                                                                     error:nil] : nil;
        if ([extraJson isKindOfClass:[NSDictionary class]]) {
            id extraSummary = ((NSDictionary *)extraJson)[@"Summary"];
            if ([extraSummary isKindOfClass:[NSString class]] && [(NSString *)extraSummary length] > 0) {
                summary = [[AiSummary alloc] initWithTitle:chapterResult.title
                                               summaryText:(NSString *)extraSummary
                                                  markdown:nil
                                                      tags:chapterResult.tags];
                hasAnalysis = YES;
            }
        }
    }

    // 有知识点或摘要为文字解析，否则仅章节
    AiContentType type = hasAnalysis ? AiContentTypeTextAnalysis : AiContentTypeChaptersOnly;

    return [[AiVideoContent alloc] initWithVideoId:mediaId
                                              type:type
                                           summary:summary
                                          chapters:[chapters copy]
                                          segments:[segments copy]];
}

@end
