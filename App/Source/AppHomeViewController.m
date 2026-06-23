//
//  AppHomeViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "AppHomeViewController.h"
#import "AppMenuConfig.h"
#import "AppMenuItem.h"
#import "AppSchemaRouter.h"

static NSString * const kTitleCellIdentifier = @"AppHomeTitleCell";
static NSString * const kItemCellIdentifier = @"AppHomeItemCell";

@interface AppHomeViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) AppMenuConfig *menuConfig;
@property (nonatomic, strong) NSArray<NSArray<AppMenuItem *> *> *menuSections;

@end

@implementation AppHomeViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"PlayerKit-iOS";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupTableView];
    [self loadMenuData];
}

#pragma mark - Private Methods

// 配置表格视图布局并注册 cell 标识符
- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60.0;
    [self.view addSubview:self.tableView];
}

// 从配置中加载菜单数据
- (void)loadMenuData {
    self.menuConfig = [[AppMenuConfig alloc] init];
    self.menuSections = [self.menuConfig menuSections];
    [self.tableView reloadData];
}

// 获取指定 index path 的菜单项
- (AppMenuItem *)menuItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < self.menuSections.count) {
        NSArray<AppMenuItem *> *section = self.menuSections[indexPath.section];
        if (indexPath.row < section.count) {
            return section[indexPath.row];
        }
    }
    return nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.menuSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < self.menuSections.count) {
        return self.menuSections[section].count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppMenuItem *item = [self menuItemAtIndexPath:indexPath];
    
    if (item.type == AppMenuItemTypeTitle) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTitleCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kTitleCellIdentifier];
        }
        cell.textLabel.text = item.title;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    }
    
    // 使用 UITableViewCellStyleSubtitle 以支持 detailTextLabel 显示
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kItemCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kItemCellIdentifier];
    }
    cell.textLabel.text = item.title;
    cell.textLabel.font = [UIFont systemFontOfSize:15.0];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.text = item.itemDescription;
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    AppMenuItem *item = [self menuItemAtIndexPath:indexPath];
    if (item.type == AppMenuItemTypeItem && item.schema) {
        [AppSchemaRouter navigateToSchema:item.schema fromViewController:self];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppMenuItem *item = [self menuItemAtIndexPath:indexPath];
    if (item.type == AppMenuItemTypeTitle) {
        return 44.0;
    }
    return 56.0;
}

@end
