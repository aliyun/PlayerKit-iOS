//
//  AiContentConstants.m
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "AiContentConstants.h"

// 客户唯一必改配置：App Server 基础地址
NSString * const AiContentAppServerBaseURL = @"https://vodappserver-gwzwacvbyf.cn-shanghai.fcapp.run";

// 默认演示视频 MediaId
NSString * const AiContentDefaultMediaId = @"2042d63ea5c771f19a6b4531859c0102";

// 接口参数名常量
NSString * const AiContentParamVideoId    = @"videoId";
NSString * const AiContentParamMediaId    = @"MediaId";
NSString * const AiContentParamResultType = @"ResultType";

// ResultType 取值常量
NSString * const AiContentResultTypeChapter = @"Chapter";
NSString * const AiContentResultTypeSummary = @"Summary";

// 接口路径常量
static NSString * const kPlayAuthPath   = @"/appServer/GetVideoPlayAuth";
static NSString * const kAiAnalysisPath = @"/GetMediaAiAnalysisByResultType";

@implementation AiContentConstants

#pragma mark - Public Methods

+ (nullable NSString *)buildPlayAuthURLWithBaseURL:(NSString *)baseURL
                                           videoId:(NSString *)videoId {
    if (baseURL.length == 0 || videoId.length == 0) {
        return nil;
    }
    NSString *encodedVid = [self encodeQueryValue:videoId];
    return [NSString stringWithFormat:@"%@%@?%@=%@",
            baseURL, kPlayAuthPath, AiContentParamVideoId, encodedVid];
}

+ (nullable NSString *)buildAiAnalysisURLWithBaseURL:(NSString *)baseURL
                                             mediaId:(NSString *)mediaId
                                          resultType:(nullable NSString *)resultType {
    if (baseURL.length == 0 || mediaId.length == 0) {
        return nil;
    }
    NSString *encodedVid = [self encodeQueryValue:mediaId];
    NSMutableString *url = [NSMutableString stringWithFormat:@"%@%@?%@=%@",
                            baseURL, kAiAnalysisPath, AiContentParamMediaId, encodedVid];
    if (resultType.length > 0) {
        [url appendFormat:@"&%@=%@", AiContentParamResultType, [self encodeQueryValue:resultType]];
    }
    return [url copy];
}

#pragma mark - Private Methods

// 对查询参数值做 URL 编码
+ (NSString *)encodeQueryValue:(NSString *)value {
    NSCharacterSet *allowed = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSMutableCharacterSet *strict = [allowed mutableCopy];
    // 查询值中不允许出现的保留字符
    [strict removeCharactersInString:@"&=?+"];
    NSString *encoded = [value stringByAddingPercentEncodingWithAllowedCharacters:strict];
    return encoded ?: value;
}

@end
