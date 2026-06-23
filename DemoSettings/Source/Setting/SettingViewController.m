//
//  SettingViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SettingViewController.h"
#import "SettingModel.h"
#import "SettingKeys.h"
#import "ValueFormatter.h"
#import "LogLevelFormatter.h"
#import "UserDefaultsManager.h"
#import "LinkViewController.h"
#import "ToastUtils.h"
#import "PasteboardUtils.h"
#import <PlayerKit/AliPlayerKit.h>
#import <PlayerKit/LogLevel.h>

#if __has_include(<AliVCSDK_Standard/AliVCSDK_Standard.h>)
#import <AliVCSDK_Standard/AliVCSDK_Standard.h>

#elif __has_include(<AliVCSDK_InteractiveLive/AliVCSDK_InteractiveLive.h>)
#import <AliVCSDK_InteractiveLive/AliVCSDK_InteractiveLive.h>

#elif __has_include(<AliVCSDK_BasicLive/AliVCSDK_BasicLive.h>)
#import <AliVCSDK_BasicLive/AliVCSDK_BasicLive.h>

#elif __has_include(<AliVCSDK_UGC/AliVCSDK_UGC.h>)
#import <AliVCSDK_UGC/AliVCSDK_UGC.h>

#endif

#if __has_include(<AliyunPlayer/AliyunPlayer.h>)
#import <AliyunPlayer/AliyunPlayer.h>
#endif

#pragma mark - 设置项 ID 常量

static NSString * const kIDHeaderGeneral       = @"header_general";
static NSString * const kIDLinkSetting         = @"link_setting";
static NSString * const kIDDebugMode           = @"debug_mode";

static NSString * const kIDHeaderLogs          = @"header_logs";
static NSString * const kIDLogPanelSwitch      = @"log_panel_switch";
static NSString * const kIDLogLevelSelector    = @"log_level_selector";

static NSString * const kIDHeaderVersions      = @"header_versions";
static NSString * const kIDSdkVersion          = @"sdk_version";
static NSString * const kIDPlayerKitVersion    = @"player_kit_version";
static NSString * const kIDPlayerKitBuild      = @"player_kit_build";
static NSString * const kIDDeviceUUID          = @"device_uuid";

static NSString * const kIDHeaderOthers        = @"header_others";
static NSString * const kIDResetDefault        = @"reset_default";
static NSString * const kIDClearCache          = @"clear_cache";

// 恢复默认后的应用退出延迟
static NSTimeInterval const kKillAppDelaySeconds = 2.0;

// Cell 复用标识符
static NSString * const kButtonCellId   = @"SettingButtonCell";
static NSString * const kTextCellId     = @"SettingTextCell";
static NSString * const kSwitchCellId   = @"SettingSwitchCell";
static NSString * const kSelectorCellId = @"SettingSelectorCell";

@interface SettingViewController ()

@property (nonatomic, strong) NSArray<NSString *> *sectionTitles;
@property (nonatomic, strong) NSArray<NSArray<SettingModel *> *> *sections;

@end

@implementation SettingViewController

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"设置";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadSettings];
}

#pragma mark - Private Methods

- (void)loadSettings {
    NSMutableArray<SettingModel *> *allModels = [NSMutableArray array];
    [allModels addObjectsFromArray:[self buildGeneralSettings]];
    [allModels addObjectsFromArray:[self buildLogSettings]];
    [allModels addObjectsFromArray:[self buildVersionSettings]];
    [allModels addObjectsFromArray:[self buildOtherSettings]];

    [self organizeIntoSections:allModels];
    [self triggerAsyncLoading];
    [self.tableView reloadData];
}

// 将平铺的 model 列表按 HEADER 分割为 section
- (void)organizeIntoSections:(NSArray<SettingModel *> *)allModels {
    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    NSMutableArray<NSMutableArray<SettingModel *> *> *sections = [NSMutableArray array];
    NSMutableArray<SettingModel *> *currentSection = nil;

    for (SettingModel *model in allModels) {
        if (model.type == SettingTypeHeader) {
            [titles addObject:model.title];
            currentSection = [NSMutableArray array];
            [sections addObject:currentSection];
        } else if (currentSection) {
            [currentSection addObject:model];
        }
    }

    self.sectionTitles = [titles copy];
    self.sections = [sections copy];
}

// 对所有带 asyncLoaderBlock 的 model 触发异步加载
- (void)triggerAsyncLoading {
    __weak typeof(self) weakSelf = self;
    for (NSArray<SettingModel *> *section in self.sections) {
        for (SettingModel *model in section) {
            if (model.asyncLoaderBlock) {
                [model loadAsyncWithBlock:^(NSString * _Nullable result) {
                    NSIndexPath *indexPath = [weakSelf indexPathForModel:model];
                    if (indexPath) {
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath]
                                                  withRowAnimation:UITableViewRowAnimationNone];
                    }
                }];
            }
        }
    }
}

- (nullable NSIndexPath *)indexPathForModel:(SettingModel *)model {
    for (NSUInteger section = 0; section < self.sections.count; section++) {
        NSArray<SettingModel *> *items = self.sections[section];
        NSUInteger row = [items indexOfObjectIdenticalTo:model];
        if (row != NSNotFound) {
            return [NSIndexPath indexPathForRow:row inSection:section];
        }
    }
    return nil;
}

#pragma mark - Build Settings

- (NSArray<SettingModel *> *)buildGeneralSettings {
    NSMutableArray<SettingModel *> *models = [NSMutableArray array];

    [models addObject:[SettingModel headerWithId:kIDHeaderGeneral title:@"通用"]];

    // 链接配置
    SettingModel *linkSetting = [SettingModel buttonArrowWithId:kIDLinkSetting title:@"链接配置"];
    __weak typeof(self) weakSelf = self;
    linkSetting.onClickBlock = ^(SettingModel *m) {
        LinkViewController *vc = [[LinkViewController alloc] init];
        [weakSelf.navigationController pushViewController:vc animated:YES];
    };
    [models addObject:linkSetting];

    // 调试模式开关
    BOOL enableDebugMode = [[UserDefaultsManager sharedInstance] boolForKey:SettingKeyDebugMode
                                                        defValue:[AliPlayerKit isDebugModeEnabled]];
    SettingModel *debugMode = [SettingModel switchWithId:kIDDebugMode title:@"调试模式" checked:enableDebugMode];
    debugMode.onValueChangedBlock = ^(SettingModel *m, id newValue) {
        BOOL checked = [newValue boolValue];
        [[UserDefaultsManager sharedInstance] saveBool:checked forKey:SettingKeyDebugMode];
        [AliPlayerKit setDebugModeEnabled:checked];
    };
    [models addObject:debugMode];

    return models;
}

- (NSArray<SettingModel *> *)buildLogSettings {
    NSMutableArray<SettingModel *> *models = [NSMutableArray array];

    [models addObject:[SettingModel headerWithId:kIDHeaderLogs title:@"日志"]];

    // 显示日志面板开关
    BOOL enableLogPanel = [[UserDefaultsManager sharedInstance] boolForKey:SettingKeyEnableLogPanel
                                                       defValue:[AliPlayerKit isLogPanelEnabled]];
    SettingModel *logPanel = [SettingModel switchWithId:kIDLogPanelSwitch title:@"显示日志面板" checked:enableLogPanel];
    logPanel.onValueChangedBlock = ^(SettingModel *m, id newValue) {
        BOOL checked = [newValue boolValue];
        [[UserDefaultsManager sharedInstance] saveBool:checked forKey:SettingKeyEnableLogPanel];
        [AliPlayerKit setLogPanelEnabled:checked];
    };
    [models addObject:logPanel];

    // 日志等级选择器
    LogLevelFormatter *formatter = [[LogLevelFormatter alloc] init];
    NSArray *levelOptions = @[
        @(LogLevelVerbose),
        @(LogLevelDebug),
        @(LogLevelInfo),
        @(LogLevelWarn),
        @(LogLevelError),
        @(LogLevelNone),
    ];
    SettingModel *logLevel = [SettingModel selectorWithId:kIDLogLevelSelector
                                                   title:@"日志等级"
                                            valueOptions:levelOptions
                                               formatter:formatter];
    logLevel.onValueChangedBlock = ^(SettingModel *m, id newValue) {
        NSInteger level = [newValue integerValue];
        [[UserDefaultsManager sharedInstance] saveInteger:level forKey:SettingKeyLogLevel];
        [AliPlayerKit setLogLevel:(LogLevel)level];
    };
    logLevel.asyncLoaderBlock = ^NSString * _Nullable {
        NSInteger level = [[UserDefaultsManager sharedInstance] integerForKey:SettingKeyLogLevel
                                                          defValue:(NSInteger)[AliPlayerKit logLevel]];
        return [formatter formatValue:@(level)];
    };
    [models addObject:logLevel];

    return models;
}

- (NSArray<SettingModel *> *)buildVersionSettings {
    NSMutableArray<SettingModel *> *models = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;

    [models addObject:[SettingModel headerWithId:kIDHeaderVersions title:@"版本"]];

    // 设备 UUID
    SettingModel *deviceUUID = [SettingModel textWithId:kIDDeviceUUID title:@"设备 UUID" value:nil];
    deviceUUID.asyncLoaderBlock = ^NSString * _Nullable {
        return [AliPlayer getDeviceUUID];
    };
    deviceUUID.onClickBlock = ^(SettingModel *m) {
        [PasteboardUtils copyText:m.value];
        [ToastUtils showToast:@"已复制" inViewController:weakSelf];
    };
    [models addObject:deviceUUID];

    // SDK 版本号
    SettingModel *sdkVersion = [SettingModel textWithId:kIDSdkVersion title:@"SDK 版本号" value:nil];
    sdkVersion.asyncLoaderBlock = ^NSString * _Nullable {
        return [AliPlayerKit getSdkVersion];
    };
    sdkVersion.onClickBlock = ^(SettingModel *m) {
        [PasteboardUtils copyText:m.value];
        [ToastUtils showToast:@"已复制" inViewController:weakSelf];
    };
    [models addObject:sdkVersion];

    // PlayerKit 版本号
    SettingModel *pkVersion = [SettingModel textWithId:kIDPlayerKitVersion title:@"PlayerKit 版本号" value:nil];
    pkVersion.asyncLoaderBlock = ^NSString * _Nullable {
        return [AliPlayerKit getPlayerKitVersion];
    };
    pkVersion.onClickBlock = ^(SettingModel *m) {
        [PasteboardUtils copyText:m.value];
        [ToastUtils showToast:@"已复制" inViewController:weakSelf];
    };
    [models addObject:pkVersion];

    // 构建信息
    SettingModel *buildInfo = [SettingModel textWithId:kIDPlayerKitBuild title:@"构建信息" value:nil];
    buildInfo.asyncLoaderBlock = ^NSString * _Nullable {
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"unknown";
        NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"unknown";
#if defined(__arm64__)
        NSString *arch = @"arm64";
#elif defined(__x86_64__)
        NSString *arch = @"x86_64";
#else
        NSString *arch = @"unknown";
#endif
        return [NSString stringWithFormat:@"%@/%@/%@", version, build, arch];
    };
    buildInfo.onClickBlock = ^(SettingModel *m) {
        [PasteboardUtils copyText:m.value];
        [ToastUtils showToast:@"已复制" inViewController:weakSelf];
    };
    [models addObject:buildInfo];

    return models;
}

- (NSArray<SettingModel *> *)buildOtherSettings {
    NSMutableArray<SettingModel *> *models = [NSMutableArray array];

    [models addObject:[SettingModel headerWithId:kIDHeaderOthers title:@"其他"]];

    // 恢复默认配置
    SettingModel *resetDefault = [SettingModel buttonWithId:kIDResetDefault title:@"恢复默认设置"];
    __weak typeof(self) weakSelf = self;
    resetDefault.onClickBlock = ^(SettingModel *m) {
        [weakSelf showResetConfirmation];
    };
    [models addObject:resetDefault];

    // 清除缓存
    SettingModel *clearCache = [SettingModel buttonWithId:kIDClearCache title:@"清除缓存"];
    clearCache.onClickBlock = ^(SettingModel *m) {
        [AliPlayerKit clearCaches];
        [ToastUtils showToast:@"缓存已清除" inViewController:weakSelf];
    };
    [models addObject:clearCache];

    return models;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].count;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionTitles[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SettingModel *model = self.sections[indexPath.section][indexPath.row];

    switch (model.type) {
        case SettingTypeButton:
            return [self buttonCellForModel:model tableView:tableView];
        case SettingTypeText:
            return [self textCellForModel:model tableView:tableView];
        case SettingTypeSwitch:
            return [self switchCellForModel:model tableView:tableView];
        case SettingTypeSelector:
            return [self selectorCellForModel:model tableView:tableView];
        default:
            return [[UITableViewCell alloc] init];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SettingModel *model = self.sections[indexPath.section][indexPath.row];

    switch (model.type) {
        case SettingTypeButton:
            if (model.onClickBlock) {
                model.onClickBlock(model);
            }
            break;
        case SettingTypeSelector:
            [self showSelectorForModel:model atIndexPath:indexPath];
            break;
        case SettingTypeText:
            if (model.onClickBlock) {
                model.onClickBlock(model);
            }
            break;
        default:
            break;
    }
}

#pragma mark - Cell Configuration

- (UITableViewCell *)buttonCellForModel:(SettingModel *)model tableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kButtonCellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kButtonCellId];
    }
    cell.textLabel.text = model.title;
    cell.accessoryType = model.showArrow ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (UITableViewCell *)textCellForModel:(SettingModel *)model tableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTextCellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kTextCellId];
    }
    cell.textLabel.text = model.title;
    cell.detailTextLabel.text = model.value ?: @"";
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = model.onClickBlock ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    return cell;
}

- (UITableViewCell *)switchCellForModel:(SettingModel *)model tableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSwitchCellId];
    UISwitch *sw;
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSwitchCellId];
        sw = [[UISwitch alloc] init];
        [sw addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        sw = (UISwitch *)cell.accessoryView;
    }
    cell.textLabel.text = model.title;
    sw.on = model.isChecked;
    return cell;
}

- (UITableViewCell *)selectorCellForModel:(SettingModel *)model tableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSelectorCellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kSelectorCellId];
    }
    cell.textLabel.text = model.title;
    cell.detailTextLabel.text = model.value ?: @"";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

#pragma mark - Switch Action

- (void)switchValueChanged:(UISwitch *)sender {
    UIView *view = sender;
    while (view && ![view isKindOfClass:[UITableViewCell class]]) {
        view = view.superview;
    }
    if (!view) return;

    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)view];
    if (!indexPath) return;

    SettingModel *model = self.sections[indexPath.section][indexPath.row];
    [model handleCheckedChange:sender.isOn];
}

#pragma mark - Selector Action

- (void)showSelectorForModel:(SettingModel *)model atIndexPath:(NSIndexPath *)indexPath {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:model.title
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];

    for (NSString *option in model.options) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:option
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *a) {
            [model handleValueChange:option];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
        }];
        [alert addAction:action];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    // iPad 适配
    if (alert.popoverPresentationController) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        alert.popoverPresentationController.sourceView = cell;
        alert.popoverPresentationController.sourceRect = cell.bounds;
    }

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Alert Helpers

- (void)showResetConfirmation {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                  message:@"确定要恢复默认设置吗？恢复后应用将自动重启。"
                                                           preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *a) {
        [[UserDefaultsManager sharedInstance] clearAll];
        [self showAlert:@"提示" message:@"已恢复默认设置，应用即将重启"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kKillAppDelaySeconds * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            exit(0);
        });
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
