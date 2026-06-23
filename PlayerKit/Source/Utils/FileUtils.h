//
//  FileUtils.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/30.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 统一文件工具类。
 *
 * @discussion 提供文件和目录的常用操作方法，包括创建、删除、读写、校验等功能。
 */
@interface FileUtils : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

// ========== 存在性检查 ==========

/**
 * @brief 检查文件是否存在。
 *
 * @param path 文件路径。
 *
 * @return YES 如果文件存在，NO 否则。
 */
+ (BOOL)fileExistsAtPath:(nullable NSString *)path;

/**
 * @brief 检查目录是否存在。
 *
 * @param path 目录路径。
 *
 * @return YES 如果目录存在，NO 否则。
 */
+ (BOOL)directoryExistsAtPath:(nullable NSString *)path;

/**
 * @brief 检查路径是否存在（文件或目录）。
 *
 * @param path 路径。
 *
 * @return YES 如果路径存在，NO 否则。
 */
+ (BOOL)pathExistsAtPath:(nullable NSString *)path;

// ========== 路径操作 ==========

/**
 * @brief 获取文件所在目录路径。
 *
 * @param path 文件路径。
 *
 * @return 父目录路径，如果无法获取则返回空字符串。
 */
+ (NSString *)folderPathForFilePath:(nullable NSString *)path;

/**
 * @brief 获取文件名（包含扩展名）。
 *
 * @param path 文件路径。
 *
 * @return 文件名，如果无法获取则返回空字符串。
 */
+ (NSString *)fileNameForPath:(nullable NSString *)path;

/**
 * @brief 获取文件扩展名（不包含点号）。
 *
 * @param path 文件路径。
 *
 * @return 文件扩展名，如果没有扩展名则返回空字符串。
 */
+ (NSString *)fileExtensionForPath:(nullable NSString *)path;

/**
 * @brief 获取不包含扩展名的文件名。
 *
 * @param path 文件路径。
 *
 * @return 不包含扩展名的文件名，如果无法获取则返回空字符串。
 */
+ (NSString *)fileNameWithoutExtensionForPath:(nullable NSString *)path;

/**
 * @brief 组合多个路径组件。
 *
 * @param components 路径组件数组。
 *
 * @return 组合后的路径，如果数组为空则返回空字符串。
 */
+ (NSString *)combinePaths:(NSArray<NSString *> *)components;

// ========== 文件/目录创建 ==========

/**
 * @brief 安全创建目录。
 *
 * @discussion 如果目标路径是文件则先删除，然后创建目录（含中间目录）。
 *
 * @param path  目录路径。
 * @param error 错误输出。
 *
 * @return YES 如果创建成功或目录已存在，NO 否则。
 */
+ (BOOL)safeCreateDirectoryAtPath:(nullable NSString *)path error:(NSError **)error;

/**
 * @brief 安全创建文件。
 *
 * @discussion 如果目标路径是目录则先删除，确保父目录存在后创建文件。
 *
 * @param path  文件路径。
 * @param error 错误输出。
 *
 * @return YES 如果创建成功或文件已存在，NO 否则。
 */
+ (BOOL)safeCreateFileAtPath:(nullable NSString *)path error:(NSError **)error;

// ========== 存储路径获取 ==========

/**
 * @brief 获取 Documents 目录路径。
 *
 * @return Documents 目录路径。
 */
+ (NSString *)documentsDirectory;

/**
 * @brief 获取 Caches 目录路径。
 *
 * @return Caches 目录路径。
 */
+ (NSString *)cachesDirectory;

/**
 * @brief 获取临时目录路径。
 *
 * @return 临时目录路径。
 */
+ (NSString *)temporaryDirectory;

// ========== 文件读取 ==========

/**
 * @brief 从文件读取文本内容。
 *
 * @param filePath 文件路径。
 * @param error    错误输出。
 *
 * @return 文件文本内容，读取失败返回 nil。
 */
+ (nullable NSString *)readTextFromFile:(nullable NSString *)filePath error:(NSError **)error;

/**
 * @brief 从文件读取二进制数据。
 *
 * @param filePath 文件路径。
 * @param error    错误输出。
 *
 * @return 文件二进制数据，读取失败返回 nil。
 */
+ (nullable NSData *)readDataFromFile:(nullable NSString *)filePath error:(NSError **)error;

// ========== 文件写入 ==========

/**
 * @brief 写入文本到文件。
 *
 * @param text     要写入的文本。
 * @param filePath 文件路径。
 * @param error    错误输出。
 *
 * @return YES 如果写入成功，NO 否则。
 */
+ (BOOL)writeText:(nullable NSString *)text toFile:(nullable NSString *)filePath error:(NSError **)error;

/**
 * @brief 写入二进制数据到文件。
 *
 * @param data     要写入的数据。
 * @param filePath 文件路径。
 * @param error    错误输出。
 *
 * @return YES 如果写入成功，NO 否则。
 */
+ (BOOL)writeData:(nullable NSData *)data toFile:(nullable NSString *)filePath error:(NSError **)error;

// ========== 文件复制移动 ==========

/**
 * @brief 复制文件。
 *
 * @param sourcePath 源文件路径。
 * @param destPath   目标文件路径。
 * @param error      错误输出。
 *
 * @return YES 如果复制成功，NO 否则。
 */
+ (BOOL)copyFileFrom:(nullable NSString *)sourcePath to:(nullable NSString *)destPath error:(NSError **)error;

/**
 * @brief 移动文件。
 *
 * @param sourcePath 源文件路径。
 * @param destPath   目标文件路径。
 * @param error      错误输出。
 *
 * @return YES 如果移动成功，NO 否则。
 */
+ (BOOL)moveFileFrom:(nullable NSString *)sourcePath to:(nullable NSString *)destPath error:(NSError **)error;

// ========== 文件删除 ==========

/**
 * @brief 删除文件。
 *
 * @param filePath 文件路径。
 * @param error    错误输出。
 *
 * @return YES 如果删除成功或文件不存在，NO 否则。
 */
+ (BOOL)deleteFileAtPath:(nullable NSString *)filePath error:(NSError **)error;

/**
 * @brief 递归删除文件或目录。
 *
 * @param path  文件或目录路径。
 * @param error 错误输出。
 *
 * @return YES 如果删除成功，NO 否则。
 */
+ (BOOL)deleteRecursivelyAtPath:(nullable NSString *)path error:(NSError **)error;

/**
 * @brief 清空目录内容（保留目录本身）。
 *
 * @param path  目录路径。
 * @param error 错误输出。
 *
 * @return YES 如果清空成功，NO 否则。
 */
+ (BOOL)clearDirectoryAtPath:(nullable NSString *)path error:(NSError **)error;

// ========== 文件信息 ==========

/**
 * @brief 获取文件大小。
 *
 * @param filePath 文件路径。
 *
 * @return 文件大小（字节），如果文件不存在则返回 -1。
 */
+ (long long)fileSizeAtPath:(nullable NSString *)filePath;

/**
 * @brief 格式化文件大小。
 *
 * @discussion 支持 B/KB/MB/GB/TB 单位，保留两位小数。
 *
 * @param size 文件大小（字节）。
 *
 * @return 格式化后的文件大小字符串。
 */
+ (NSString *)formatFileSize:(long long)size;

/**
 * @brief 获取目录总大小（递归）。
 *
 * @param dirPath 目录路径。
 *
 * @return 目录总大小（字节），如果目录不存在则返回 -1。
 */
+ (long long)directorySizeAtPath:(nullable NSString *)dirPath;

// ========== 文件校验 ==========

/**
 * @brief 计算文件的 MD5 校验和。
 *
 * @param filePath 文件路径。
 *
 * @return MD5 校验和字符串（小写十六进制），计算失败返回 nil。
 */
+ (nullable NSString *)md5ChecksumForFileAtPath:(nullable NSString *)filePath;

/**
 * @brief 计算文件的 SHA-256 校验和。
 *
 * @param filePath 文件路径。
 *
 * @return SHA-256 校验和字符串（小写十六进制），计算失败返回 nil。
 */
+ (nullable NSString *)sha256ChecksumForFileAtPath:(nullable NSString *)filePath;

// ========== 图片操作 ==========

/**
 * @brief 从文件读取图片。
 *
 * @param filePath 图片文件路径。
 *
 * @return UIImage 对象，读取失败返回 nil。
 */
+ (nullable UIImage *)readImageFromFile:(nullable NSString *)filePath;

/**
 * @brief 保存图片到指定目录。
 *
 * @discussion 以 JPEG 格式保存，确保目录存在后写入。
 *
 * @param image     要保存的图片。
 * @param directory 目标目录路径。
 * @param fileName  文件名（含扩展名）。
 * @param error     错误输出。
 *
 * @return YES 如果保存成功，NO 否则。
 */
+ (BOOL)saveImage:(nullable UIImage *)image
      toDirectory:(nullable NSString *)directory
         fileName:(nullable NSString *)fileName
            error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
