//
//  CoverSlot.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "CoverSlot.h"
#import "AliPlayerModel.h"
#import "PlayerNotificationDelegate.h"
#import "Log.h"

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
#import <SDWebImage/UIImageView+WebCache.h>
#define PLAYERKIT_SDWEBIMAGE_AVAILABLE 1
#else
#define PLAYERKIT_SDWEBIMAGE_AVAILABLE 0
#endif

@interface CoverSlot () <PlayerNotificationDelegate>

@property (nonatomic, strong) UIImageView *coverImageView;

@end

@implementation CoverSlot

#pragma mark - Slot Lifecycle

- (void)setupContentView {
    self.coverImageView = [[UIImageView alloc] init];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverImageView.clipsToBounds = YES;
    self.coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.coverImageView];

    [NSLayoutConstraint activateConstraints:@[
        [self.coverImageView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.coverImageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.coverImageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.coverImageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    ]];
}

- (void)onBindData:(AliPlayerModel *)model {
    [super onBindData:model];

    NSString *coverUrl = model.coverUrl;
    if (coverUrl && coverUrl.length > 0) {
        [self loadCoverWithURL:coverUrl];
        [self show];
    } else {
        SLOGI(@"No cover URL, hiding cover slot");
        [self hide];
    }
}

- (void)onUnbindData {
#if PLAYERKIT_SDWEBIMAGE_AVAILABLE
    [self.coverImageView sd_cancelCurrentImageLoad];
#endif
    self.coverImageView.image = nil;
    [self hide];
    [super onUnbindData];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidRenderFirstFrame {
    SLOGI(@"First frame rendered, hiding cover");
    [self hideWithAnimation:YES];
}

#pragma mark - Private Methods

- (void)loadCoverWithURL:(NSString *)urlString {
    SLOGI(@"Loading cover: %@", urlString);

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        SLOGW(@"Invalid cover URL: %@", urlString);
        [self hide];
        return;
    }

#if PLAYERKIT_SDWEBIMAGE_AVAILABLE
    [self.coverImageView sd_setImageWithURL:url
                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (error) {
            // 若提示 App Transport Security 错误，请在宿主 App 的 Info.plist 中添加：
            // <key>NSAppTransportSecurity</key>
            // <dict><key>NSAllowsArbitraryLoads</key><true/></dict>
            SLOGW(@"Cover load failed: %@", error.localizedDescription);
        } else {
            SLOGI(@"Cover image loaded successfully");
        }
    }];
#else
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *image = data ? [UIImage imageWithData:data] : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) {
                self.coverImageView.image = image;
                SLOGI(@"Cover image loaded successfully");
            } else {
                SLOGW(@"Cover load failed");
            }
        });
    });
#endif
}

@end
