//
//  SettingModel.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingType.h"

@class SettingModel;
@protocol ValueFormatter;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 设置项点击回调。
 *
 * @param model 被点击的设置项。
 */
typedef void (^SettingClickBlock)(SettingModel *model);

/**
 * @brief 设置项值变更回调。
 *
 * @param model    值发生变更的设置项。
 * @param newValue 新值。Switch 类型为 NSNumber(BOOL)，Selector 类型为格式化器解析后的值对象或显示字符串。
 */
typedef void (^SettingValueChangedBlock)(SettingModel *model, id newValue);

/**
 * @brief 异步数据加载器，在后台线程执行。
 *
 * @return 加载到的字符串结果，可为 nil。
 */
typedef NSString * _Nullable (^SettingAsyncLoaderBlock)(void);

/**
 * @brief 异步加载完成回调，在主线程执行。
 *
 * @param result 加载到的结果字符串。
 */
typedef void (^SettingLoadedBlock)(NSString * _Nullable result);

/**
 * @brief 设置项数据模型。
 *
 * @discussion 通过语义化工厂方法创建，支持 5 种视图类型（Header / Button / Text / Switch / Selector）。
 *             使用 Block 处理交互回调，使用 GCD 实现异步数据加载。
 *             对标 Android 端 SettingModel（Builder 模式在 ObjC 中替换为工厂方法 + 属性赋值）。
 *
 * @see SettingType
 * @see ValueFormatter
 * @see SettingViewController
 */
@interface SettingModel : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Core Properties

/** 设置项唯一标识符 */
@property (nonatomic, copy, readonly) NSString *identifier;

/** 设置项标题 */
@property (nonatomic, copy, readonly) NSString *title;

/** 设置项视图类型 */
@property (nonatomic, assign, readonly) SettingType type;

#pragma mark - State Properties

/** 描述文本或当前值（用于 Text 和 Selector 类型） */
@property (nonatomic, copy, nullable) NSString *value;

/** 选中状态（仅用于 Switch 类型） */
@property (nonatomic, assign, getter=isChecked) BOOL checked;

/** 可选项列表（仅用于 Selector 类型），元素为显示字符串 */
@property (nonatomic, copy, nullable) NSArray<NSString *> *options;

/** 是否启用，默认 YES */
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

/** 是否显示右侧箭头指示器 */
@property (nonatomic, assign) BOOL showArrow;

#pragma mark - Callback Blocks

/** 点击回调（用于 Button 类型） */
@property (nonatomic, copy, nullable) SettingClickBlock onClickBlock;

/** 值变更回调（用于 Switch 和 Selector 类型） */
@property (nonatomic, copy, nullable) SettingValueChangedBlock onValueChangedBlock;

/** 异步数据加载器（在后台线程执行） */
@property (nonatomic, copy, nullable) SettingAsyncLoaderBlock asyncLoaderBlock;

/** 值格式化器（用于 Selector 类型的值↔字符串转换） */
@property (nonatomic, strong, nullable) id<ValueFormatter> valueFormatter;

#pragma mark - Factory Methods

/**
 * @brief 创建分组头部项。
 *
 * @param identifier 唯一标识符。
 * @param title      分组标题。
 *
 * @return SettingModel 实例。
 */
+ (instancetype)headerWithId:(NSString *)identifier title:(NSString *)title;

/**
 * @brief 创建普通按钮项（不带箭头）。
 *
 * @param identifier 唯一标识符。
 * @param title      按钮标题。
 *
 * @return SettingModel 实例。
 */
+ (instancetype)buttonWithId:(NSString *)identifier title:(NSString *)title;

/**
 * @brief 创建带箭头的按钮项。
 *
 * @param identifier 唯一标识符。
 * @param title      按钮标题。
 *
 * @return SettingModel 实例。
 */
+ (instancetype)buttonArrowWithId:(NSString *)identifier title:(NSString *)title;

/**
 * @brief 创建纯文本展示项。
 *
 * @param identifier 唯一标识符。
 * @param title      标题文本。
 * @param value      当前值文本，可为 nil。
 *
 * @return SettingModel 实例。
 */
+ (instancetype)textWithId:(NSString *)identifier title:(NSString *)title value:(nullable NSString *)value;

/**
 * @brief 创建开关切换项。
 *
 * @param identifier 唯一标识符。
 * @param title      开关标题。
 * @param checked    初始选中状态。
 *
 * @return SettingModel 实例。
 */
+ (instancetype)switchWithId:(NSString *)identifier title:(NSString *)title checked:(BOOL)checked;

/**
 * @brief 创建选择器项（直接指定显示字符串列表）。
 *
 * @param identifier 唯一标识符。
 * @param title      标题文本。
 * @param options    选项显示字符串列表。
 *
 * @return SettingModel 实例。
 */
+ (instancetype)selectorWithId:(NSString *)identifier
                         title:(NSString *)title
                       options:(NSArray<NSString *> *)options;

/**
 * @brief 创建带格式化器的选择器项。
 *
 * @discussion 接收值对象数组，内部通过格式化器自动转换为显示字符串列表。
 *             格式化器同时用于用户选择后的反向解析。
 *
 * @param identifier   唯一标识符。
 * @param title        标题文本。
 * @param valueOptions 值对象数组（如 @[@(LogLevelVerbose), @(LogLevelDebug), ...]）。
 * @param formatter    值格式化器，负责值↔字符串的双向转换。
 *
 * @return SettingModel 实例。
 *
 * @see ValueFormatter
 */
+ (instancetype)selectorWithId:(NSString *)identifier
                         title:(NSString *)title
                  valueOptions:(NSArray *)valueOptions
                     formatter:(id<ValueFormatter>)formatter;

#pragma mark - Actions

/**
 * @brief 触发异步加载。
 *
 * @discussion 在后台线程执行 asyncLoaderBlock，完成后切回主线程更新 value 并触发回调。
 *             如果 asyncLoaderBlock 为 nil，此方法不执行任何操作。
 *
 * @param block 加载完成后的回调，在主线程执行，可为 nil。
 */
- (void)loadAsyncWithBlock:(nullable SettingLoadedBlock)block;

/**
 * @brief 处理值变更（用于 Selector 类型）。
 *
 * @discussion 更新内部 value，如果存在 valueFormatter 则解析显示字符串为值类型后传递给回调。
 *
 * @param newDisplayValue 用户选择的显示字符串。
 */
- (void)handleValueChange:(NSString *)newDisplayValue;

/**
 * @brief 处理选中状态变更（用于 Switch 类型）。
 *
 * @discussion 更新内部 checked 状态并触发 onValueChangedBlock 回调。
 *
 * @param checked 新的选中状态。
 */
- (void)handleCheckedChange:(BOOL)checked;

@end

NS_ASSUME_NONNULL_END
