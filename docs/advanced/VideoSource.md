# **多视频源支持**

**视频源 (Video Source)** 是 AliPlayerKit 的数据基础模块。它定义了多种视频源类型，支持 VidAuth、VidSts、URL 三种播放方式，实现统一的视频资源配置与管理。

---

## **1. 概念介绍**

### **1.1 什么是视频源？**

**视频源 (Video Source)** 是播放器播放视频的数据来源，定义了视频资源的获取方式和授权机制。

AliPlayerKit 通过 `VideoSource` 类统一封装三种视频源类型：

| 视频源类型 | 授权方式 | 安全级别 | 适用场景 |
|-----------|---------|---------|---------|
| VidAuth | VID + 播放凭证 | 中等 | **推荐**，大多数生产环境 |
| VidSts | VID + STS 临时凭证 | 高 | 高安全性场景 |
| URL | 直接 URL 地址 | 低 | 公开资源、测试演示 |

### **1.2 如何选择视频源类型？**

| 需求 | 推荐类型 | 说明 |
|-----|---------|------|
| 需要授权且安全性要求一般 | VidAuth（推荐） | 授权机制简单，易于集成 |
| 高安全性和临时访问凭证 | VidSts | 临时凭证，支持精细权限控制 |
| 公开视频资源 | URL | 无需授权，使用简单 |

### **1.3 设计特点**

- **不可变对象**：`VideoSource` 的所有属性均为 `readonly`，创建后不可修改
- **工厂方法创建**：`init` 和 `new` 被标记为 `NS_UNAVAILABLE`，必须通过工厂类方法创建
- **参数校验**：工厂方法对必填参数进行空值和空字符串检查，校验失败返回 `nil`
- **有效性验证**：提供 `isValid` 方法在配置播放器前进行二次验证
- **唯一标识**：`uniqueId` 属性根据类型自动派生（VidAuth/VidSts 返回 `vid`，URL 返回 `url`），用于播放器生命周期策略中的实例复用

---

## **2. 视频源类型详解**

### **2.1 VidAuth 模式（推荐）**

通过视频 ID (VID) 和播放凭证 (PlayAuth) 进行授权播放。授权机制简单，易于集成，**推荐用于大多数业务场景**。

**适用场景**：

- 需要授权验证的视频资源
- 大多数生产环境的视频播放
- 需要简单且安全的授权方式

**参数说明**：

| 参数 | 类型 | 必需 | 说明 |
|------|------|:----:|------|
| `vid` | `NSString *` | 是 | 视频唯一标识符（不能为 nil 或空字符串） |
| `playAuth` | `NSString *` | 是 | 播放授权码（应从服务端获取，不能为 nil 或空字符串） |

**使用示例**：

```objc
VideoSource *videoSource =
    [VideoSource vidAuthSourceWithVid:@"your_video_id"
                             playAuth:@"your_play_auth"];

AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
model.sceneType = SceneTypeVOD;
model.autoPlay = YES;
```

### **2.2 VidSts 模式**

通过视频 ID (VID) 和阿里云 STS (Security Token Service) 临时凭证播放视频，提供更高的安全性和访问控制。

**适用场景**：

- 需要临时访问凭证的场景
- 高安全性要求的视频资源
- 需要精细访问控制的场景

**参数说明**：

| 参数 | 类型 | 必需 | 说明 |
|------|------|:----:|------|
| `vid` | `NSString *` | 是 | 视频唯一标识符（不能为 nil 或空字符串） |
| `accessKeyId` | `NSString *` | 是 | STS 访问密钥 ID（不能为 nil 或空字符串） |
| `accessKeySecret` | `NSString *` | 是 | STS 访问密钥密文（不能为 nil 或空字符串） |
| `securityToken` | `NSString *` | 是 | STS 安全令牌（不能为 nil 或空字符串） |
| `region` | `NSString *` | 否 | 区域信息（如 `@"cn-shanghai"`），`nil` 时使用默认区域 |

**使用示例**：

```objc
VideoSource *videoSource =
    [VideoSource vidStsSourceWithVid:@"your_video_id"
                         accessKeyId:@"your_access_key_id"
                     accessKeySecret:@"your_access_key_secret"
                       securityToken:@"your_security_token"
                              region:@"cn-shanghai"];

AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
model.sceneType = SceneTypeVOD;
model.autoPlay = YES;
```

### **2.3 URL 模式**

通过直接提供视频 URL 进行播放，适用于公开访问的视频资源。

**适用场景**：

- 公开的视频资源，无需授权验证
- 测试和演示场景
- 直播流播放

**参数说明**：

| 参数 | 类型 | 必需 | 说明 |
|------|------|:----:|------|
| `url` | `NSString *` | 是 | 视频 URL 地址（不能为 nil 或空字符串） |

**使用示例**：

```objc
VideoSource *videoSource =
    [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];

AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
```

### **2.4 三种视频源对比表**

| 特性 | VidAuth | VidSts | URL |
|-----|---------|--------|-----|
| 授权方式 | 播放凭证 | 临时访问凭证 | 无需授权 |
| 必填参数 | vid, playAuth | vid, accessKeyId, accessKeySecret, securityToken | url |
| 可选参数 | — | region | — |
| 安全级别 | 中等 | 高 | 低 |
| 适用场景 | 大多数业务 | 高安全场景 | 公开资源 / 直播 |
| 推荐度 | **推荐** | 特殊需求 | 测试 / 演示 |
| `uniqueId` 来源 | `vid` | `vid` | `url` |

---

## **3. 使用方式**

### **3.1 基本用法 — 使用工厂方法创建**

通过 `VideoSource` 工厂类方法创建视频源：

```objc
// VidAuth（推荐）
VideoSource *authSource =
    [VideoSource vidAuthSourceWithVid:@"your_video_id"
                             playAuth:@"your_play_auth"];

// VidSts
VideoSource *stsSource =
    [VideoSource vidStsSourceWithVid:@"your_video_id"
                         accessKeyId:@"your_access_key_id"
                     accessKeySecret:@"your_access_key_secret"
                       securityToken:@"your_security_token"
                              region:@"cn-shanghai"];

// URL
VideoSource *urlSource =
    [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
```

> **注意**：工厂方法在必填参数为 `nil` 或空字符串时返回 `nil`。调用方应检查返回值。

### **3.2 基本用法 — 验证有效性**

配置播放器前调用 `isValid` 验证视频源配置：

```objc
VideoSource *source =
    [VideoSource vidAuthSourceWithVid:vid playAuth:playAuth];

if (source && [source isValid]) {
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    [self.controller configure:model];
} else {
    NSLog(@"视频源配置无效: %@", source);
}
```

**`isValid` 验证规则**：

| 类型 | 验证条件 |
|------|---------|
| VidAuth | `vid.length > 0 && playAuth.length > 0` |
| VidSts | `vid.length > 0 && accessKeyId.length > 0 && accessKeySecret.length > 0 && securityToken.length > 0` |
| URL | `url.length > 0` |

> **说明**：VidSts 的 `region` 为可选参数，不参与 `isValid` 验证。

### **3.3 基本用法 — 完整播放流程**

```objc
@interface PlayerViewController ()
@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *playerController;
@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 1. 创建视频源（推荐从服务端获取 playAuth）
    VideoSource *videoSource =
        [VideoSource vidAuthSourceWithVid:@"your_video_id"
                                 playAuth:@"server_returned_play_auth"];

    // 2. 验证视频源
    if (!videoSource || ![videoSource isValid]) {
        NSLog(@"视频源配置无效: %@", videoSource);
        return;
    }

    // 3. 创建播放数据
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
    model.sceneType = SceneTypeVOD;
    model.coverUrl = @"https://example.com/cover.jpg";
    model.autoPlay = YES;

    // 4. 创建控制器并配置
    self.playerController = [[AliPlayerController alloc] init];
    [self.playerController configure:model];

    // 5. 绑定到播放器视图
    [self.playerView attach:self.playerController];
}

- (void)dealloc {
    [_playerView detach];
    [_playerController destroy];
}

@end
```

### **3.4 高级用法 — 切换视频源**

在同一个控制器上切换不同视频源，只需用新的 `AliPlayerModel` 重新调用 `configure:`：

```objc
- (void)switchToNewVideo:(NSString *)newVid playAuth:(NSString *)newPlayAuth {
    VideoSource *newSource =
        [VideoSource vidAuthSourceWithVid:newVid playAuth:newPlayAuth];

    AliPlayerModel *newModel = [[AliPlayerModel alloc] initWithVideoSource:newSource];
    newModel.videoTitle = @"新视频";

    // 在同一个控制器上重新配置即可
    [self.playerController configure:newModel];
}
```

---

## **4. 最佳实践**

### **4.1 安全性建议**

| 建议 | 说明 |
|------|------|
| 不要硬编码敏感信息 | 避免在客户端代码中硬编码 `playAuth`、`accessKeySecret` 等 |
| 从服务器获取授权 | 通过服务器端接口获取授权信息，再传递给客户端 |
| 及时刷新凭证 | VidSts 令牌有有效期，需及时刷新 |
| 使用 HTTPS | 确保数据传输安全 |

```objc
// 推荐：从服务器获取授权信息
- (void)playVideoWithId:(NSString *)videoId {
    [self.apiService fetchPlayAuthForVideoId:videoId
                                  completion:^(NSString *playAuth, NSError *error) {
        if (error) {
            NSLog(@"获取播放凭证失败: %@", error);
            return;
        }

        VideoSource *source =
            [VideoSource vidAuthSourceWithVid:videoId playAuth:playAuth];
        AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
        [self.playerController configure:model];
    }];
}
```

### **4.2 常见错误**

#### **错误 1：未检查工厂方法返回值**

```objc
// ✗ 错误：工厂方法在参数无效时返回 nil，未检查
VideoSource *source = [VideoSource vidAuthSourceWithVid:vid playAuth:playAuth];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source]; // source 可能为 nil

// ✓ 正确：检查返回值
VideoSource *source = [VideoSource vidAuthSourceWithVid:vid playAuth:playAuth];
if (source && [source isValid]) {
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    [self.playerController configure:model];
}
```

#### **错误 2：客户端硬编码敏感信息**

```objc
// ✗ 错误：硬编码 playAuth（安全风险）
VideoSource *source =
    [VideoSource vidAuthSourceWithVid:@"video_id"
                             playAuth:@"hardcoded_play_auth_value"];

// ✓ 正确：从服务器获取
NSString *playAuth = [self fetchPlayAuthFromServer:videoId];
VideoSource *source =
    [VideoSource vidAuthSourceWithVid:videoId playAuth:playAuth];
```

#### **错误 3：STS 令牌过期未处理**

```objc
// ✗ 错误：使用过期令牌
VideoSource *source = [VideoSource vidStsSourceWithVid:vid
                                           accessKeyId:accessKeyId
                                       accessKeySecret:accessKeySecret
                                         securityToken:expiredToken
                                                region:region];

// ✓ 正确：检查并刷新令牌
if ([self isTokenExpired:securityToken]) {
    securityToken = [self refreshSecurityToken];
}
VideoSource *source = [VideoSource vidStsSourceWithVid:vid
                                           accessKeyId:accessKeyId
                                       accessKeySecret:accessKeySecret
                                         securityToken:securityToken
                                                region:region];
```

#### **错误 4：使用 init 创建实例**

```objc
// ✗ 编译错误：init 和 new 被标记为 NS_UNAVAILABLE
VideoSource *source = [[VideoSource alloc] init]; // 编译报错

// ✓ 正确：使用工厂类方法
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
```

---

## **5. API 速查**

### **5.1 视频源类型枚举 (VideoSourceType)**

| 枚举值 | 数值 | 说明 |
|--------|------|------|
| `VideoSourceTypeVidAuth` | 0 | VID + PlayAuth 播放凭证播放源（推荐） |
| `VideoSourceTypeVidSts` | 1 | VID + STS 临时凭证播放源 |
| `VideoSourceTypeUrl` | 2 | URL 直接播放源 |

### **5.2 VideoSource 属性**

| 属性 | 类型 | 说明 |
|------|------|------|
| `sourceType` | `VideoSourceType` | 视频源类型（`readonly`） |
| `uniqueId` | `NSString *` | 唯一标识符，VidAuth/VidSts 返回 `vid`，URL 返回 `url`（`readonly`，nullable） |
| `url` | `NSString *` | 视频 URL 地址，仅 URL 类型有效（`readonly`，nullable） |
| `vid` | `NSString *` | 视频唯一标识符，VidAuth 和 VidSts 类型有效（`readonly`，nullable） |
| `playAuth` | `NSString *` | 播放授权码，仅 VidAuth 类型有效（`readonly`，nullable） |
| `accessKeyId` | `NSString *` | STS 访问密钥 ID，仅 VidSts 类型有效（`readonly`，nullable） |
| `accessKeySecret` | `NSString *` | STS 访问密钥密文，仅 VidSts 类型有效（`readonly`，nullable） |
| `securityToken` | `NSString *` | STS 安全令牌，仅 VidSts 类型有效（`readonly`，nullable） |
| `region` | `NSString *` | 区域信息，仅 VidSts 类型有效（`readonly`，nullable） |

### **5.3 VideoSource 方法**

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `+vidAuthSourceWithVid:playAuth:` | `instancetype` | 创建 VidAuth 源（参数无效时返回 `nil`） |
| `+vidStsSourceWithVid:accessKeyId:accessKeySecret:securityToken:region:` | `instancetype` | 创建 VidSts 源（参数无效时返回 `nil`，`region` 可为 `nil`） |
| `+urlSourceWithUrl:` | `instancetype` | 创建 URL 源（参数无效时返回 `nil`） |
| `-isValid` | `BOOL` | 验证当前视频源配置是否有效 |

> **注意**：`+new` 和 `-init` 被标记为 `NS_UNAVAILABLE`，必须通过工厂类方法创建实例。

### **5.4 相关文件**

| 文件 | 说明 |
|------|------|
| `PlayerKit/Source/Data/VideoSource.h` | VideoSource 类及 VideoSourceType 枚举定义 |
| `PlayerKit/Source/Data/VideoSource.m` | VideoSource 实现（工厂方法、isValid、uniqueId 派生） |
| `PlayerKit/Source/AliPlayerModel.h` | 播放数据模型（通过 `initWithVideoSource:` 接收视频源） |

> 完整 API 详见 [API 参考](../ApiReference.md)。

---

## **6. 示例参考**

> **参考**：`PlayerKitUsages/UsageVideoSource` 模块提供了完整的视频源使用示例，包含三种视频源类型的创建、参数校验和播放流程。
