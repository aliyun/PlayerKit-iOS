//
//  FileUtils.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/30.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "FileUtils.h"
#import <CommonCrypto/CommonDigest.h>

/// 文件操作错误域
static NSString *const kFileUtilsErrorDomain = @"com.alicloud.playerkit.FileUtils";

/// 默认缓冲区大小
static const NSUInteger kDefaultBufferSize = 8192;

/// 文件大小单位
static NSString *const kSizeUnits[] = {@"B", @"KB", @"MB", @"GB", @"TB"};
static const NSUInteger kSizeUnitsCount = 5;

/// JPEG 压缩质量
static const CGFloat kJPEGCompressionQuality = 0.9;

#pragma mark - Private Helper

static BOOL _isEmptyString(NSString *string) {
    return string == nil || string.length == 0;
}

static NSError *_fileError(NSInteger code, NSString *description) {
    return [NSError errorWithDomain:kFileUtilsErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: description ?: @"Unknown error"}];
}

@implementation FileUtils

// ========== 存在性检查 ==========

+ (BOOL)fileExistsAtPath:(nullable NSString *)path {
    if (_isEmptyString(path)) return NO;

    BOOL isDirectory = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    return exists && !isDirectory;
}

+ (BOOL)directoryExistsAtPath:(nullable NSString *)path {
    if (_isEmptyString(path)) return NO;

    BOOL isDirectory = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    return exists && isDirectory;
}

+ (BOOL)pathExistsAtPath:(nullable NSString *)path {
    if (_isEmptyString(path)) return NO;

    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

// ========== 路径操作 ==========

+ (NSString *)folderPathForFilePath:(nullable NSString *)path {
    if (_isEmptyString(path)) return @"";

    return [path stringByDeletingLastPathComponent] ?: @"";
}

+ (NSString *)fileNameForPath:(nullable NSString *)path {
    if (_isEmptyString(path)) return @"";

    return [path lastPathComponent] ?: @"";
}

+ (NSString *)fileExtensionForPath:(nullable NSString *)path {
    if (_isEmptyString(path)) return @"";

    NSString *ext = [path pathExtension];
    return ext.length > 0 ? ext : @"";
}

+ (NSString *)fileNameWithoutExtensionForPath:(nullable NSString *)path {
    if (_isEmptyString(path)) return @"";

    NSString *fileName = [path lastPathComponent];
    if (!fileName.length) return @"";

    return [fileName stringByDeletingPathExtension] ?: fileName;
}

+ (NSString *)combinePaths:(NSArray<NSString *> *)components {
    if (!components || components.count == 0) return @"";

    NSString *result = components.firstObject;
    for (NSUInteger i = 1; i < components.count; i++) {
        NSString *component = components[i];
        if (!_isEmptyString(component)) {
            result = [result stringByAppendingPathComponent:component];
        }
    }
    return result ?: @"";
}

// ========== 文件/目录创建 ==========

+ (BOOL)safeCreateDirectoryAtPath:(nullable NSString *)path error:(NSError **)error {
    if (_isEmptyString(path)) {
        if (error) *error = _fileError(-1, @"Path is nil or empty");
        return NO;
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    BOOL exists = [fm fileExistsAtPath:path isDirectory:&isDirectory];

    // 目标路径是文件，先删除
    if (exists && !isDirectory) {
        if (![fm removeItemAtPath:path error:error]) {
            return NO;
        }
        exists = NO;
    }

    // 目录已存在
    if (exists && isDirectory) {
        return YES;
    }

    // 创建目录
    return [fm createDirectoryAtPath:path
         withIntermediateDirectories:YES
                          attributes:nil
                               error:error];
}

+ (BOOL)safeCreateFileAtPath:(nullable NSString *)path error:(NSError **)error {
    if (_isEmptyString(path)) {
        if (error) *error = _fileError(-1, @"Path is nil or empty");
        return NO;
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    BOOL exists = [fm fileExistsAtPath:path isDirectory:&isDirectory];

    // 确保父目录存在
    NSString *parentPath = [self folderPathForFilePath:path];
    if (parentPath.length > 0) {
        if (![self safeCreateDirectoryAtPath:parentPath error:error]) {
            return NO;
        }
    }

    // 目标路径是目录，先递归删除
    if (exists && isDirectory) {
        if (![fm removeItemAtPath:path error:error]) {
            return NO;
        }
        exists = NO;
    }

    // 文件已存在
    if (exists && !isDirectory) {
        return YES;
    }

    // 创建文件
    BOOL created = [fm createFileAtPath:path contents:nil attributes:nil];
    if (!created && error) {
        *error = _fileError(-2, [NSString stringWithFormat:@"Failed to create file: %@", path]);
    }
    return created;
}

// ========== 存储路径获取 ==========

+ (NSString *)documentsDirectory {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject ?: @"";
}

+ (NSString *)cachesDirectory {
    return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject ?: @"";
}

+ (NSString *)temporaryDirectory {
    return NSTemporaryDirectory() ?: @"";
}

// ========== 文件读取 ==========

+ (nullable NSString *)readTextFromFile:(nullable NSString *)filePath error:(NSError **)error {
    if (_isEmptyString(filePath)) {
        if (error) *error = _fileError(-1, @"File path is nil or empty");
        return nil;
    }

    if (![self fileExistsAtPath:filePath]) {
        if (error) *error = _fileError(-3, [NSString stringWithFormat:@"File does not exist: %@", filePath]);
        return nil;
    }

    return [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:error];
}

+ (nullable NSData *)readDataFromFile:(nullable NSString *)filePath error:(NSError **)error {
    if (_isEmptyString(filePath)) {
        if (error) *error = _fileError(-1, @"File path is nil or empty");
        return nil;
    }

    if (![self fileExistsAtPath:filePath]) {
        if (error) *error = _fileError(-3, [NSString stringWithFormat:@"File does not exist: %@", filePath]);
        return nil;
    }

    return [NSData dataWithContentsOfFile:filePath options:0 error:error];
}

// ========== 文件写入 ==========

+ (BOOL)writeText:(nullable NSString *)text toFile:(nullable NSString *)filePath error:(NSError **)error {
    if (!text || _isEmptyString(filePath)) {
        if (error) *error = _fileError(-1, @"Text or file path is nil or empty");
        return NO;
    }

    if (![self safeCreateFileAtPath:filePath error:error]) {
        return NO;
    }

    return [text writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:error];
}

+ (BOOL)writeData:(nullable NSData *)data toFile:(nullable NSString *)filePath error:(NSError **)error {
    if (!data || _isEmptyString(filePath)) {
        if (error) *error = _fileError(-1, @"Data or file path is nil or empty");
        return NO;
    }

    if (![self safeCreateFileAtPath:filePath error:error]) {
        return NO;
    }

    return [data writeToFile:filePath options:NSDataWritingAtomic error:error];
}

// ========== 文件复制移动 ==========

+ (BOOL)copyFileFrom:(nullable NSString *)sourcePath to:(nullable NSString *)destPath error:(NSError **)error {
    if (_isEmptyString(sourcePath) || _isEmptyString(destPath)) {
        if (error) *error = _fileError(-1, @"Source or destination path is nil or empty");
        return NO;
    }

    if (![self fileExistsAtPath:sourcePath]) {
        if (error) *error = _fileError(-3, [NSString stringWithFormat:@"Source file does not exist: %@", sourcePath]);
        return NO;
    }

    // 确保目标文件父目录存在
    NSString *destParent = [self folderPathForFilePath:destPath];
    if (destParent.length > 0) {
        if (![self safeCreateDirectoryAtPath:destParent error:error]) {
            return NO;
        }
    }

    // 如果目标已存在则先删除
    if ([self pathExistsAtPath:destPath]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:destPath error:error]) {
            return NO;
        }
    }

    return [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destPath error:error];
}

+ (BOOL)moveFileFrom:(nullable NSString *)sourcePath to:(nullable NSString *)destPath error:(NSError **)error {
    if (_isEmptyString(sourcePath) || _isEmptyString(destPath)) {
        if (error) *error = _fileError(-1, @"Source or destination path is nil or empty");
        return NO;
    }

    if (![self fileExistsAtPath:sourcePath]) {
        if (error) *error = _fileError(-3, [NSString stringWithFormat:@"Source file does not exist: %@", sourcePath]);
        return NO;
    }

    // 确保目标文件父目录存在
    NSString *destParent = [self folderPathForFilePath:destPath];
    if (destParent.length > 0) {
        if (![self safeCreateDirectoryAtPath:destParent error:error]) {
            return NO;
        }
    }

    // 如果目标已存在则先删除
    if ([self pathExistsAtPath:destPath]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:destPath error:error]) {
            return NO;
        }
    }

    return [[NSFileManager defaultManager] moveItemAtPath:sourcePath toPath:destPath error:error];
}

// ========== 文件删除 ==========

+ (BOOL)deleteFileAtPath:(nullable NSString *)filePath error:(NSError **)error {
    if (_isEmptyString(filePath)) {
        if (error) *error = _fileError(-1, @"File path is nil or empty");
        return NO;
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return YES; // 文件不存在视为成功
    }

    if (![self fileExistsAtPath:filePath]) {
        if (error) *error = _fileError(-4, [NSString stringWithFormat:@"Path is not a file: %@", filePath]);
        return NO;
    }

    return [[NSFileManager defaultManager] removeItemAtPath:filePath error:error];
}

+ (BOOL)deleteRecursivelyAtPath:(nullable NSString *)path error:(NSError **)error {
    if (_isEmptyString(path)) {
        if (error) *error = _fileError(-1, @"Path is nil or empty");
        return NO;
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return YES; // 路径不存在视为成功
    }

    return [[NSFileManager defaultManager] removeItemAtPath:path error:error];
}

+ (BOOL)clearDirectoryAtPath:(nullable NSString *)path error:(NSError **)error {
    if (_isEmptyString(path)) {
        if (error) *error = _fileError(-1, @"Path is nil or empty");
        return NO;
    }

    if (![self directoryExistsAtPath:path]) {
        if (error) *error = _fileError(-3, [NSString stringWithFormat:@"Directory does not exist: %@", path]);
        return NO;
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *contents = [fm contentsOfDirectoryAtPath:path error:error];
    if (!contents) return NO;

    for (NSString *item in contents) {
        NSString *itemPath = [path stringByAppendingPathComponent:item];
        if (![fm removeItemAtPath:itemPath error:error]) {
            return NO;
        }
    }
    return YES;
}

// ========== 文件信息 ==========

+ (long long)fileSizeAtPath:(nullable NSString *)filePath {
    if (![self fileExistsAtPath:filePath]) return -1;

    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if (error || !attrs) return -1;

    return [attrs fileSize];
}

+ (NSString *)formatFileSize:(long long)size {
    if (size <= 0) return @"0 B";

    NSUInteger unitIndex = 0;
    double fileSize = (double)size;

    while (fileSize >= 1024.0 && unitIndex < kSizeUnitsCount - 1) {
        fileSize /= 1024.0;
        unitIndex++;
    }

    return [NSString stringWithFormat:@"%.2f %@", fileSize, kSizeUnits[unitIndex]];
}

+ (long long)directorySizeAtPath:(nullable NSString *)dirPath {
    if (![self directoryExistsAtPath:dirPath]) return -1;

    return [self _calculateDirectorySizeAtPath:dirPath];
}

+ (long long)_calculateDirectorySizeAtPath:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    long long totalSize = 0;

    BOOL isDirectory = NO;
    if (![fm fileExistsAtPath:path isDirectory:&isDirectory]) {
        return 0;
    }

    if (!isDirectory) {
        NSDictionary *attrs = [fm attributesOfItemAtPath:path error:nil];
        return attrs ? (long long)[attrs fileSize] : 0;
    }

    NSArray<NSString *> *contents = [fm contentsOfDirectoryAtPath:path error:nil];
    for (NSString *item in contents) {
        NSString *itemPath = [path stringByAppendingPathComponent:item];
        totalSize += [self _calculateDirectorySizeAtPath:itemPath];
    }

    return totalSize;
}

// ========== 文件校验 ==========

+ (nullable NSString *)md5ChecksumForFileAtPath:(nullable NSString *)filePath {
    if (![self fileExistsAtPath:filePath]) return nil;

    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:filePath];
    if (!stream) return nil;

    [stream open];

    CC_MD5_CTX ctx;
    CC_MD5_Init(&ctx);

    uint8_t buffer[kDefaultBufferSize];
    NSInteger bytesRead;
    while ((bytesRead = [stream read:buffer maxLength:sizeof(buffer)]) > 0) {
        CC_MD5_Update(&ctx, buffer, (CC_LONG)bytesRead);
    }

    [stream close];

    if (bytesRead < 0) return nil;

    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &ctx);

    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    return [result copy];
}

+ (nullable NSString *)sha256ChecksumForFileAtPath:(nullable NSString *)filePath {
    if (![self fileExistsAtPath:filePath]) return nil;

    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:filePath];
    if (!stream) return nil;

    [stream open];

    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);

    uint8_t buffer[kDefaultBufferSize];
    NSInteger bytesRead;
    while ((bytesRead = [stream read:buffer maxLength:sizeof(buffer)]) > 0) {
        CC_SHA256_Update(&ctx, buffer, (CC_LONG)bytesRead);
    }

    [stream close];

    if (bytesRead < 0) return nil; // 读取错误

    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &ctx);

    NSMutableString *result = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    return [result copy];
}

// ========== 图片操作 ==========

+ (nullable UIImage *)readImageFromFile:(nullable NSString *)filePath {
    if (![self fileExistsAtPath:filePath]) return nil;

    return [UIImage imageWithContentsOfFile:filePath];
}

+ (BOOL)saveImage:(nullable UIImage *)image
      toDirectory:(nullable NSString *)directory
         fileName:(nullable NSString *)fileName
            error:(NSError **)error {
    if (!image || _isEmptyString(directory) || _isEmptyString(fileName)) {
        if (error) *error = _fileError(-1, @"Image, directory, or fileName is nil or empty");
        return NO;
    }

    // 确保目录存在
    if (![self safeCreateDirectoryAtPath:directory error:error]) {
        return NO;
    }

    NSString *filePath = [directory stringByAppendingPathComponent:fileName];

    NSString *ext = [[fileName pathExtension] lowercaseString];
    NSData *imageData;
    if ([ext isEqualToString:@"png"]) {
        imageData = UIImagePNGRepresentation(image);
    } else {
        imageData = UIImageJPEGRepresentation(image, kJPEGCompressionQuality);
    }
    if (!imageData) {
        if (error) *error = _fileError(-5, @"Failed to generate image data");
        return NO;
    }

    return [imageData writeToFile:filePath options:NSDataWritingAtomic error:error];
}

@end
