//
//  SlotHostLayout.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SlotHostLayout.h"
#import "SlotType.h"
#import "SlotProtocol.h"
#import "SlotConfig.h"
#import "SlotManager.h"
#import "SlotManager+Private.h"
#import "CustomSlotType.h"
#import "BaseSlot.h"
#import "AliPlayerController.h"
#import "AliPlayerController+Private.h"
#import "AliPlayerModel.h"
#import "AliPlayerView.h"
#import "PlayerStateStore.h"
#import "PlayerViewState.h"
#import "GestureControlSlot.h"
#import "CenterDisplaySlot.h"
#import "TopBarSlot.h"
#import "BottomBarSlot.h"
#import "GestureNotificationDelegate.h"
#import "GestureNotificationDispatcher.h"
#import "SlotActionNotificationDispatcher.h"
#import "Log.h"
#import "../Utils/PlayerLayout+Private.h"

@interface SlotHostLayout ()

@property (nonatomic, weak, nullable) AliPlayerController *controller;
@property (nonatomic, strong, nullable) AliPlayerModel *currentModel;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIView<SlotProtocol> *> *slotViews;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIView<SlotProtocol> *> *customSlotViews;
@property (nonatomic, strong, nullable) SlotManager *slotManager;
@property (nonatomic, strong) SlotActionNotificationDispatcher *slotActionDispatcher;

@end

@implementation SlotHostLayout

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _slotViews = [NSMutableDictionary dictionary];
        _customSlotViews = [NSMutableDictionary dictionary];
        _slotActionDispatcher = [[SlotActionNotificationDispatcher alloc] init];
        self.clipsToBounds = YES;

        SLOGI(@"[LC][init] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
    }
    return self;
}

- (void)dealloc {
    SLOGI(@"[LC][dealloc] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints {
    // 读取保留区，跟踪 bounds 不变时的保留区变化。
    PlayerLayoutReadableRect(self, self.bounds, YES);
    [self setNeedsLayout];
    [super updateConstraints];
}

- (void)safeAreaInsetsDidChange {
    [super safeAreaInsetsDidChange];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = PlayerLayoutReadableRect(self, self.bounds, NO);
    UIEdgeInsets safeArea = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeArea = self.safeAreaInsets;
    }
    for (UIView<SlotProtocol> *slotView in [self allSlotViews]) {
        slotView.frame = [self frameForSlot:slotView bounds:bounds safeArea:safeArea];
    }
}

- (CGRect)frameForSlot:(UIView<SlotProtocol> *)slotView
                bounds:(CGRect)bounds
              safeArea:(UIEdgeInsets)safeArea {
    SlotSafeAreaEdge edges = [slotView respondsToSelector:@selector(safeAreaEdges)]
        ? slotView.safeAreaEdges : SlotSafeAreaEdgeNone;
    BOOL avoidsOcclusion = [slotView respondsToSelector:@selector(avoidsOcclusion)]
        ? slotView.avoidsOcclusion : edges != SlotSafeAreaEdgeNone;
    return [self frameForEdges:edges bounds:bounds safeArea:safeArea avoidsOcclusion:avoidsOcclusion];
}

- (CGRect)frameForEdges:(SlotSafeAreaEdge)edges
                 bounds:(CGRect)bounds
               safeArea:(UIEdgeInsets)safeArea
        avoidsOcclusion:(BOOL)avoidsOcclusion {
    CGRect safeBounds = self.bounds;
    if (edges & SlotSafeAreaEdgeTop) {
        safeBounds.origin.y += safeArea.top;
        safeBounds.size.height -= safeArea.top;
    }
    if (edges & SlotSafeAreaEdgeLeft) {
        safeBounds.origin.x += safeArea.left;
        safeBounds.size.width -= safeArea.left;
    }
    if (edges & SlotSafeAreaEdgeBottom) {
        safeBounds.size.height -= safeArea.bottom;
    }
    if (edges & SlotSafeAreaEdgeRight) {
        safeBounds.size.width -= safeArea.right;
    }
    safeBounds.size.width = MAX(0, safeBounds.size.width);
    safeBounds.size.height = MAX(0, safeBounds.size.height);
    CGRect frame = PlayerLayoutIntersection(bounds, safeBounds);
    return avoidsOcclusion ? PlayerLayoutReadableRect(self, frame, YES) : frame;
}

- (CGRect)readableContentBoundsForSlot:(UIView<SlotProtocol> *)slotView {
    UIEdgeInsets safeArea = UIEdgeInsetsZero;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
    if (@available(iOS 11.0, *)) {
        safeArea = self.safeAreaInsets;
    }
#endif
    CGRect bounds = PlayerLayoutReadableRect(self, self.bounds, NO);
    CGRect frame = [self frameForEdges:SlotSafeAreaEdgeAll bounds:bounds
                             safeArea:safeArea avoidsOcclusion:YES];
    CGRect localFrame = [slotView convertRect:frame fromView:self];
    return PlayerLayoutIntersection(slotView.bounds, localFrame);
}

#pragma mark - Public Methods

- (void)bindController:(AliPlayerController *)controller {
    SLOGI(@"bindController: %@ -> %@", self.controller, controller);
    self.controller = controller;
}

- (void)bindSlotManager:(SlotManager *)slotManager {
    self.slotManager = slotManager;
    [slotManager bindHostLayout:self];
}

- (void)unbind {
    SLOGI(@"unbind, %@ -> nil", self.controller);
    [self detachAllSlots];
    self.controller = nil;
    self.currentModel = nil;
    self.backPressedHandler = nil;
}

- (void)rebuildSlots {
    AliPlayerController *controller = self.controller;
    if (!controller) {
        SLOGW(@"Controller already released, skipping rebuild");
        return;
    }
    SLOGI(@"Rebuilding slots...");

    [self detachAllSlots];

    if (!self.slotManager) {
        SLOGW(@"No SlotManager available, skipping rebuild");
        return;
    }

    // 收集内置插槽条目（order = SlotType 枚举值）
    NSMutableArray<NSDictionary *> *entries = [NSMutableArray array];

    NSArray<NSNumber *> *builtinTypes = SlotTypeAllBuiltinTypes();
    for (NSNumber *typeNumber in builtinTypes) {
        SlotType type = (SlotType)[typeNumber integerValue];

        if ([self.slotManager isSlotHidden:type]) {
            continue;
        }

        SlotConfig *config = [self.slotManager slotConfigForType:type];
        if (config && ![config isVisibleInScene:self.sceneType]) {
            continue;
        }

        [entries addObject:@{
            @"kind": @"builtin",
            @"order": typeNumber,
            @"type": typeNumber
        }];
    }

    // 收集自定义插槽条目
    NSArray<CustomSlotType *> *customTypes = [self.slotManager registeredCustomSlotTypes];
    for (CustomSlotType *customType in customTypes) {
        [entries addObject:@{
            @"kind": @"custom",
            @"order": @(customType.order),
            @"customType": customType
        }];
    }

    // 按 order 统一排序
    [entries sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[@"order"] compare:b[@"order"]];
    }];

    // 按排序后的顺序构建插槽
    for (NSDictionary *entry in entries) {
        if ([entry[@"kind"] isEqualToString:@"builtin"]) {
            SlotType type = (SlotType)[entry[@"type"] integerValue];
            UIView<SlotProtocol> *slotView = [self.slotManager buildSlotForType:type parentView:self];
            if (slotView) {
                if ([slotView isKindOfClass:[BaseSlot class]]) {
                    ((BaseSlot *)slotView).slotType = type;
                }
                self.slotViews[@(type)] = slotView;
                [self addSubview:slotView];
                slotView.frame = self.bounds;
                [slotView onAttach:self];
                SLOGI(@"Built and attached slot: %@", SlotTypeName(type));
            }
        } else {
            CustomSlotType *customType = entry[@"customType"];
            UIView<SlotProtocol> *slotView = [self.slotManager buildCustomSlotForType:customType parentView:self];
            if (slotView) {
                self.customSlotViews[customType.key] = slotView;
                [self addSubview:slotView];
                slotView.frame = self.bounds;
                [slotView onAttach:self];
                SLOGI(@"Built and attached custom slot: %@", customType.key);
            }
        }
    }

    [self wireGestureNotifications];
    [self wireSlotActionNotifications];

    if (self.currentModel) {
        [self bindData:self.currentModel];
    }

    [self setNeedsLayout];
    NSUInteger total = self.slotViews.count + self.customSlotViews.count;
    SLOGI(@"Rebuild complete, %lu slots attached", (unsigned long)total);
}

- (void)bindData:(AliPlayerModel *)model {
    self.currentModel = model;
    for (UIView<SlotProtocol> *slotView in [self allSlotViews]) {
        if ([self canBindSlotContent:slotView]) {
            [slotView onBindData:model];
        }
    }
    NSUInteger total = self.slotViews.count + self.customSlotViews.count;
    SLOGI(@"Data bound to %lu slots", (unsigned long)total);
}

- (void)unbindData {
    for (UIView<SlotProtocol> *slotView in [self allSlotViews]) {
        if ([self canBindSlotContent:slotView]) {
            [slotView onUnbindData];
        }
    }
    self.currentModel = nil;
    SLOGI(@"Data unbound from all slots");
}

#pragma mark - SlotHost Protocol

- (void)notifyBackPressed {
    if (self.backPressedHandler) {
        self.backPressedHandler();
        SLOGI(@"Back pressed - notified external handler");
        return;
    }

    // 未设置 handler 时，执行原有操作：通过 responder chain 执行默认导航
    UIResponder *responder = self;
    while (responder && ![responder isKindOfClass:[UIViewController class]]) {
        responder = [responder nextResponder];
    }
    UIViewController *vc = (UIViewController *)responder;
    if (!vc) return;
    if (vc.navigationController) {
        [vc.navigationController popViewControllerAnimated:YES];
    } else if (vc.presentingViewController) {
        [vc dismissViewControllerAnimated:YES completion:nil];
    }
    SLOGI(@"Back pressed - navigate back (default)");
}

- (UIView *)hostView {
    return self;
}

- (nullable AliPlayerModel *)model {
    return self.currentModel;
}

- (void)setRenderView:(nullable UIView *)renderView {
    if (self.controller) {
        [self.controller bindRenderView:renderView];
        SLOGI(@"Render view %@ to controller", renderView ? @"bound" : @"unbound");
    }
}

- (PlayerStateStore *)playerStateStore {
    return self.controller.stateStore;
}

- (PlayerViewState *)viewState {
    return self.controller.playerView.viewState;
}

- (void)dismissSlotView:(UIView<SlotProtocol> *)slotView {
    if (!slotView) {
        return;
    }

    // 按实例查找归属，避免自定义 BaseSlot 的 slotType 误指向内置插槽。
    NSNumber *keyToRemove = nil;
    NSString *customKeyToRemove = nil;
    for (NSNumber *key in self.slotViews.allKeys) {
        if (self.slotViews[key] == slotView) {
            keyToRemove = key;
            break;
        }
    }
    if (keyToRemove) {
        [self.slotViews removeObjectForKey:keyToRemove];
    } else {
        for (NSString *key in self.customSlotViews.allKeys) {
            if (self.customSlotViews[key] == slotView) {
                customKeyToRemove = key;
                break;
            }
        }
        if (!customKeyToRemove) return;
        [self.customSlotViews removeObjectForKey:customKeyToRemove];
    }

    [slotView onDetach];
    [slotView removeFromSuperview];
    SLOGI(@"Dismissed slot: %@", keyToRemove ? SlotTypeName((SlotType)[keyToRemove integerValue]) : @"custom");
}

- (NSArray<UIView<SlotProtocol> *> *)allSlotViews {
    NSMutableArray *all = [NSMutableArray arrayWithArray:self.slotViews.allValues];
    [all addObjectsFromArray:self.customSlotViews.allValues];
    return [all copy];
}

- (nullable UIView<SlotProtocol> *)slotViewForType:(SlotType)slotType {
    return self.slotViews[@(slotType)];
}

#pragma mark - Private Methods

- (BOOL)canBindSlotContent:(UIView<SlotProtocol> *)slotView {
    if (![slotView isKindOfClass:[BaseSlot class]]) return YES;
    BaseSlot *slot = (BaseSlot *)slotView;
    return !slot.deferContentCreation || slot.contentReady;
}

- (void)wireGestureNotifications {
    UIView<SlotProtocol> *gestureSlotView = self.slotViews[@(SlotTypeGestureControl)];
    UIView<SlotProtocol> *centerDisplaySlotView = self.slotViews[@(SlotTypeCenterDisplay)];

    if (!gestureSlotView || !centerDisplaySlotView) return;
    if (![gestureSlotView isKindOfClass:[GestureControlSlot class]]) return;
    if (![centerDisplaySlotView isKindOfClass:[CenterDisplaySlot class]]) return;

    GestureControlSlot *gestureSlot = (GestureControlSlot *)gestureSlotView;
    CenterDisplaySlot *centerSlot = (CenterDisplaySlot *)centerDisplaySlotView;
    centerSlot.gestureDispatcher = gestureSlot.gestureDispatcher;
    SLOGI(@"Wired CenterDisplaySlot as gesture notification observer");

    UIView<SlotProtocol> *topBarSlotView = self.slotViews[@(SlotTypeTopBar)];
    if ([topBarSlotView isKindOfClass:[TopBarSlot class]]) {
        ((TopBarSlot *)topBarSlotView).gestureDispatcher = gestureSlot.gestureDispatcher;
        SLOGI(@"Wired TopBarSlot as gesture notification observer");
    }

    UIView<SlotProtocol> *bottomBarSlotView = self.slotViews[@(SlotTypeBottomBar)];
    if ([bottomBarSlotView isKindOfClass:[BottomBarSlot class]]) {
        ((BottomBarSlot *)bottomBarSlotView).gestureDispatcher = gestureSlot.gestureDispatcher;
        SLOGI(@"Wired BottomBarSlot as gesture notification observer");
    }
}

/**
 * @brief 把统一的 Slot 操作事件总线注入所有插槽。
 *
 * @discussion 事件生产者（TopBar、BottomBar 等）借此发送事件；
 *             遵循 SlotActionNotificationDelegate 的插槽由 BaseSlot 的 setter
 *             自动注册为观察者，无需在此逐个枚举。
 *
 * @see BaseSlot.slotActionDispatcher
 */
- (void)wireSlotActionNotifications {
    NSArray<UIView<SlotProtocol> *> *slots = [self allSlotViews];
    for (UIView<SlotProtocol> *slotView in slots) {
        if ([slotView isKindOfClass:[BaseSlot class]]) {
            ((BaseSlot *)slotView).slotActionDispatcher = self.slotActionDispatcher;
        }
    }
    SLOGI(@"Wired %lu slots to slot action dispatcher", (unsigned long)slots.count);
}

- (void)detachAllSlots {
    for (NSNumber *key in self.slotViews) {
        UIView<SlotProtocol> *slotView = self.slotViews[key];
        [slotView onDetach];
        [slotView removeFromSuperview];
        SLOGI(@"Detached slot: %@", SlotTypeName((SlotType)[key integerValue]));
    }
    [self.slotViews removeAllObjects];

    for (NSString *key in self.customSlotViews) {
        UIView<SlotProtocol> *slotView = self.customSlotViews[key];
        [slotView onDetach];
        [slotView removeFromSuperview];
        SLOGI(@"Detached custom slot: %@", key);
    }
    [self.customSlotViews removeAllObjects];
}

- (void)setSceneType:(SceneType)sceneType {
    if (_sceneType == sceneType) {
        return;
    }
    _sceneType = sceneType;
    if (self.slotManager) {
        [self rebuildSlots];
    }
}

@end
