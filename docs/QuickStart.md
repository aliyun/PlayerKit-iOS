> 📚 **推荐阅读路径**
>
> [核心能力](./CoreFeatures.md) → [集成准备](./Integration.md) → **快速开始** → [API 参考](./ApiReference.md)

---

# **AliPlayerKit 快速开始**

只需几步，您就可以轻松实现视频播放功能！

通过极简的 API 设计，帮助您以低代码的方式快速集成视频播放功能，无需直接调用底层播放器 API，也无需自行实现复杂的播放器 UI。

> **注意**：在开始之前，请确保您已经按照 [集成准备](./Integration.md) 完成环境配置和依赖添加。

---

## **1. 接入流程概览**

只需几步，您就可以轻松实现视频播放功能！**AliPlayerKit 提供了极简的 API 设计**，帮助您以低代码的方式快速集成视频播放功能。

下图展示了 **组件层接入** 的基本流程：

![QuickStart](https://alivc-demo-cms.alicdn.com/versionProduct/installPackage/AliPlayerKit/iOS/QuickStart.png)

---

## **2. 选择接入方案**

AliPlayerKit 采用 **分层架构设计**。除组件层接入外，还提供 **场景层接入方式**，您可以根据业务需求灵活选择：

| 接入方案 | 模块 | 说明 | 适用场景 |
|---------|------|---------|---------|
| **方案一：组件层接入** | `PlayerKit` | 使用 `PlayerKit` 核心模块，提供可配置的播放器 UI 组件 | 需要自定义播放器 UI 或灵活控制播放行为 |
| **方案二：场景层接入** | `PlayerKitScenes` | 在组件层基础上，使用完整业务场景解决方案 | 快速实现标准播放场景，如长视频、短视频、直播 |

> **说明**：场景层依赖组件层。若选择场景层接入，需先完成组件层接入。

---

## **3. 全局初始化**

在 `AppDelegate` 的 `application:didFinishLaunchingWithOptions:` 中调用 `[AliPlayerKit setup]` 进行全局初始化。整个应用生命周期只需调用一次，用于初始化播放器内核和全局配置。

* **Objective-C**：

```objc
#import <AliPlayerKit/AliPlayerKit.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 初始化 AliPlayerKit 全局设置
    [AliPlayerKit setup];
    return YES;
}

@end
```

* **Swift**：

```swift
import AliPlayerKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 初始化 AliPlayerKit 全局设置
        AliPlayerKit.setup()
        return true
    }
}
```

> **说明**：`AliPlayerKit` 还提供其他全局配置接口，如日志系统、预加载策略等，详见 [API 参考](./ApiReference.md)。

---

## **4. 方案一：组件层接入**

组件层（`PlayerKit` 模块）提供开箱即用、可配置的播放器 UI 组件。在每个需要播放视频的页面中，按以下步骤实现播放功能。

> **前置条件**：在接入组件层之前，请先完成 [集成准备](./Integration.md) 中的组件层集成步骤，并完成全局初始化。

### **步骤 1：添加播放器视图**

在 ViewController 中通过纯代码创建 `AliPlayerView` 并添加到视图层级：

* **Objective-C**：

```objc
AliPlayerView *playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
[self.view addSubview:playerView];
```

* **Swift**：

```swift
let playerView = AliPlayerView(frame: view.bounds)
view.addSubview(playerView)
```

`AliPlayerView` 可放置在您视图层级的任意位置，frame 可根据实际需求设置。如需支持全屏切换，组件内部会自动处理视图层级调整。

### **步骤 2：绑定控制器并播放**

> **重要**：`configure:` 必须在 `attach:` 之前调用，否则视图绑定时无法获取播放配置。

在 ViewController 中创建控制器、配置数据、绑定视图：

1. 创建 `AliPlayerController`
2. 配置 `AliPlayerModel`（推荐使用 VidAuth 方式，也可使用 URL 源快速测试）
3. 调用 `configure:` + `attach:`
4. 在 `dealloc` 中调用 `destroy` 释放资源

* **Objective-C**：

```objc
#import <AliPlayerKit/AliPlayerKit.h>

@interface VideoPlayerViewController ()
@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *controller;
@end

@implementation VideoPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 1. 创建播放器视图
    self.playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.playerView];

    // 2. 创建播放控制器
    self.controller = [[AliPlayerController alloc] init];

    // 3. 配置播放数据（推荐使用 VidAuth 方式）
    VideoSource *source = [VideoSource vidAuthSourceWithVid:@"您的视频 ID"
                                                  playAuth:@"您的播放凭证"];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    model.videoTitle = @"示例视频";

    // 4. 配置播放源并绑定视图（绑定后自动开始播放）
    [self.controller configure:model];
    [self.playerView attach:self.controller];
}

- (void)dealloc {
    // 销毁播放器，释放资源
    [self.controller destroy];
}

@end
```

* **Swift**：

```swift
import AliPlayerKit

class VideoPlayerViewController: UIViewController {

    private let playerView = AliPlayerView(frame: .zero)
    private let controller = AliPlayerController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. 创建播放器视图
        playerView.frame = view.bounds
        view.addSubview(playerView)

        // 2. 配置播放数据（推荐使用 VidAuth 方式）
        let source = VideoSource.vidAuthSource(withVid: "您的视频 ID", playAuth: "您的播放凭证")
        let model = AliPlayerModel(videoSource: source)
        model.videoTitle = "示例视频"

        // 3. 配置播放源并绑定视图（绑定后自动开始播放）
        controller.configure(model)
        playerView.attach(controller)
    }

    deinit {
        // 销毁播放器，释放资源
        controller.destroy()
    }
}
```

> **提示**：如果暂时无法获取 **视频 ID** 和 **播放凭证**，可使用 URL 源快速测试：
>
> ```objc
> VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
> ```
>
> 场景模块内置了 `SceneConstants` 示例数据，也可直接参考使用。

> **说明**：
>
> - `AliPlayerModel.autoPlay` 默认为 `YES`，配置完成后自动开始播放，无需手动调用 `play`
> - `AliPlayerController.autoLifecycleManagement` 默认为 `YES`，会自动处理应用前后台切换时的播放暂停与恢复。但页面级导航（如 push/pop）需要手动在 `viewDidAppear` / `viewWillDisappear` 中调用 `onResume` / `onPause`
> - `configure:` 内部通过生命周期策略获取播放器实例、设置数据源并准备播放
> - `dealloc` 中必须调用 `destroy` 销毁控制器，否则会导致内存泄漏

### **步骤 3（可选）：处理返回键**

如果您需要自定义播放器的返回行为，可通过 `onBackPressed` 回调实现：

* **Objective-C**：

```objc
__weak typeof(self) weakSelf = self;
self.playerView.onBackPressed = ^{
    [weakSelf.navigationController popViewControllerAnimated:YES];
};
```

* **Swift**：

```swift
playerView.onBackPressed = { [weak self] in
    self?.navigationController?.popViewController(animated: true)
}
```

> **说明**：当播放器处于全屏状态时，返回操作会自动退出全屏，不触发此回调。仅在非全屏状态下，返回操作才会通过此回调通知外部。若未设置此回调，播放器将通过 responder chain 尝试默认导航行为（pop / dismiss）。
>
> **跨平台差异**：Android 端通过 `Activity.onBackPressed()` 拦截，调用 `playerView.onBackPressed()` 方法并根据返回值判断是否已消费；iOS 端通过 Block 回调通知外部。

### **步骤 4（可选）：自定义配置**

如需在播放器准备前注入自定义 SDK 配置（如缓冲策略、Referer 等），可通过 `onPlayerConfigBlock` 实现：

* **Objective-C**：

```objc
model.onPlayerConfigBlock = ^(id<MediaPlayer> player) {
    // 在 prepare 前执行，可访问底层播放器实例进行自定义配置
    // 例如：设置缓冲配置、Referer、setOption 等
};
```

* **Swift**：

```swift
model.onPlayerConfigBlock = { player in
    // 在 prepare 前执行，可访问底层播放器实例进行自定义配置
}
```

> **说明**：全局配置通过 `[AliPlayerKit setOnGlobalInitBlock:]` 在 `setup` 前设置（仅执行一次）；实例配置通过 `model.onPlayerConfigBlock` 在每次 `configure:` 时触发。详见 [自定义配置](./advanced/CustomConfig.md)。

---

## **5. 方案二：场景层接入**

场景层提供针对特定业务场景的完整播放解决方案，如长视频、短视频、直播等。场景层基于组件层封装，集成后即可开箱使用，无需额外开发。

> **前置条件**：在接入场景层之前，请先完成 [集成准备](./Integration.md) 中的场景层集成步骤，并完成全局初始化。

### **步骤 1：选择场景模块**

场景模块位于 `PlayerKitScenes` 目录下，通过 CocoaPods subspecs 引入，当前包含：

| 场景模块 | Pod Subspec | 说明 |
|---------|-------------|------|
| `SceneCommon` | `PlayerKitScenes/SceneCommon` | 场景公共模块（必需，其他场景模块的基础依赖） |
| `SceneLongVideo` | `PlayerKitScenes/SceneLongVideo` | **中长视频场景**：提供中长视频播放的完整解决方案 |
| `SceneShortVideo` | `PlayerKitScenes/SceneShortVideo` | **短视频场景**：提供短视频滑动播放的完整解决方案 |
| `SceneLive` | `PlayerKitScenes/SceneLive` | **直播场景**：提供直播播放的完整解决方案 |
| `ScenePlaylist` | `PlayerKitScenes/ScenePlaylist` | **列表播放场景**：提供视频列表播放的完整解决方案 |

> **跨平台对齐**：场景模块与 Android 端对齐（`scene-longvideo` / `scene-shortvideo` / `scene-live` / `scene-playlist`）。各场景的业务能力和 UI 交互在多端间保持一致。

### **步骤 2：启动场景页面**

场景模块集成完成后，可通过以下两种方式启动场景页面：

#### **方式一：直接实例化（推荐）**

每个场景模块提供独立的 ViewController，可直接实例化并通过 `UINavigationController` 跳转：

* **Objective-C**：

```objc
#import "SceneLongVideoViewController.h"

// 跳转到中长视频场景
SceneLongVideoViewController *vc = [[SceneLongVideoViewController alloc] init];
[self.navigationController pushViewController:vc animated:YES];
```

* **Swift**：

```swift
// 跳转到中长视频场景
let vc = SceneLongVideoViewController()
navigationController?.pushViewController(vc, animated: true)
```

各场景对应的 ViewController：

| 场景 | ViewController |
|------|----------------|
| 中长视频 | `SceneLongVideoViewController` |
| 短视频 | `SceneShortVideoViewController` |
| 直播 | `SceneLiveViewController` |
| 列表播放 | `ScenePlaylistViewController` |

#### **方式二：Schema 路由**

场景模块支持通过 Schema 协议启动对应的播放场景。Demo 工程中提供了 `AppSchemaRouter` 路由工具类，可通过 Schema URL 自动发现并跳转到对应场景：

* **Objective-C**：

```objc
#import "AppSchemaRouter.h"

// 通过 Schema 跳转到中长视频场景
[AppSchemaRouter navigateToSchema:@"playerkit://scenes/longvideo" fromViewController:self];
```

* **Swift**：

```swift
// 通过 Schema 跳转到中长视频场景
AppSchemaRouter.navigate(toSchema: "playerkit://scenes/longvideo", from: self)
```

各场景对应的 Schema 地址：

| 场景 | Schema |
|------|--------|
| 中长视频 | `playerkit://scenes/longvideo` |
| 短视频 | `playerkit://scenes/shortvideo` |
| 直播 | `playerkit://scenes/live` |
| 列表播放 | `playerkit://scenes/playlist` |

> **说明**：`AppSchemaRouter` 是 Demo 工程（`App` 模块）中提供的路由工具，基于 `AppModuleProtocol` 协议实现模块自动发现。场景模块通过 `*Module` 类（如 `SceneLongVideoModule`）注册自身的 Schema、标题和优先级。如需在您的应用中使用 Schema 路由，可参考此实现或对接您自己的路由框架。
>
> **跨平台对比**：Android 端通过 `Intent` + `AndroidManifest.xml` 的 `<intent-filter>` 实现 Schema 路由；iOS 端通过 `AppModuleProtocol` + 运行时反射实现模块自动发现。Schema 格式在各平台间保持一致。

---

## **6. 场景实现参考**

场景模块的源码可作为组件层接入的最佳实践参考。以下是各场景的核心实现模式：

### **6.1 中长视频场景**

`SceneLongVideoViewController` 展示了标准的组件层接入流程：

```objc
// 初始化 AliPlayerKit 播放组件
- (void)setupPlayerKit {
    // 1. 创建播放器组件视图
    self.playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.playerView];

    // 可选：设置返回键回调
    __weak typeof(self) weakSelf = self;
    self.playerView.onBackPressed = ^{
        [weakSelf.navigationController popViewControllerAnimated:YES];
    };

    // 2. 创建播放器组件控制器
    self.playerController = [[AliPlayerController alloc] init];

    // 3. 配置播放器组件数据
    VideoSource *source = [VideoSource vidAuthSourceWithVid:@"视频 ID" playAuth:@"播放凭证"];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    model.videoTitle = @"Long Video";

    // 4. 配置播放源并将控制器挂载到视图（挂载后自动开始播放）
    [self.playerController configure:model];
    [self.playerView attach:self.playerController];
}
```

### **6.2 直播场景**

`SceneLiveViewController` 展示了 URL 源 + 直播场景类型的用法：

```objc
VideoSource *source = [VideoSource urlSourceWithUrl:liveUrl];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.videoTitle = @"Live Stream";
model.sceneType = SceneTypeLive;  // 设置为直播场景类型

[self.playerController configure:model];
[self.playerView attach:self.playerController];
```

> **说明**：`SceneType` 影响插槽可见性配置和 UI 行为。直播场景下会自动隐藏进度条等点播元素。详见 [场景类型](./advanced/SceneType.md)。

### **6.3 列表播放场景**

`ScenePlaylistViewController` 展示了 `SingletonLifecycleStrategy` + `PlayerNotificationDelegate` 实现自动连播的高级用法：

```objc
// 使用单例生命周期策略复用播放器实例
self.lifecycleStrategy = [SingletonLifecycleStrategy sharedInstance];
self.currentController = [[AliPlayerController alloc] initWithLifecycleStrategy:self.lifecycleStrategy];

// 注册播放完成通知，用于触发自动播放下一个
[self.currentController addNotificationDelegate:self];

// PlayerNotificationDelegate 回调
- (void)playerDidCompletion {
    [self playNextVideo];  // 当前视频播放完成，自动播放下一个
}
```

> **说明**：列表播放场景通过 `initWithLifecycleStrategy:` 指定生命周期策略，复用播放器实例以提升性能。详见 [播放器生命周期策略](./advanced/PlayerLifecycleStrategy.md)。

---

## **7. 示例与扩展**

通过以上步骤，您已经完成了 AliPlayerKit 的基础接入，并成功实现了视频播放。

如需查看更多示例，可参考以下目录：

| 模块 | 说明 |
|------|------|
| `PlayerKitUsages` | 提供常见 API 的使用示例（日志系统、插槽系统、通知系统、策略系统、生命周期策略、预加载、视频源、本地化） |
| `PlayerKitScenes` | 提供典型播放场景的解决方案（长视频、短视频、直播、列表播放） |

各使用示例的 Schema 路由格式为 `playerkit://usages/<模块名>`，可通过 Demo 工程首页直接进入。

如果您在接入或使用过程中遇到问题，可联系官方技术支持获取帮助。

---

如需查看各组件和接口的详细说明，请参考 **[API 参考](./ApiReference.md)**。
