//
//  LinkViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "LinkViewController.h"
#import "LinkConstants.h"
#import "LinkItem.h"
#import "UserDefaultsManager.h"
#import "QRScannerViewController.h"

static NSString * const kLinkCellIdentifier = @"LinkCell";

@interface LinkViewController () <UITableViewDataSource, UITableViewDelegate, QRScannerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<LinkItem *> *items;
@property (nonatomic, assign) NSInteger currentScanIndex;

@end

@implementation LinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Link Settings";
    self.view.backgroundColor = [UIColor whiteColor];
    self.currentScanIndex = -1;

    [self initData];
    [self setupTableView];
    [self setupSaveButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

#pragma mark - Data

- (void)initData {
    NSArray<LinkItem *> *allItems = [LinkConstants buildDefaultItems];

    if (self.filterKeys.count > 0) {
        NSMutableArray<LinkItem *> *filtered = [NSMutableArray array];
        for (LinkItem *item in allItems) {
            if ([self.filterKeys containsObject:item.key]) {
                [filtered addObject:item];
            }
        }
        self.items = [filtered copy];
    } else {
        self.items = allItems;
    }

    for (LinkItem *item in self.items) {
        NSString *savedValue = [[UserDefaultsManager sharedInstance] stringForKey:item.key];
        if (savedValue) {
            item.link = savedValue;
        }
    }
}

#pragma mark - UI Setup

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
}

- (void)setupSaveButton {
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [saveButton setTitle:@"Save" forState:UIControlStateNormal];
    saveButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    saveButton.backgroundColor = self.view.tintColor;
    [saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveButton.layer.cornerRadius = 8;
    saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [saveButton addTarget:self action:@selector(saveTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveButton];

    [NSLayoutConstraint activateConstraints:@[
        [saveButton.topAnchor constraintEqualToAnchor:self.tableView.bottomAnchor constant:8],
        [saveButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [saveButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [saveButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-34],
        [saveButton.heightAnchor constraintEqualToConstant:48],
    ]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLinkCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kLinkCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [self configureCellSubviews:cell];
    }

    [self bindCell:cell withItem:self.items[indexPath.row] atIndex:indexPath.row];
    return cell;
}

#pragma mark - Cell Configuration

- (void)configureCellSubviews:(UITableViewCell *)cell {
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.tag = 100;
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UITextField *textField = [[UITextField alloc] init];
    textField.font = [UIFont systemFontOfSize:14];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.placeholder = @"Enter link or scan QR code";
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.tag = 101;
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    UIButton *scanButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [scanButton setTitle:@"Scan" forState:UIControlStateNormal];
    scanButton.titleLabel.font = [UIFont systemFontOfSize:14];
    scanButton.tag = 102;
    scanButton.translatesAutoresizingMaskIntoConstraints = NO;
    [scanButton addTarget:self action:@selector(scanTapped:) forControlEvents:UIControlEventTouchUpInside];

    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    separator.tag = 103;
    separator.translatesAutoresizingMaskIntoConstraints = NO;

    [cell.contentView addSubview:nameLabel];
    [cell.contentView addSubview:textField];
    [cell.contentView addSubview:scanButton];
    [cell.contentView addSubview:separator];

    [NSLayoutConstraint activateConstraints:@[
        [nameLabel.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:12],
        [nameLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
        [nameLabel.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],

        [textField.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:8],
        [textField.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
        [textField.heightAnchor constraintEqualToConstant:36],

        [scanButton.centerYAnchor constraintEqualToAnchor:textField.centerYAnchor],
        [scanButton.leadingAnchor constraintEqualToAnchor:textField.trailingAnchor constant:8],
        [scanButton.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
        [scanButton.widthAnchor constraintEqualToConstant:50],

        [separator.topAnchor constraintEqualToAnchor:textField.bottomAnchor constant:12],
        [separator.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
        [separator.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor],
        [separator.heightAnchor constraintEqualToConstant:1],
        [separator.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor],
    ]];
}

- (void)bindCell:(UITableViewCell *)cell withItem:(LinkItem *)item atIndex:(NSInteger)index {
    UILabel *nameLabel = [cell.contentView viewWithTag:100];
    UITextField *textField = [cell.contentView viewWithTag:101];
    UIButton *scanButton = [cell.contentView viewWithTag:102];

    nameLabel.text = item.name;
    textField.text = item.link ?: @"";

    textField.accessibilityIdentifier = [NSString stringWithFormat:@"link_field_%ld", (long)index];
    scanButton.accessibilityIdentifier = [NSString stringWithFormat:@"scan_button_%ld", (long)index];
}

#pragma mark - Actions

- (void)textFieldDidChange:(UITextField *)textField {
    UIView *cell = textField.superview;
    while (cell && ![cell isKindOfClass:[UITableViewCell class]]) {
        cell = cell.superview;
    }
    if (!cell) return;

    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)cell];
    if (indexPath && indexPath.row < (NSInteger)self.items.count) {
        self.items[indexPath.row].link = textField.text;
    }
}

- (void)scanTapped:(UIButton *)button {
    UIView *cell = button.superview;
    while (cell && ![cell isKindOfClass:[UITableViewCell class]]) {
        cell = cell.superview;
    }
    if (!cell) return;

    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)cell];
    if (!indexPath) return;

    self.currentScanIndex = indexPath.row;

    QRScannerViewController *scanner = [[QRScannerViewController alloc] init];
    scanner.delegate = self;
    [self.navigationController pushViewController:scanner animated:YES];
}

- (void)saveTapped {
    for (LinkItem *item in self.items) {
        [[UserDefaultsManager sharedInstance] saveString:item.link forKey:item.key];
    }

    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - QRScannerDelegate

- (void)qrScanner:(QRScannerViewController *)scanner didScanResult:(NSString *)result {
    if (self.currentScanIndex >= 0 && self.currentScanIndex < (NSInteger)self.items.count) {
        self.items[self.currentScanIndex].link = result;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.currentScanIndex inSection:0]]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
    self.currentScanIndex = -1;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
}

#pragma mark - Keyboard

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
