//
//  QRScannerViewController.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class QRScannerViewController;

/**
 * @brief QR 扫码结果回调协议。
 */
@protocol QRScannerDelegate <NSObject>

/**
 * @brief 扫码成功回调。
 *
 * @param scanner 扫码控制器。
 * @param result 扫码结果字符串。
 */
- (void)qrScanner:(QRScannerViewController *)scanner didScanResult:(NSString *)result;

@end

/**
 * @brief 二维码扫描控制器。
 *
 * @discussion 使用 AVFoundation 原生实现二维码扫描功能。
 *             自动检查相机权限，扫码结果通过 delegate 回调返回。
 *             对标 Android 端使用的 SimpleZxing CaptureActivity。
 *
 * @see QRScannerDelegate
 * @see LinkViewController
 */
@interface QRScannerViewController : UIViewController

/** @brief 扫码结果回调代理。 */
@property (nonatomic, weak, nullable) id<QRScannerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
