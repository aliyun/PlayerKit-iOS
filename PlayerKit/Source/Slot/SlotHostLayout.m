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
#import "SettingMenuSlot.h"
#import "Log.h"

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

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.bounds;
    SLOGI(@"layoutSubviews: bounds = %@, superview.bounds = %@",
          NSStringFromCGRect(bounds), NSStringFromCGRect(self.superview.bounds));
    
    UIEdgeInsets safeArea = self.safeAreaInsets;
    for (UIView<SlotProtocol> *slotView in self.slotViews.allValues) {
        slotView.frame = [self frameForSlot:slotView bounds:bounds safeArea:safeArea];
    }
    for (UIView<SlotProtocol> *slotView in self.customSlotViews.allValues) {
        slotView.frame = [self frameForSlot:slotView bounds:bounds safeArea:safeArea];
    }
}

- (CGRect)frameForSlot:(UIView<SlotProtocol> *)slotView
                bounds:(CGRect)bounds
              safeArea:(UIEdgeInsets)safeArea {
    if (![slotView isKindOfClass:[BaseSlot class]]) {
        return bounds;
    }
    SlotSafeAreaEdge edges = ((BaseSlot *)slotView).safeAreaEdges;
    if (edges == SlotSafeAreaEdgeNone) {
        return bounds;
    }
    CGRect frame = bounds;
    if (edges & SlotSafeAreaEdgeTop) {
        frame.origin.y += safeArea.top;
        frame.size.height -= safeArea.top;
    }
    if (edges & SlotSafeAreaEdgeLeft) {
        frame.origin.x += safeArea.left;
        frame.size.width -= safeArea.left;
    }
    if (edges & SlotSafeAreaEdgeBottom) {
        frame.size.height -= safeArea.bottom;
    }
    if (edges & SlotSafeAreaEdgeRight) {
        frame.size.width -= safeArea.right;
    }
    frame.size.width = MAX(0, frame.size.width);
    frame.size.height = MAX(0, frame.size.height);
    return frame;
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

    NSUInteger total = self.slotViews.count + self.customSlotViews.count;
    SLOGI(@"Rebuild complete, %lu slots attached", (unsigned long)total);
}

- (void)bindData:(AliPlayerModel *)model {
    self.currentModel = model;
    for (UIView<SlotProtocol> *slotView in self.slotViews.allValues) {
        if ([slotView isKindOfClass:[BaseSlot class]]) {
            BaseSlot *slot = (BaseSlot *)slotView;
            if (slot.deferContentCreation && !slot.contentReady) {
                continue;
            }
        }
        [slotView onBindData:model];
    }
    for (UIView<SlotProtocol> *slotView in self.customSlotViews.allValues) {
        [slotView onBindData:model];
    }
    NSUInteger total = self.slotViews.count + self.customSlotViews.count;
    SLOGI(@"Data bound to %lu slots", (unsigned long)total);
}

- (void)unbindData {
    for (UIView<SlotProtocol> *slotView in self.slotViews.allValues) {
        [slotView onUnbindData];
    }
    for (UIView<SlotProtocol> *slotView in self.customSlotViews.allValues) {
        [slotView onUnbindData];
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

    NSNumber *keyToRemove = nil;
    if ([slotView isKindOfClass:[BaseSlot class]]) {
        keyToRemove = @(((BaseSlot *)slotView).slotType);
    } else {
        for (NSNumber *key in [self.slotViews.allKeys copy]) {
            if (self.slotViews[key] == slotView) {
                keyToRemove = key;
                break;
            }
        }
    }

    if (keyToRemove) {
        [self.slotViews removeObjectForKey:keyToRemove];
    } else {
        NSString *customKeyToRemove = nil;
        for (NSString *key in [self.customSlotViews.allKeys copy]) {
            if (self.customSlotViews[key] == slotView) {
                customKeyToRemove = key;
                break;
            }
        }
        if (customKeyToRemove) {
            [self.customSlotViews removeObjectForKey:customKeyToRemove];
        }
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

- (void)wireSlotActionNotifications {
    UIView<SlotProtocol> *topBarSlotView = self.slotViews[@(SlotTypeTopBar)];
    if ([topBarSlotView isKindOfClass:[TopBarSlot class]]) {
        ((TopBarSlot *)topBarSlotView).slotActionDispatcher = self.slotActionDispatcher;
        SLOGI(@"Wired TopBarSlot to slot action dispatcher");
    }

    UIView<SlotProtocol> *bottomBarSlotView = self.slotViews[@(SlotTypeBottomBar)];
    if ([bottomBarSlotView isKindOfClass:[BottomBarSlot class]]) {
        ((BottomBarSlot *)bottomBarSlotView).slotActionDispatcher = self.slotActionDispatcher;
        SLOGI(@"Wired BottomBarSlot to slot action dispatcher");
    }

    UIView<SlotProtocol> *settingMenuSlotView = self.slotViews[@(SlotTypeSettingMenu)];
    if ([settingMenuSlotView isKindOfClass:[SettingMenuSlot class]]) {
        ((SettingMenuSlot *)settingMenuSlotView).slotActionDispatcher = self.slotActionDispatcher;
        SLOGI(@"Wired SettingMenuSlot as slot action notification observer");
    }
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
