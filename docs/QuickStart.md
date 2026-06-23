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

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  全局初始化      │ ──▶ │  创建视图        │ ──▶ │  配置数据        │ ──▶ │  绑定并播放      │
│  [AliPlayerKit   │     │  AliPlayerView   │     │  AliPlayerModel  │     │  attach + play   │
│   setup]         │     │                  │     │  configure       │     │                  │
└─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
```

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

> **前置条件**：在接入组件层之前，请先完成 [集成准备](./Integration.md) 中的组件层集成步骤，并完成 [全局初始化](#3-全局初始化)。

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
    model.autoPlay = YES;
    [self.controller configure:model];

    // 4. 绑定视图与控制器
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
        model.autoPlay = true
        controller.configure(model)

        // 3. 绑定视图与控制器
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

### **步骤 3（可选）：处理返回键**

如果您需要自定义播放器的返回行为，可通过 `onBackPressed` 回调实现：

* **Objective-C**：

```objc
__weak typeof(self) weakSelf = self;
playerView.onBackPressed = ^{
    [weakSelf.navigationController popViewControllerAnimated:YES];
};
```

* **Swift**：

```swift
playerView.onBackPressed = { [weak self] in
    self?.navigationController?.popViewController(animated: true)
}
```

> **说明**：当播放器处于全屏状态时，返回操作会自动退出全屏，不触发此回调。仅在非全屏状态下，返回操作才会通过此回调通知外部。若未设置此回调，播放器将执行默认导航行为（pop/dismiss）。

---

## **5. 方案二：场景层接入**

场景层提供针对特定业务场景的完整播放解决方案，如长视频、短视频、直播等。场景层基于组件层封装，集成后即可开箱使用，无需额外开发。

> **前置条件**：在接入场景层之前，请先完成 [集成准备](./Integration.md) 中的场景层集成步骤，并完成 [全局初始化](#3-全局初始化)。

### **步骤 1：选择场景模块**

场景模块位于 `PlayerKitScenes` 目录下，通过 CocoaPods subspecs 引入，当前包含：

| 场景模块 | Pod Subspec | 说明 |
|---------|-------------|------|
| `SceneCommon` | `PlayerKitScenes/SceneCommon` | 场景公共模块（必需，其他场景模块的基础依赖） |
| `SceneLongVideo` | `PlayerKitScenes/SceneLongVideo` | **中长视频场景**：提供中长视频播放的完整解决方案 |
| `SceneShortVideo` | `PlayerKitScenes/SceneShortVideo` | **短视频场景**：提供短视频滑动播放的完整解决方案 |
| `SceneLive` | `PlayerKitScenes/SceneLive` | **直播场景**：提供直播播放的完整解决方案 |
| `ScenePlaylist` | `PlayerKitScenes/ScenePlaylist` | **列表播放场景**：提供视频列表播放的完整解决方案 |

### **步骤 2：启动场景页面**

场景模块集成完成后，可通过以下两种方式启动场景页面：

#### **方式一：直接实例化**

* **Objective-C**：

```objc
#import <PlayerKitScenes/SceneLongVideo.h>

// 跳转到中长视频场景
SceneLongVideoViewController *vc = [[SceneLongVideoViewController alloc] init];
[self.navigationController pushViewController:vc animated:YES];
```

* **Swift**：

```swift
import PlayerKitScenes

// 跳转到中长视频场景
let vc = SceneLongVideoViewController()
navigationController?.pushViewController(vc, animated: true)
```

#### **方式二：Schema 路由**

场景模块支持通过 Schema 协议启动对应的播放场景。Schema 格式为：`playerkit://scenes/<场景名>`

各场景对应的 Schema 地址：

| 场景 | Schema |
|------|--------|
| 中长视频 | `playerkit://scenes/longvideo` |
| 短视频 | `playerkit://scenes/shortvideo` |
| 直播 | `playerkit://scenes/live` |
| 列表播放 | `playerkit://scenes/playlist` |

* **Objective-C**：

```objc
#import <App/App.h>

// 通过 Schema 跳转到中长视频场景
[AppSchemaRouter navigateToSchema:@"playerkit://scenes/longvideo" fromViewController:self];
```

* **Swift**：

```swift
import App

// 通过 Schema 跳转到中长视频场景
AppSchemaRouter.navigate(toSchema: "playerkit://scenes/longvideo", from: self)
```

---

## **6. 示例与扩展**

通过以上步骤，您已经完成了 AliPlayerKit 的基础接入，并成功实现了视频播放。

如需查看更多示例，可参考以下目录：

- `PlayerKitUsages`：提供常见 API 的使用示例（日志系统、策略系统、预加载等）
- `PlayerKitScenes`：提供典型播放场景的解决方案（长视频、短视频、直播、列表播放）

如果您在接入或使用过程中遇到问题，可联系官方技术支持获取帮助。

---

如需查看各组件和接口的详细说明，请参考 **[API 参考](./ApiReference.md)**。
