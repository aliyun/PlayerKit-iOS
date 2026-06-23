//
//  FullscreenViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/3/15.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "FullscreenViewController.h"

@interface FullscreenViewController ()

@property (nonatomic, assign) BOOL landscapeLocked;

@end

@implementation FullscreenViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
}

#pragma mark - Public

- (void)lockToLandscape {
    self.landscapeLocked = YES;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000
    if (@available(iOS 16.0, *)) {
        [self setNeedsUpdateOfSupportedInterfaceOrientations];
    }
#endif
}

- (void)unlockOrientation {
    self.landscapeLocked = NO;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000
    if (@available(iOS 16.0, *)) {
        [self setNeedsUpdateOfSupportedInterfaceOrientations];
    }
#endif
}

#pragma mark - Rotation

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.landscapeLocked
        ? UIInterfaceOrientationMaskLandscape
        : UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (self.rotationHandler) {
        self.rotationHandler(size, coordinator);
    }
}

#pragma mark - Status Bar & Home Indicator

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}
#endif

@end
