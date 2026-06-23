//
//  SceneShortVideoViewController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SceneShortVideoViewController.h"
#import "ToastUtils.h"
#import "PasteboardUtils.h"

static NSString * const kShortVideoHintURL = @"https://help.aliyun.com/zh/vod/use-cases/brief-introduction-micro-of-drama/";

static NSString * const kHintText =
    @"如需实现 短视频列表播放 能力，建议直接采用 阿里云微短剧解决方案。\n\n"
    @"该方案由 客户端 AUI 组件 与 服务端 VodAppServer 配套组成，"
    @"覆盖从内容管理、分发到播放的完整短剧业务链路。"
    @"通过前后端一体化设计，无需自行搭建后台服务，"
    @"即可快速构建具备运营能力的短剧应用，有效缩短上线周期并降低研发成本。\n\n"
    @"说明：微短剧相关 功能源码及示例工程 已在 GitHub 开源，"
    @"可前往开源仓库查看、下载并按需集成。\n\n"
    @"如需了解 专业版 License 功能范围、商业授权方式或正式接入流程，"
    @"可联系 PDSA 售前技术支持团队 获取进一步协助。\n\n"
    @"查看阿里云微短剧解决方案介绍";

static NSString * const kLinkText = @"查看阿里云微短剧解决方案介绍";

@interface SceneShortVideoViewController ()

@property (nonatomic, strong) UITextView *hintTextView;

@end

@implementation SceneShortVideoViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Short Video";
    [self setupHintView];
}

#pragma mark - UI Setup

- (void)setupHintView {
    self.hintTextView = [[UITextView alloc] init];
    self.hintTextView.editable = NO;
    self.hintTextView.scrollEnabled = NO;
    self.hintTextView.dataDetectorTypes = UIDataDetectorTypeNone;
    self.hintTextView.textContainerInset = UIEdgeInsetsZero;
    self.hintTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.hintTextView];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.hintTextView.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor],
        [self.hintTextView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:24],
        [self.hintTextView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-24],
    ]];

    self.hintTextView.attributedText = [self buildHintAttributedString];

    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.hintTextView addGestureRecognizer:longPress];
}

- (NSAttributedString *)buildHintAttributedString {
    UIFont *bodyFont = [UIFont systemFontOfSize:16];
    UIFont *boldFont = [UIFont boldSystemFontOfSize:16];
    UIColor *textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 4;

    NSDictionary *bodyAttrs = @{
        NSFontAttributeName: bodyFont,
        NSForegroundColorAttributeName: textColor,
        NSParagraphStyleAttributeName: paragraphStyle,
    };

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:kHintText attributes:bodyAttrs];

    NSArray<NSString *> *boldPhrases = @[
        @"短视频列表播放",
        @"阿里云微短剧解决方案",
        @"客户端 AUI 组件",
        @"服务端 VodAppServer",
        @"说明：",
        @"功能源码及示例工程",
        @"专业版 License",
        @"PDSA 售前技术支持团队",
    ];

    for (NSString *phrase in boldPhrases) {
        NSRange range = [kHintText rangeOfString:phrase];
        if (range.location != NSNotFound) {
            [text addAttribute:NSFontAttributeName value:boldFont range:range];
        }
    }

    NSRange linkRange = [kHintText rangeOfString:kLinkText];
    if (linkRange.location != NSNotFound) {
        [text addAttribute:NSLinkAttributeName value:[NSURL URLWithString:kShortVideoHintURL] range:linkRange];
    }

    return text;
}

#pragma mark - Actions

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;

    NSMutableString *plainText = [NSMutableString stringWithString:self.hintTextView.attributedText.string];
    [plainText appendFormat:@"\n\n%@", kShortVideoHintURL];

    [PasteboardUtils copyText:[plainText copy]];
    
    [ToastUtils showToast:@"已复制" inViewController:self];
}

@end
