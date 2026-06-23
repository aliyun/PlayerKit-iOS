//
//  SettingSwitcherItemView.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingItemViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 开关类型的设置项视图。
 *
 * @discussion 显示标题与 UISwitch 开关，切换时触发 valueChangedBlock。
 *             支持点击整行触发开关切换。
 *
 * @see SettingItemViewProtocol
 * @see SettingItem
 */
@interface SettingSwitcherItemView : UIView <SettingItemViewProtocol>

@property (nonatomic, strong, readonly) UIView *separatorView;

@end

NS_ASSUME_NONNULL_END
