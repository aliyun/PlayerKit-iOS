//
//  PlayerSurfaceSlot.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "PlayerSurfaceSlot.h"
#import "Log.h"

@implementation PlayerSurfaceSlot

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.safeAreaEdges = SlotSafeAreaEdgeNone;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    for (UIView *subview in self.subviews) {
        subview.frame = self.bounds;
    }
}

#pragma mark - Slot Protocol

- (void)onAttach:(id<SlotHost>)host {
    [super onAttach:host];
    // 直接使用自身作为渲染视图
    [host setRenderView:self];
}

- (void)onDetach {
    // 分离前从宿主解绑渲染视图
    [self.host setRenderView:nil];
    [super onDetach];
}

@end
