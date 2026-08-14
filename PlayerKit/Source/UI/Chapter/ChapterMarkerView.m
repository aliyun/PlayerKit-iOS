//
//  ChapterMarkerView.m
//  AliPlayerKit
//
//  Created by keria on 2026/8/3.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "ChapterMarkerView.h"

#pragma mark - Constants

/// 章节标记竖线宽度
static const CGFloat kMarkerLineWidth = 2.5;

/// 章节标记竖线颜色 alpha
static const CGFloat kMarkerColorAlpha = 0.78;

@interface ChapterMarkerView ()

@property (nonatomic, copy) NSArray<NSNumber *> *positions;

@end

@implementation ChapterMarkerView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}

#pragma mark - Public Methods

- (void)setMarkerPositions:(NSArray<NSNumber *> *)positions {
    _positions = [positions copy];
    [self setNeedsDisplay];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    if (self.positions.count == 0) return;

    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    if (width <= 0 || height <= 0) return;

    UIColor *markerColor = [UIColor colorWithWhite:1.0 alpha:kMarkerColorAlpha];
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = kMarkerLineWidth;
    [markerColor setStroke];

    for (NSNumber *posNumber in self.positions) {
        CGFloat pos = posNumber.floatValue;
        // 过滤 pos <= 0 || pos >= 1
        if (pos <= 0.0 || pos >= 1.0) continue;
        CGFloat x = pos * width;
        [path moveToPoint:CGPointMake(x, 0)];
        [path addLineToPoint:CGPointMake(x, height)];
    }

    [path stroke];
}

@end
