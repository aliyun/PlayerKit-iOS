//
//  OptionPanelSlot.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseSlot.h"

NS_ASSUME_NONNULL_BEGIN

@interface OptionPanelSlot : BaseSlot

- (void)showWithOptions:(NSArray<NSString *> *)displayTexts
          selectedIndex:(NSInteger)selectedIndex
               onSelect:(void(^)(NSInteger index))selectBlock;

- (void)hidePanel;

@end

NS_ASSUME_NONNULL_END
