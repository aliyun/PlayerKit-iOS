//
//  QRScannerViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "QRScannerViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface QRScannerViewController () <AVCaptureMetadataOutputObjectsDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) UIView *scanOverlay;

@end

@implementation QRScannerViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.title = @"扫码";
    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                     target:self
                                                     action:@selector(cancelTapped)];
    [self checkCameraPermission];
    [self addNotification];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    if (self.captureSession && !self.captureSession.isRunning) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.captureSession startRunning];
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopCamera];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.previewLayer.frame = self.view.bounds;
}

#pragma mark - Notification

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)appDidEnterBackground {
    [self stopCamera];
}

- (void)appWillEnterForeground {
    [self setupCamera];
}

#pragma mark - Permission

- (void)checkCameraPermission {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusAuthorized:
            [self setupCamera];
            break;
        case AVAuthorizationStatusNotDetermined: {
            __weak typeof(self) weakSelf = self;
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        [weakSelf setupCamera];
                    } else {
                        [weakSelf showPermissionDeniedAlert];
                    }
                });
            }];
            break;
        }
        default:
            [self showPermissionDeniedAlert];
            break;
    }
}

- (void)showPermissionDeniedAlert {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"提示"
                        message:@"当前没有摄像头权限，请在设置中打开摄像头权限"
                 preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"去设置"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
        [self dismissSelf];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Camera

- (void)setupCamera {
    if (self.captureSession) {
        return;
    }

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!device) {
        [self dismissSelf];
        return;
    }

    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) {
        [self dismissSelf];
        return;
    }

    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];

    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    [self.captureSession addInput:input];
    [self.captureSession addOutput:output];

    output.metadataObjectTypes = @[
        AVMetadataObjectTypeQRCode,
        AVMetadataObjectTypeEAN13Code,
        AVMetadataObjectTypeEAN8Code,
        AVMetadataObjectTypeCode128Code,
    ];

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.previewLayer];

    [self setupScanOverlay];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.captureSession startRunning];
    });
}

- (void)stopCamera {
    [self.captureSession stopRunning];
    self.captureSession = nil;
    [self.previewLayer removeFromSuperlayer];
    self.previewLayer = nil;
}

#pragma mark - Overlay

- (void)setupScanOverlay {
    CGFloat screenW = self.view.bounds.size.width;
    CGFloat screenH = self.view.bounds.size.height;
    CGFloat scanSize = screenW * 0.7;
    CGFloat scanX = (screenW - scanSize) / 2.0;
    CGFloat scanY = screenH * 0.24;
    CGRect scanRect = CGRectMake(scanX, scanY, scanSize, scanSize);

    self.scanOverlay = [[UIView alloc] initWithFrame:self.view.bounds];
    self.scanOverlay.userInteractionEnabled = NO;
    [self.view addSubview:self.scanOverlay];

    // Semi-transparent mask with transparent center
    CALayer *topLayer = [CALayer layer];
    topLayer.frame = CGRectMake(0, 0, screenW, scanY);
    topLayer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4].CGColor;
    [self.scanOverlay.layer addSublayer:topLayer];

    CALayer *leftLayer = [CALayer layer];
    leftLayer.frame = CGRectMake(0, scanY, scanX, scanSize);
    leftLayer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4].CGColor;
    [self.scanOverlay.layer addSublayer:leftLayer];

    CALayer *rightLayer = [CALayer layer];
    rightLayer.frame = CGRectMake(CGRectGetMaxX(scanRect), scanY, screenW - CGRectGetMaxX(scanRect), scanSize);
    rightLayer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4].CGColor;
    [self.scanOverlay.layer addSublayer:rightLayer];

    CALayer *bottomLayer = [CALayer layer];
    bottomLayer.frame = CGRectMake(0, CGRectGetMaxY(scanRect), screenW, screenH - CGRectGetMaxY(scanRect));
    bottomLayer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4].CGColor;
    [self.scanOverlay.layer addSublayer:bottomLayer];

    // Scan frame border
    CALayer *borderLayer = [CALayer layer];
    borderLayer.frame = scanRect;
    borderLayer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6].CGColor;
    borderLayer.borderWidth = 0.7;
    [self.scanOverlay.layer addSublayer:borderLayer];

    // Corner indicators
    CGFloat cornerLen = 20.0;
    CGFloat cornerWidth = 3.0;
    UIColor *cornerColor = [UIColor whiteColor];
    NSArray<NSValue *> *corners = @[
        [NSValue valueWithCGPoint:scanRect.origin],
        [NSValue valueWithCGPoint:CGPointMake(CGRectGetMaxX(scanRect), scanY)],
        [NSValue valueWithCGPoint:CGPointMake(scanX, CGRectGetMaxY(scanRect))],
        [NSValue valueWithCGPoint:CGPointMake(CGRectGetMaxX(scanRect), CGRectGetMaxY(scanRect))],
    ];
    BOOL hDirections[] = {YES, NO, YES, NO};
    BOOL vDirections[] = {YES, YES, NO, NO};

    for (NSUInteger i = 0; i < corners.count; i++) {
        CGPoint pt = corners[i].CGPointValue;
        CGFloat hOffset = hDirections[i] ? 0 : -cornerLen;
        CGFloat vOffset = vDirections[i] ? 0 : -cornerLen;

        CALayer *h = [CALayer layer];
        h.frame = CGRectMake(pt.x + hOffset, pt.y + (vDirections[i] ? 0 : -cornerWidth), cornerLen, cornerWidth);
        h.backgroundColor = cornerColor.CGColor;
        [self.scanOverlay.layer addSublayer:h];

        CALayer *v = [CALayer layer];
        v.frame = CGRectMake(pt.x + (hDirections[i] ? 0 : -cornerWidth), pt.y + vOffset, cornerWidth, cornerLen);
        v.backgroundColor = cornerColor.CGColor;
        [self.scanOverlay.layer addSublayer:v];
    }

    // Hint label
    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.text = @"将二维码放入框内，即可自动扫描";
    hintLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    hintLabel.font = [UIFont systemFontOfSize:13];
    hintLabel.textAlignment = NSTextAlignmentCenter;
    hintLabel.frame = CGRectMake(0, CGRectGetMaxY(scanRect) + 20, screenW, 25);
    [self.scanOverlay addSubview:hintLabel];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)output
    didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
              fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count == 0) return;

    AVMetadataMachineReadableCodeObject *code = metadataObjects.firstObject;
    if (code.stringValue.length > 0) {
        [self stopCamera];

        if (self.delegate && [self.delegate respondsToSelector:@selector(qrScanner:didScanResult:)]) {
            [self.delegate qrScanner:self didScanResult:code.stringValue];
        }
        [self dismissSelf];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
}

#pragma mark - Actions

- (void)cancelTapped {
    [self dismissSelf];
}

- (void)dismissSelf {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
