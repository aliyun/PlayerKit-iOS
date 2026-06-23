# **多视频源支持**

**视频源 (Video Source)** 是 AliPlayerKit 的数据基础模块。它定义了多种视频源类型，支持 VidAuth、VidSts、URL 三种播放方式，实现统一的视频资源配置与管理。

---

## **1. 概念介绍**

### **1.1 什么是视频源？**

**视频源 (Video Source)** 是播放器播放视频的数据来源，定义了视频资源的获取方式和授权机制。

AliPlayerKit 支持 3 种视频源类型：

| 视频源类型 | 授权方式 | 安全级别 | 适用场景 |
|-----------|---------|---------|---------|
| VidAuth | VID + 播放凭证 | 中等 | **推荐**，大多数生产环境 |
| VidSts | VID + STS 临时凭证 | 高 | 高安全性场景 |
| URL | 直接 URL 地址 | 低 | 公开资源、测试演示 |

### **1.2 如何选择视频源类型？**

根据业务场景和安全需求选择合适的视频源类型：

| 需求 | 推荐类型 | 说明 |
|-----|---------|------|
| 需要授权且安全性要求一般 | VidAuth（推荐） | 授权机制简单，易于集成 |
| 高安全性和临时访问凭证 | VidSts | 临时凭证，支持精细权限控制 |
| 公开视频资源 | URL | 无需授权，使用简单 |

---

## **2. 功能特性**

### **2.1 核心能力**

| 能力 | 说明 |
|-----|------|
| VidAuth 播放 | 通过 VID 和播放凭证进行授权播放 |
| VidSts 播放 | 通过 VID 和 STS 临时凭证进行授权播放 |
| URL 播放 | 通过直接 URL 地址播放视频 |
| 参数验证 | `isValid` 方法验证配置有效性 |
| 唯一标识 | 每个视频源有唯一的 `uniqueId`，用于播放器池复用 |
| 工厂创建 | 通过 `VideoSource` 类方法简化创建过程 |

### **2.2 内置组件**

| 组件 | 类型 | 说明 |
|------|------|------|
| `VideoSource` | 基类 | 视频源抽象基类，定义统一接口 |
| `VideoSourceType` | 枚举 | 视频源类型定义 |

---

## **3. 视频源类型详解**

### **3.1 VidAuth 模式（推荐）**

通过视频 ID (VID) 和播放凭证 (PlayAuth) 进行授权播放。授权机制简单，易于集成，**推荐用于大多数业务场景**。

**适用场景**：

- 需要授权验证的视频资源
- 大多数生产环境的视频播放
- 需要简单且安全的授权方式

**参数说明**：

| 参数 | 类型 | 必需 | 说明 |
|------|------|:----:|------|
| `vid` | `NSString *` | 是 | 视频唯一标识符 |
| `playAuth` | `NSString *` | 是 | 播放授权码（应从服务端获取） |

**使用示例**：

```objc
// 创建 VidAuth 类型的视频源
VideoSource *videoSource =
    [VideoSource vidAuthSourceWithVid:@"your_video_id"
                             playAuth:@"your_play_auth"];

// 创建播放数据
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
model.sceneType = SceneTypeVOD;
model.autoPlay = YES;
```

### **3.2 VidSts 模式**

通过视频 ID (VID) 和阿里云 STS (Security Token Service) 临时凭证播放视频，提供更高的安全性和访问控制。

**适用场景**：

- 需要临时访问凭证的场景
- 高安全性要求的视频资源
- 需要精细访问控制的场景

**参数说明**：

| 参数 | 类型 | 必需 | 说明 |
|------|------|:----:|------|
| `vid` | `NSString *` | 是 | 视频唯一标识符 |
| `accessKeyId` | `NSString *` | 是 | STS 访问密钥 ID |
| `accessKeySecret` | `NSString *` | 是 | STS 访问密钥密文 |
| `securityToken` | `NSString *` | 是 | STS 安全令牌 |
| `region` | `NSString *` | 否 | 区域信息，如 `@"cn-shanghai"` |

**使用示例**：

```objc
// 创建 VidSts 类型的视频源
VideoSource *videoSource =
    [VideoSource vidStsSourceWithVid:@"your_video_id"
                         accessKeyId:@"your_access_key_id"
                     accessKeySecret:@"your_access_key_secret"
                       securityToken:@"your_security_token"
                              region:@"cn-shanghai"];

// 创建播放数据
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
model.sceneType = SceneTypeVOD;
model.autoPlay = YES;
```

### **3.3 URL 模式**

通过直接提供视频 URL 进行播放，适用于公开访问的视频资源。

**适用场景**：

- 公开的视频资源，无需授权验证
- 测试和演示场景
- 简单的视频播放需求

**参数说明**：

| 参数 | 类型 | 必需 | 说明 |
|------|------|:----:|------|
| `url` | `NSString *` | 是 | 视频 URL 地址 |

**使用示例**：

```objc
// 创建 URL 类型的视频源
VideoSource *videoSource =
    [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];

// 创建播放数据
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
```

### **3.4 三种视频源对比表**

| 特性 | VidAuth | VidSts | URL |
|-----|---------|--------|-----|
| 授权方式 | 播放凭证 | 临时访问凭证 | 无需授权 |
| 参数数量 | 2 个 | 4~5 个 | 1 个 |
| 安全级别 | 中等 | 高 | 低 |
| 适用场景 | 大多数业务 | 高安全场景 | 公开资源 |
| 推荐度 | **推荐** | 特殊需求 | 测试/演示 |
| MediaId 格式 | `vidauth:{vid}` | `vidsts:{vid}` | `url:{url}` |

---

## **4. 使用方式**

### **4.1 基本用法 — 使用工厂创建**

通过 `VideoSource` 工厂方法统一创建视频源：

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

### **4.2 基本用法 — 验证有效性**

配置播放器前调用 `isValid` 验证视频源配置：

```objc
VideoSource *source =
    [VideoSource vidAuthSourceWithVid:vid playAuth:playAuth];

if ([source isValid]) {
    // 配置有效，创建播放数据并开始播放
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    [self.controller configure:model];
    [self.playerView attach:self.controller];
} else {
    NSLog(@"视频源配置无效: %@", source);
}
```

### **4.3 基本用法 — 完整播放流程**

```objc
@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 1. 创建视频源（推荐从服务端获取 playAuth）
    VideoSource *videoSource =
        [VideoSource vidAuthSourceWithVid:@"your_video_id"
                                 playAuth:@"server_returned_play_auth"];

    // 2. 验证视频源
    if (![videoSource isValid]) {
        NSLog(@"视频源配置无效: %@", videoSource);
        return;
    }

    // 3. 创建播放数据
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
    model.sceneType = SceneTypeVOD;
    model.coverUrl = @"https://example.com/cover.jpg";
    model.autoPlay = YES;

    // 4. 创建控制器
    AliPlayerController *controller = [[AliPlayerController alloc] init];

    // 5. 配置并绑定到播放器视图
    [controller configure:model];
    [self.playerView attach:controller];
}

- (void)dealloc {
    [self.playerView detach];
}

@end
```

### **4.4 高级用法 — 切换视频源**

```objc
// 先解绑当前播放
[self.playerView detach];

// 创建新的视频源
VideoSource *newSource =
    [VideoSource vidAuthSourceWithVid:@"new_video_id"
                             playAuth:@"new_play_auth"];

// 创建新的播放数据并绑定
AliPlayerModel *newModel = [[AliPlayerModel alloc] initWithVideoSource:newSource];
AliPlayerController *newController = [[AliPlayerController alloc] init];
[newController configure:newModel];
[self.playerView attach:newController];
```

---

## **5. 最佳实践**

### **5.1 安全性建议**

| 建议 | 说明 |
|------|------|
| 不要硬编码敏感信息 | 避免在客户端代码中硬编码 `playAuth`、`accessKeySecret` 等 |
| 从服务器获取授权 | 通过服务器端接口获取授权信息，再传递给客户端 |
| 及时刷新凭证 | VidSts 令牌有有效期，需及时刷新 |
| 使用 HTTPS | 确保数据传输安全 |

```objc
// ✅ 推荐：从服务器获取授权信息
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
        [self.controller configure:model];
        [self.playerView attach:self.controller];
    }];
}
```

### **5.2 常见错误**

#### **错误 1：客户端硬编码敏感信息**

```objc
// ✘ 错误：硬编码 playAuth（安全风险）
VideoSource *source =
    [VideoSource vidAuthSourceWithVid:@"video_id"
                             playAuth:@"hardcoded_play_auth_value"];

// ✔ 正确：从服务器获取
NSString *playAuth = [self fetchPlayAuthFromServer:videoId];
VideoSource *source =
    [VideoSource vidAuthSourceWithVid:videoId playAuth:playAuth];
```

#### **错误 2：未验证视频源有效性**

```objc
// ✘ 错误：未验证就使用
VideoSource *source = [VideoSource vidAuthSourceWithVid:vid playAuth:playAuth];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
[self.controller configure:model];
[self.playerView attach:self.controller];

// ✔ 正确：先验证再使用
VideoSource *source = [VideoSource vidAuthSourceWithVid:vid playAuth:playAuth];
if ([source isValid]) {
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    [self.controller configure:model];
    [self.playerView attach:self.controller];
} else {
    NSLog(@"视频源配置无效");
}
```

#### **错误 3：STS 令牌过期未处理**

```objc
// ✘ 错误：使用过期令牌
VideoSource *source = [VideoSource vidStsSourceWithVid:vid
                                           accessKeyId:accessKeyId
                                       accessKeySecret:accessKeySecret
                                         securityToken:expiredToken
                                                region:region];

// ✔ 正确：检查并刷新令牌
if ([self isTokenExpired:securityToken]) {
    securityToken = [self refreshSecurityToken];
}
VideoSource *source = [VideoSource vidStsSourceWithVid:vid
                                           accessKeyId:accessKeyId
                                       accessKeySecret:accessKeySecret
                                         securityToken:securityToken
                                                region:region];
```

---

## **6. API 速查**

### **6.1 视频源类型枚举**

| 枚举值 | 数值 | 说明 |
|--------|------|------|
| `VideoSourceTypeVidAuth` | 0 | VidAuth 类型 |
| `VideoSourceTypeVidSts` | 1 | VidSts 类型 |
| `VideoSourceTypeUrl` | 2 | URL 类型 |

### **6.2 VideoSource**

| 属性 / 方法 | 类型 | 说明 |
|-------------|------|------|
| `sourceType` | `VideoSourceType` | 只读，视频源类型 |
| `uniqueId` | `NSString *` | 只读，唯一标识符 |
| `isValid` | `BOOL` | 验证配置有效性 |
| `toDictionary` | `NSDictionary *` | 转换为键值对 |

### **6.3 工厂方法**

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `vidAuthSourceWithVid:playAuth:` | `VideoSource *` | 创建 VidAuth 源 |
| `vidStsSourceWithVid:accessKeyId:accessKeySecret:securityToken:region:` | `VideoSource *` | 创建 VidSts 源 |
| `urlSourceWithUrl:` | `VideoSource *` | 创建 URL 源 |

### **6.4 MediaId 生成规则**

| 视频源类型 | MediaId 格式 | 示例 |
|-----------|-------------|------|
| VidAuth | `vidauth:{vid}` | `vidauth:abc123` |
| VidSts | `vidsts:{vid}` | `vidsts:abc123` |
| URL | `url:{url}` | `url:https://example.com/video.mp4` |

`uniqueId` 用于播放器生命周期策略中的实例复用，相同 `uniqueId` 的视频源会复用同一个播放器实例。

详细接口说明请参考 [API 参考文档](../ApiReference.md)。

---

## **下一步**

- [播放器生命周期策略](./PlayerLifecycleStrategy.md) — 了解播放器实例管理
- [日志系统](./LogSystem.md) — 了解 AliPlayerKit 的日志管理
- [API 参考](../ApiReference.md) — 完整 API 文档
