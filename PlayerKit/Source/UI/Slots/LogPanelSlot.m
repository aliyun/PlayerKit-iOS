//
//  LogPanelSlot.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "LogPanelSlot.h"
#import "LogObserver.h"
#import "LogHub.h"
#import "LogInfo.h"
#import "LogLevel.h"
#import "AliPlayerKit.h"
#import "PlayerColor.h"
#import "PlayerFont.h"
#import "Log.h"
#import "LocaleMacros.h"
#import "LocaleKeys.h"
#import "PasteboardUtils.h"

static const NSUInteger kMaxLines = 2000;
static const NSUInteger kMaxCopyChars = 20000;
static const CGFloat kHeaderHeight = 36.0;
static const CGFloat kHeaderPadding = 12.0;
static const CGFloat kDefaultContentHeight = 200.0;
static const CGFloat kCornerRadius = 8.0;

@interface LogPanelSlot () <LogObserver>

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *logLabel;

@property (nonatomic, assign) BOOL expanded;
@property (nonatomic, strong) NSMutableArray<NSString *> *lines;
@property (nonatomic, strong) NSMutableString *textCache;

@end

@implementation LogPanelSlot

#pragma mark - Slot Lifecycle

- (void)onAttach:(id<SlotHost>)host {
    [super onAttach:host];
    self.lines = [NSMutableArray arrayWithCapacity:kMaxLines + 4];
    self.textCache = [NSMutableString stringWithCapacity:8 * 1024];
    [[LogHub sharedHub] addObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLocaleDidChange:)
                                                 name:LocaleDidChangeNotification
                                               object:nil];
}

- (void)setupContentView {
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = YES;

    [self setupHeader];
    [self setupContent];
    [self updateExpandState];
}

- (void)onDetach {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:LocaleDidChangeNotification
                                                  object:nil];
    [[LogHub sharedHub] removeObserver:self];
    [super onDetach];
}

#pragma mark - LogObserver

- (void)onLog:(LogInfo *)logInfo {
    if (![AliPlayerKit isLogPanelEnabled]) {
        return;
    }

    if (logInfo.level < LogLevelDebug) {
        return;
    }

    NSString *message = logInfo.message;
    if (!message.length) {
        return;
    }

    NSString *line = [logInfo formattedString];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self appendLogLine:line];
    });
}

#pragma mark - Private Methods

- (void)appendLogLine:(NSString *)line {
    if (!self.logLabel) {
        return;
    }

    [self.lines addObject:line];

    BOOL trimmed = NO;
    if (self.lines.count > kMaxLines) {
        NSInteger excess = (NSInteger)self.lines.count - kMaxLines;
        [self.lines removeObjectsInRange:NSMakeRange(0, excess)];
        trimmed = YES;
    }

    BOOL wasAtBottom = [self isScrolledToBottom];

    if (trimmed) {
        [self.textCache setString:@""];
        for (NSString *l in self.lines) {
            [self.textCache appendString:l];
            [self.textCache appendString:@"\n"];
        }
    } else {
        [self.textCache appendString:line];
        [self.textCache appendString:@"\n"];
    }

    self.logLabel.text = [self.textCache copy];
    [self.logLabel sizeToFit];

    if (self.expanded && wasAtBottom) {
        [self scrollToBottom];
    }
}

- (BOOL)isScrolledToBottom {
    if (!self.scrollView) {
        return YES;
    }
    CGFloat contentHeight = self.scrollView.contentSize.height;
    CGFloat frameHeight = self.scrollView.frame.size.height;
    if (contentHeight <= frameHeight) {
        return YES;
    }
    CGFloat offset = self.scrollView.contentOffset.y;
    return offset >= contentHeight - frameHeight - 100.0;
}

- (void)scrollToBottom {
    CGFloat contentHeight = self.scrollView.contentSize.height;
    CGFloat frameHeight = self.scrollView.frame.size.height;
    if (contentHeight > frameHeight) {
        CGPoint offset = CGPointMake(0, contentHeight - frameHeight);
        [self.scrollView setContentOffset:offset animated:NO];
    }
}

#pragma mark - Actions

- (void)onHeaderTapped {
    self.expanded = !self.expanded;
    [self updateExpandState];

    if (self.expanded) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scrollToBottom];
        });
    }
}

- (void)onClearTapped {
    [self.lines removeAllObjects];
    [self.textCache setString:@""];
    self.logLabel.text = @"";
}

- (void)onLogLongPressed:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }

    if (!self.lines.count) {
        return;
    }

    NSString *text = [self.textCache copy];
    if (text.length > kMaxCopyChars) {
        text = [text substringFromIndex:text.length - kMaxCopyChars];
    }

    [PasteboardUtils copyText:text];
    SLOGI(@"Log panel content copied to clipboard (%lu chars)", (unsigned long)text.length);
}

- (void)updateExpandState {
    self.scrollView.hidden = !self.expanded;
    self.clearButton.hidden = !self.expanded;
    self.titleLabel.text = self.expanded
        ? LocalizedString(LocaleKeyLogPanelTitleHide)
        : LocalizedString(LocaleKeyLogPanelTitleShow);
}

#pragma mark - UI Setup

- (void)setupHeader {
    self.headerView = [[UIView alloc] init];
    self.headerView.backgroundColor = [PlayerColor panelBackground];
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerView.layer.cornerRadius = kCornerRadius;
    if (@available(iOS 11.0, *)) {
        self.headerView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    }
    [self addSubview:self.headerView];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onHeaderTapped)];
    [self.headerView addGestureRecognizer:tap];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LocalizedString(LocaleKeyLogPanelTitleShow);
    self.titleLabel.textColor = [PlayerColor textWhite];
    self.titleLabel.font = [PlayerFont bold14];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.headerView addSubview:self.titleLabel];

    self.clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.clearButton setTitle:LocalizedString(LocaleKeyLogPanelClear) forState:UIControlStateNormal];
    [self.clearButton setTitleColor:[PlayerColor textWhite] forState:UIControlStateNormal];
    self.clearButton.titleLabel.font = [PlayerFont regular12];
    self.clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.clearButton.hidden = YES;
    [self.clearButton addTarget:self action:@selector(onClearTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.clearButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.headerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.headerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.headerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.headerView.heightAnchor constraintEqualToConstant:kHeaderHeight],

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.headerView.leadingAnchor constant:kHeaderPadding],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],

        [self.clearButton.trailingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor constant:-kHeaderPadding],
        [self.clearButton.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
    ]];
}

- (void)setupContent {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = [PlayerColor panelBackground];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.hidden = YES;
    [self addSubview:self.scrollView];

    self.logLabel = [[UILabel alloc] init];
    self.logLabel.textColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    if (@available(iOS 13.0, *)) {
        self.logLabel.font = [UIFont monospacedSystemFontOfSize:10.0 weight:UIFontWeightRegular];
    } else {
        self.logLabel.font = [UIFont fontWithName:@"Menlo" size:10.0];
    }
    self.logLabel.numberOfLines = 0;
    self.logLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.logLabel];

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLogLongPressed:)];
    [self.scrollView addGestureRecognizer:longPress];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.headerView.topAnchor],
        [self.scrollView.heightAnchor constraintEqualToConstant:kDefaultContentHeight],

        [self.logLabel.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor constant:8],
        [self.logLabel.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:8],
        [self.logLabel.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor constant:-8],
        [self.logLabel.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor constant:-8],
        [self.logLabel.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor constant:-16],
    ]];
}

#pragma mark - Hit Testing

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    CGPoint headerPoint = [self.headerView convertPoint:point fromView:self];
    if (!self.headerView.hidden && CGRectContainsPoint(self.headerView.bounds, headerPoint)) {
        return [self.headerView hitTest:headerPoint withEvent:event] ?: self.headerView;
    }

    if (self.expanded && !self.scrollView.hidden) {
        CGPoint scrollPoint = [self.scrollView convertPoint:point fromView:self];
        if (CGRectContainsPoint(self.scrollView.bounds, scrollPoint)) {
            return [self.scrollView hitTest:scrollPoint withEvent:event] ?: self.scrollView;
        }
    }

    return nil;
}

#pragma mark - Notification Handlers

- (void)onLocaleDidChange:(NSNotification *)notification {
    [self updateExpandState];
}

@end
