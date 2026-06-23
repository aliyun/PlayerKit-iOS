//
//  SettingSelectorItemView.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingItemViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SettingSelectorItemView : UIView <SettingItemViewProtocol>

@property (nonatomic, strong, readonly) UIView *separatorView;

@end

NS_ASSUME_NONNULL_END
