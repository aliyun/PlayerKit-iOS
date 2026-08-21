//
//  OptionPanelSlot.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BasePanelSlot.h"

NS_ASSUME_NONNULL_BEGIN

@interface OptionPanelSlot : BasePanelSlot

- (void)showWithOptions:(NSArray<NSString *> *)displayTexts
          selectedIndex:(NSInteger)selectedIndex
               onSelect:(void(^)(NSInteger index))selectBlock;

@end

NS_ASSUME_NONNULL_END
