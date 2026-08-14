//
//  CoverSlot.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "CoverSlot.h"
#import "AliPlayerModel.h"
#import "PlayerNotificationDelegate.h"
#import "PlayerStateStore.h"
#import "Log.h"

#import <SDWebImage/UIImageView+WebCache.h>

// 将播放器的缩放模式转换为 UIImageView 的等效绘制模式
// 使封面与视频画面采用相同的缩放规则，切换时边界不会跳变
static UIViewContentMode ContentModeForScaleMode(ScaleMode scaleMode) {
    switch (scaleMode) {
        case ScaleModeFitXY:
            return UIViewContentModeScaleToFill;
        case ScaleModeCenterCrop:
            return UIViewContentModeScaleAspectFill;
        case ScaleModeFitCenter:
        default:
            return UIViewContentModeScaleAspectFit;
    }
}

@interface CoverSlot () <PlayerNotificationDelegate>

@property (nonatomic, strong) UIImageView *coverImageView;

// 是否使用了外部传入的封面地址，其优先级高于 SDK 从媒体信息中提取的地址
// 置为 YES 后，MediaInfo 回调里的地址一律忽略，避免两个来源互相覆盖
@property (nonatomic, assign) BOOL externalCoverUsed;

// 首帧是否已渲染
// 置为 YES 后不允许任何路径再显示封面，只有重新绑定或解绑数据才会复位
@property (nonatomic, assign) BOOL firstFrameRendered;

@end

@implementation CoverSlot

#pragma mark - Slot Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 不避让安全区域，与 PlayerSurfaceSlot 使用同一个基准矩形
        // 否则在刘海机型上，封面的显示范围会比视频渲染范围小一圈
        self.safeAreaEdges = SlotSafeAreaEdgeNone;
    }
    return self;
}

- (void)setupContentView {
    self.coverImageView = [[UIImageView alloc] init];
    self.coverImageView.clipsToBounds = YES;
    self.coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.coverImageView];

    [NSLayoutConstraint activateConstraints:@[
        [self.coverImageView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.coverImageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.coverImageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.coverImageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    ]];

    // 封面尚未加载，先保持隐藏，避免空白视图参与渲染
    self.hidden = YES;

    [self applyCurrentScaleMode];
}

- (void)onBindData:(AliPlayerModel *)model {
    [super onBindData:model];

    // 开始新一轮播放，复位首帧标记并取消上一轮尚未完成的加载
    self.firstFrameRendered = NO;
    [self.coverImageView sd_cancelCurrentImageLoad];

    // 清掉上一轮的图并回到隐藏态，否则新视频会先显示上一个视频的封面
    self.coverImageView.image = nil;
    [self hide];

    [self applyCurrentScaleMode];

    NSString *coverUrl = model.coverUrl;
    if (coverUrl.length > 0) {
        // 来源一：外部赋值。绑定这一刻地址就已就绪，是能做到无黑屏秒开的路径
        // 宿主若提前预加载过这张图，此处直接命中本地缓存，封面与页面几乎同时出现
        self.externalCoverUsed = YES;
        [self loadCoverWithURL:coverUrl];
        [self show];
    } else {
        // 来源二：等 SDK 从媒体信息中提取，见 playerDidReadyCoverUrl:
        // 地址还没到，保持上面的隐藏态
        self.externalCoverUsed = NO;
        SLOGI(@"Cover URL not set, waiting for MediaInfo extraction");
    }
}

- (void)onUnbindData {
    [self.coverImageView sd_cancelCurrentImageLoad];
    self.coverImageView.image = nil;
    self.externalCoverUsed = NO;
    self.firstFrameRendered = NO;
    [self hide];
    [super onUnbindData];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidRenderFirstFrame {
    SLOGI(@"First frame rendered, hiding cover");
    // 置标记，此后不允许任何路径再显示封面
    self.firstFrameRendered = YES;
    // 直接隐藏，不使用淡出动画
    // 封面与画面的显示范围已经一致，淡出反而会让静态封面叠在已经运动的画面上，产生重影
    [self hide];
    // NOTE: 这里不取消在途的图片加载
    // 插槽已经隐藏，图片晚点回来也贴不到画面上；让它下载完还能进本地缓存，下次直接命中
}

// 来源二：Vid 播放方式下 SDK 从媒体信息中提取的封面地址，prepare 完成后才回调
// 取地址这一步天然后置，从绑定到这一刻之间可能有一段短暂黑屏
// 想消掉这段黑屏只能改用来源一：绑定时就把 coverUrl 传进来，并提前预加载图片
- (void)playerDidReadyCoverUrl:(NSString *)coverUrl {
    // 仅在未使用外部 coverUrl 时，使用自动提取的值
    if (self.externalCoverUsed || coverUrl.length == 0) {
        return;
    }
    // 首帧已经渲染，此时再显示封面会盖住正在播放的画面
    if (self.firstFrameRendered) {
        SLOGI(@"Cover URL arrived after first frame, ignored");
        return;
    }
    // NOTE: 此处不要再包一层 dispatch_async，通知分发已保证在主线程回调
    // 多包一层会把执行推迟到下一个 runloop 周期，导致上面的首帧判断失效
    [self loadCoverWithURL:coverUrl];
    [self show];
}

- (void)playerDidChangeScaleMode:(ScaleMode)scaleMode {
    self.coverImageView.contentMode = ContentModeForScaleMode(scaleMode);
}

#pragma mark - Private Methods

// 将封面的绘制模式同步为当前播放器的缩放模式
// 状态未就绪时按播放器默认值 FitCenter 处理
- (void)applyCurrentScaleMode {
    PlayerStateStore *stateStore = self.host.playerStateStore;
    ScaleMode scaleMode = stateStore ? stateStore.scaleMode : ScaleModeFitCenter;
    self.coverImageView.contentMode = ContentModeForScaleMode(scaleMode);
}

// 加载封面图并交由 SDWebImage 贴到 imageView 上
// 完成回调只打日志，不改可见性：
// 加载失败时插槽虽然显示着，但没有图、没有背景色、触摸也穿透，对画面和交互都没有影响；
// 反过来如果在这里 hide，一个迟到的失败回调会把新一轮已经显示出来的封面误隐藏掉
- (void)loadCoverWithURL:(NSString *)urlString {
    SLOGI(@"Loading cover: %@", urlString);

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        SLOGW(@"Invalid cover URL: %@", urlString);
        return;
    }

    // NOTE: sd_setImageWithURL: 会自动取消同一个 imageView 上尚未完成的上一次加载
    [self.coverImageView sd_setImageWithURL:url
                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (error) {
            // 若提示 App Transport Security 错误，请在宿主 App 的 Info.plist 中添加：
            // <key>NSAppTransportSecurity</key>
            // <dict><key>NSAllowsArbitraryLoads</key><true/></dict>
            SLOGW(@"Cover load failed: %@", error.localizedDescription);
        } else {
            SLOGI(@"Cover image loaded successfully");
        }
    }];
}

@end
