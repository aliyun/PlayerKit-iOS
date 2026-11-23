//
//  PlayerLayout+Private.h
//  AliPlayerKit
//
//  Created by keria on 2026/11/10.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#ifndef PlayerLayout_Private_h
#define PlayerLayout_Private_h

#import <UIKit/UIKit.h>

/**
 * @brief 求 bounds 内避开所有指定矩形的最大连续区域。
 * @discussion 矩形须使用同一坐标系；等面积时优先上侧、左侧，再选择较宽区域。
 * @param bounds 原始布局区域。
 * @param rects 需要避让的矩形集合。
 * @return 可用区域；全部被遮挡时返回空矩形。
 */
static inline CGRect PlayerLayoutRectExcludingRects(CGRect bounds, NSArray<NSValue *> *rects) {
    if (CGRectIsEmpty(bounds) || rects.count == 0) {
        return bounds;
    }
    NSMutableArray<NSValue *> *obstacles = [NSMutableArray array];
    NSMutableArray<NSNumber *> *xEdges = [NSMutableArray arrayWithObjects:
                                         @(CGRectGetMinX(bounds)), @(CGRectGetMaxX(bounds)), nil];
    for (NSValue *value in rects) {
        CGRect intersection = CGRectIntersection(bounds, value.CGRectValue);
        if (CGRectIsNull(intersection) || CGRectIsEmpty(intersection)) {
            continue;
        }
        [obstacles addObject:[NSValue valueWithCGRect:intersection]];
        [xEdges addObject:@(CGRectGetMinX(intersection))];
        [xEdges addObject:@(CGRectGetMaxX(intersection))];
    }
    if (obstacles.count == 0) {
        return bounds;
    }
    [xEdges sortUsingSelector:@selector(compare:)];
    NSMutableArray<NSNumber *> *uniqueX = [NSMutableArray array];
    for (NSNumber *x in xEdges) {
        if (uniqueX.count == 0 || x.doubleValue != uniqueX.lastObject.doubleValue) {
            [uniqueX addObject:x];
        }
    }
    // 按 minY 排序后线性合并 y 区间，总复杂度为 O(n^3) 时间、O(n) 空间。
    [obstacles sortUsingComparator:^NSComparisonResult(NSValue *a, NSValue *b) {
        CGFloat aY = CGRectGetMinY(a.CGRectValue);
        CGFloat bY = CGRectGetMinY(b.CGRectValue);
        return aY < bY ? NSOrderedAscending : (aY > bY ? NSOrderedDescending : NSOrderedSame);
    }];
    CGRect result = CGRectMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds), 0, 0);
    CGFloat largestArea = 0;
    // 最大矩形的 x 边缘必位于 bounds 或障碍边界，只需枚举边界对。
    for (NSUInteger left = 0; left + 1 < uniqueX.count; left++) {
        for (NSUInteger right = left + 1; right < uniqueX.count; right++) {
            CGFloat minX = uniqueX[left].doubleValue;
            CGFloat maxX = uniqueX[right].doubleValue;
            CGFloat cursorY = CGRectGetMinY(bounds);
            CGFloat gapMinY = cursorY;
            CGFloat gapHeight = 0;
            for (NSValue *value in obstacles) {
                CGRect obstacle = value.CGRectValue;
                // 仅接触边缘不算遮挡；cursorY 合并连续的阻塞区间。
                if (CGRectGetMinX(obstacle) >= maxX || CGRectGetMaxX(obstacle) <= minX) {
                    continue;
                }
                CGFloat height = CGRectGetMinY(obstacle) - cursorY;
                if (height > gapHeight) {
                    gapMinY = cursorY;
                    gapHeight = height;
                }
                cursorY = MAX(cursorY, CGRectGetMaxY(obstacle));
            }
            CGFloat height = CGRectGetMaxY(bounds) - cursorY;
            if (height > gapHeight) {
                gapMinY = cursorY;
                gapHeight = height;
            }
            CGFloat width = maxX - minX;
            CGFloat area = width * gapHeight;
            // 等面积时固定选择顺序，避免结果依赖保留区的枚举顺序。
            BOOL preferredTie = area == largestArea && area > 0 &&
                (gapMinY < CGRectGetMinY(result) ||
                 (gapMinY == CGRectGetMinY(result) &&
                  (minX < CGRectGetMinX(result) ||
                   (minX == CGRectGetMinX(result) && width > CGRectGetWidth(result)))));
            if (area > largestArea || preferredTie) {
                largestArea = area;
                result = CGRectMake(minX, gapMinY, width, gapHeight);
            }
        }
    }
    return result;
}

/**
 * @brief 返回视图内避开系统保留区的连续布局区域。
 * @discussion 始终避开分区保留区，按需避开遮挡保留区；系统 frame 已含 margins。
 *             在 updateConstraints 中读取以跟踪保留区变化；不支持该 API 时返回 bounds。
 * @param view 提供保留区的视图。
 * @param bounds 待布局区域，使用 view 坐标系。
 * @param avoidOcclusion 是否额外避开摄像头等遮挡区域。
 * @return view 坐标系内的可用区域。
 * @warning 必须在主线程调用。
 * @see PlayerLayoutRectExcludingRects
 */
static inline CGRect PlayerLayoutReadableRect(UIView *view, CGRect bounds, BOOL avoidOcclusion) {
#if defined(__IPHONE_27_1) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_27_1
    if (@available(iOS 27.1, *)) {
        NSMutableArray<NSValue *> *rects = [NSMutableArray array];
        for (UIViewReservedRegion *region in [view reservedRegionsOfKind:[UIViewReservedRegionKind divisionRegionKind]]) {
            [rects addObject:[NSValue valueWithCGRect:region.frame]];
        }
        if (avoidOcclusion) {
            for (UIViewReservedRegion *region in [view reservedRegionsOfKind:[UIViewReservedRegionKind occlusionRegionKind]]) {
                [rects addObject:[NSValue valueWithCGRect:region.frame]];
            }
        }
        return PlayerLayoutRectExcludingRects(bounds, rects);
    }
#else
    (void)view;
    (void)avoidOcclusion;
#endif
    return bounds;
}

/**
 * @brief 判断当前可用区域是否适合默认展开控制组合。
 * @discussion 底栏与菜单共用此规则，不约束其他插槽的布局。
 * @param fullscreen 当前是否为全屏状态。
 * @param bounds 当前可用区域。
 * @return 全屏且空间满足展开组合要求时返回 YES。
 */
static inline BOOL PlayerLayoutUsesExpandedControls(BOOL fullscreen, CGRect bounds) {
    return fullscreen && CGRectGetWidth(bounds) >= 320.0 && CGRectGetHeight(bounds) >= 200.0;
}

/**
 * @brief 求同一坐标系内两个布局区域的交集。
 * @discussion 用于区域裁剪，避免将宿主 Safe Area 的 insets 重复施加到分区边缘。
 * @param bounds 待裁剪区域。
 * @param safeBounds 限制区域。
 * @return 交集；不相交时返回位于 bounds 原点的空矩形。
 */
static inline CGRect PlayerLayoutIntersection(CGRect bounds, CGRect safeBounds) {
    CGRect result = CGRectIntersection(bounds, safeBounds);
    if (CGRectIsNull(result)) {
        return CGRectMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds), 0, 0);
    }
    return result;
}

#endif
