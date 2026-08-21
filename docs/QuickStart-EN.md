> 📚 **Recommended Reading Path**
>
> [Core Features](./CoreFeatures-EN.md) → [Integration Guide](./Integration-EN.md) → **Quick Start** → [API Reference](./ApiReference-EN.md)

---

# **AliPlayerKit Quick Start**

Get video playback up and running in just a few steps!

**AliPlayerKit provides a minimalist API design** that helps you integrate video playback quickly with minimal code. There is no need to call low-level player APIs directly or build complex player UIs from scratch.

> **Note**: Before you begin, make sure you have completed the environment setup and dependency configuration described in [Integration Guide](./Integration-EN.md).

---

## **1. Integration Flow Overview**

The diagram below shows the basic flow for **Component Layer integration**:

![QuickStart](https://alivc-demo-cms.alicdn.com/versionProduct/installPackage/AliPlayerKit/iOS/QuickStart-EN.png)

---

## **2. Choose an Integration Approach**

AliPlayerKit adopts a **layered architecture design**. In addition to Component Layer integration, it also provides **Scene Layer integration**. You can choose flexibly based on your business requirements:

| Approach | Module | Description | Use Case |
|---------|------|---------|---------|
| **Approach 1: Component Layer** | `PlayerKit` | Uses the `PlayerKit` core module, providing configurable player UI components | Need custom player UI or flexible control over playback behavior |
| **Approach 2: Scene Layer** | `PlayerKitScenes` | Built on top of the Component Layer, provides complete business scenario solutions | Quickly implement standard playback scenarios such as long video, short video, or live streaming |

> **Note**: The Scene Layer depends on the Component Layer. If you choose Scene Layer integration, you must complete Component Layer integration first.

---

## **3. Global Initialization**

Call `[AliPlayerKit setup]` in `AppDelegate`'s `application:didFinishLaunchingWithOptions:` to perform global initialization. This only needs to be called once during the application lifecycle to initialize the player engine and global configuration.

* **Objective-C**:

```objc
#import <PlayerKit/AliPlayerKit.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize AliPlayerKit global settings
    [AliPlayerKit setup];
    return YES;
}

@end
```

* **Swift**:

```swift
import AliPlayerKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize AliPlayerKit global settings
        AliPlayerKit.setup()
        return true
    }
}
```

> **Note**: `AliPlayerKit` also provides other global configuration interfaces such as logging system and preload strategy. See [API Reference](./ApiReference-EN.md) for details.

---

## **4. Approach 1: Component Layer Integration**

The Component Layer (`PlayerKit` module) provides out-of-the-box, configurable player UI components. Implement playback functionality on each page that requires video playback by following these steps.

> **Prerequisites**: Before integrating the Component Layer, please complete the Component Layer integration steps in [Integration Guide](./Integration-EN.md) and complete the Global Initialization.

### **Step 1: Add the Player View**

Create an `AliPlayerView` programmatically in your ViewController and add it to the view hierarchy:

* **Objective-C**:

```objc
AliPlayerView *playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
[self.view addSubview:playerView];
```

* **Swift**:

```swift
let playerView = AliPlayerView(frame: view.bounds)
view.addSubview(playerView)
```

`AliPlayerView` can be placed anywhere in your view hierarchy, and the frame can be set according to your actual needs. If fullscreen switching is needed, the component internally handles view hierarchy adjustments automatically.

### **Step 2: Attach the Controller and Start Playback**

> **Important**: `configure:` must be called before `attach:`, otherwise the view binding cannot obtain the playback configuration.

Create the controller, configure data, and attach the view in your ViewController:

1. Create an `AliPlayerController`
2. Configure `AliPlayerModel` (VidAuth is recommended; URL source can be used for quick testing)
3. Call `configure:` + `attach:`
4. Call `destroy` in `dealloc` to release resources

* **Objective-C**:

```objc
#import <PlayerKit/AliPlayerKit.h>

@interface VideoPlayerViewController ()
@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *controller;
@end

@implementation VideoPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 1. Create the player view
    self.playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.playerView];

    // 2. Create the playback controller
    self.controller = [[AliPlayerController alloc] init];

    // 3. Configure playback data (VidAuth is recommended)
    VideoSource *source = [VideoSource vidAuthSourceWithVid:@"Your Video ID"
                                                  playAuth:@"Your Play Auth Token"];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    model.videoTitle = @"Sample Video";

    // 4. Configure the source and attach the view (playback starts automatically after attachment)
    [self.controller configure:model];
    [self.playerView attach:self.controller];
}

- (void)dealloc {
    // Destroy the player and release resources
    [self.controller destroy];
}

@end
```

* **Swift**:

```swift
import AliPlayerKit

class VideoPlayerViewController: UIViewController {

    private let playerView = AliPlayerView(frame: .zero)
    private let controller = AliPlayerController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Create the player view
        playerView.frame = view.bounds
        view.addSubview(playerView)

        // 2. Configure playback data (VidAuth is recommended)
        let source = VideoSource.vidAuthSource(withVid: "Your Video ID", playAuth: "Your Play Auth Token")
        let model = AliPlayerModel(videoSource: source)
        model.videoTitle = "Sample Video"

        // 3. Configure the source and attach the view (playback starts automatically after attachment)
        controller.configure(model)
        playerView.attach(controller)
    }

    deinit {
        // Destroy the player and release resources
        controller.destroy()
    }
}
```

> **Tip**: If you cannot obtain a **Video ID** and **Play Auth Token** yet, you can use a URL source for quick testing:
>
> ```objc
> VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
> ```
>
> The scene module includes `SceneConstants` sample data that you can also reference directly.

> **Notes**:
>
> - `AliPlayerModel.autoPlay` defaults to `YES`, so playback starts automatically after configuration — no need to manually call `play`
> - `AliPlayerController.autoLifecycleManagement` defaults to `YES`, automatically handling play/pause during app foreground/background transitions. However, page-level navigation (e.g., push/pop) requires manually calling `onResume` / `onPause` in `viewDidAppear` / `viewWillDisappear`
> - `configure:` internally obtains the player instance through the lifecycle strategy, sets the data source, and prepares for playback
> - `destroy` must be called in `dealloc` to destroy the controller; otherwise it will cause memory leaks

### **Step 3 (Optional): Handle the Back Button**

If you need to customize the player's back button behavior, use the `onBackPressed` callback:

* **Objective-C**:

```objc
__weak typeof(self) weakSelf = self;
self.playerView.onBackPressed = ^{
    [weakSelf.navigationController popViewControllerAnimated:YES];
};
```

* **Swift**:

```swift
playerView.onBackPressed = { [weak self] in
    self?.navigationController?.popViewController(animated: true)
}
```

> **Note**: When the player is in fullscreen mode, the back action automatically exits fullscreen without triggering this callback. This callback is only invoked in non-fullscreen mode. If this callback is not set, the player will attempt default navigation behavior (pop / dismiss) through the responder chain.
>
> **Cross-platform difference**: On Android, interception is done via `Activity.onBackPressed()`, calling `playerView.onBackPressed()` and checking the return value to determine if the event was consumed; on iOS, external notification is done via a Block callback.

### **Step 4 (Optional): Custom Configuration**

To inject custom SDK configuration (such as buffer strategy, Referer, etc.) before the player prepares, use `onPlayerConfigBlock`:

* **Objective-C**:

```objc
model.onPlayerConfigBlock = ^(id<MediaPlayer> player) {
    // Executed before prepare — access the underlying player instance for custom configuration
    // For example: set buffer configuration, Referer, setOption, etc.
};
```

* **Swift**:

```swift
model.onPlayerConfigBlock = { player in
    // Executed before prepare — access the underlying player instance for custom configuration
}
```

> **Note**: Global configuration is set via `[AliPlayerKit setOnGlobalInitBlock:]` before `setup` (executed only once); instance configuration is triggered via `model.onPlayerConfigBlock` on each `configure:` call. See [Custom Configuration](./advanced/CustomConfig-EN.md) for details.

---

## **5. Approach 2: Scene Layer Integration**

The Scene Layer provides complete playback solutions for specific business scenarios such as long video, short video, and live streaming. Built on top of the Component Layer, it works out of the box after integration with no additional development required.

> **Prerequisites**: Before integrating the Scene Layer, please complete the Scene Layer integration steps in [Integration Guide](./Integration-EN.md) and complete the Global Initialization.

### **Step 1: Choose a Scene Module**

Scene modules are located in the `PlayerKitScenes` directory and imported via CocoaPods subspecs. Currently available:

| Scene Module | Pod Subspec | Description |
|---------|-------------|------|
| `SceneCommon` | `PlayerKitScenes/SceneCommon` | Common scene module (required, base dependency for other scene modules) |
| `SceneLongVideo` | `PlayerKitScenes/SceneLongVideo` | **Long Video Scene**: Complete solution for medium/long video playback |
| `SceneShortVideo` | `PlayerKitScenes/SceneShortVideo` | **Short Video Scene**: Complete solution for short video swipe playback |
| `SceneLive` | `PlayerKitScenes/SceneLive` | **Live Streaming Scene**: Complete solution for live stream playback. **Additionally depends on the `DemoSettings` module**; must be copied together when integrating standalone |
| `ScenePlaylist` | `PlayerKitScenes/ScenePlaylist` | **Playlist Scene**: Complete solution for video list playback |
| `SceneAiEducation` | `PlayerKitScenes/SceneAiEducation` | **AI Education Scene**: AI Education scene with chapter navigation, AI content analysis panel, and Markdown rendering (requires GMarkdown ~> 0.1.1, iOS 13.0+) |

> **Cross-platform alignment**: Scene modules are aligned with the Android counterparts (`scene-longvideo` / `scene-shortvideo` / `scene-live` / `scene-playlist`). Business capabilities and UI interactions are consistent across platforms.

### **Step 2: Launch a Scene Page**

After scene module integration is complete, you can launch a scene page in two ways:

#### **Method 1: Direct Instantiation (Recommended)**

Each scene module provides a standalone ViewController that can be instantiated directly and navigated to via `UINavigationController`:

* **Objective-C**:

```objc
#import "SceneLongVideoViewController.h"

// Navigate to the long video scene
SceneLongVideoViewController *vc = [[SceneLongVideoViewController alloc] init];
[self.navigationController pushViewController:vc animated:YES];
```

* **Swift**:

```swift
// Navigate to the long video scene
let vc = SceneLongVideoViewController()
navigationController?.pushViewController(vc, animated: true)
```

ViewControllers for each scene:

| Scene | ViewController |
|------|----------------|
| Long Video | `SceneLongVideoViewController` |
| Short Video | `SceneShortVideoViewController` |
| Live Streaming | `SceneLiveViewController` |
| Playlist | `ScenePlaylistViewController` |
| AI Education | `SceneAiEducationViewController` |

#### **Method 2: Schema Routing**

Scene modules support launching playback scenes via Schema protocol. The Demo project provides an `AppSchemaRouter` utility class that can automatically discover and navigate to the corresponding scene via Schema URL:

* **Objective-C**:

```objc
#import "AppSchemaRouter.h"

// Navigate to the long video scene via Schema
[AppSchemaRouter navigateToSchema:@"playerkit://scenes/longvideo" fromViewController:self];
```

* **Swift**:

```swift
// Navigate to the long video scene via Schema
AppSchemaRouter.navigate(toSchema: "playerkit://scenes/longvideo", from: self)
```

Schema addresses for each scene:

| Scene | Schema |
|------|--------|
| Long Video | `playerkit://scenes/longvideo` |
| Short Video | `playerkit://scenes/shortvideo` |
| Live Streaming | `playerkit://scenes/live` |
| Playlist | `playerkit://scenes/playlist` |
| AI Education | `playerkit://scenes/aieducation` |

> **Note**: `AppSchemaRouter` is a routing utility provided in the Demo project (`App` module), implementing automatic module discovery based on the `AppModuleProtocol` protocol. Scene modules register their Schema, title, and priority through `*Module` classes (e.g., `SceneLongVideoModule`). To use Schema routing in your app, you can reference this implementation or integrate with your own routing framework.
>
> **Cross-platform comparison**: Android uses `Intent` + `AndroidManifest.xml` `<intent-filter>` for Schema routing; iOS uses `AppModuleProtocol` + runtime reflection for automatic module discovery. The Schema format remains consistent across platforms.

---

## **6. Scene Implementation Reference**

Scene module source code serves as a best-practice reference for Component Layer integration. Below are the core implementation patterns for each scene:

### **6.1 Long Video Scene**

`SceneLongVideoViewController` demonstrates the standard Component Layer integration flow:

```objc
// Initialize AliPlayerKit playback components
- (void)setupPlayerKit {
    // 1. Create the player component view
    self.playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.playerView];

    // Optional: Set back button callback
    __weak typeof(self) weakSelf = self;
    self.playerView.onBackPressed = ^{
        [weakSelf.navigationController popViewControllerAnimated:YES];
    };

    // 2. Create the player component controller
    self.playerController = [[AliPlayerController alloc] init];

    // 3. Configure player component data
    VideoSource *source = [VideoSource vidAuthSourceWithVid:@"Video ID" playAuth:@"Play Auth Token"];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    model.videoTitle = @"Long Video";

    // 4. Configure the source and attach controller to view (playback starts automatically after attachment)
    [self.playerController configure:model];
    [self.playerView attach:self.playerController];
}
```

### **6.2 Live Streaming Scene**

`SceneLiveViewController` demonstrates URL source + live scene type usage:

```objc
VideoSource *source = [VideoSource urlSourceWithUrl:liveUrl];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.videoTitle = @"Live Stream";
model.sceneType = SceneTypeLive;  // Set to live streaming scene type

[self.playerController configure:model];
[self.playerView attach:self.playerController];
```

> **Note**: `SceneType` affects slot visibility configuration and UI behavior. In live streaming mode, VOD elements like the progress bar are automatically hidden. See [Scene Type](./advanced/SceneType-EN.md) for details.

### **6.3 Playlist Scene**

`ScenePlaylistViewController` demonstrates the advanced usage of `SingletonLifecycleStrategy` + `PlayerNotificationDelegate` for auto-advancement:

```objc
// Use singleton lifecycle strategy to reuse player instances
self.lifecycleStrategy = [SingletonLifecycleStrategy sharedInstance];
self.currentController = [[AliPlayerController alloc] initWithLifecycleStrategy:self.lifecycleStrategy];

// Register playback completion notification for triggering auto-play next
[self.currentController addNotificationDelegate:self];

// PlayerNotificationDelegate callback
- (void)playerDidCompletion {
    [self playNextVideo];  // Current video completed, auto-play next
}
```

> **Note**: The playlist scene specifies a lifecycle strategy via `initWithLifecycleStrategy:` to reuse player instances for better performance. See [Player Lifecycle Strategy](./advanced/PlayerLifecycleStrategy-EN.md) for details.

---

## **7. Examples & Extensions**

With the steps above, you have completed the basic AliPlayerKit integration and successfully implemented video playback.

For more examples, refer to the following directories:

| Module | Description |
|------|------|
| `PlayerKitUsages` | Provides usage examples for common APIs (logging system, slot system, notification system, strategy system, lifecycle strategy, preloading, video sources, localization) |
| `PlayerKitScenes` | Provides solutions for typical playback scenarios (long video, short video, live streaming, playlist) |

Schema routing format for usage examples is `playerkit://usages/<module-name>`, accessible directly from the Demo project's home page.

If you encounter any issues during integration or usage, please contact official technical support for assistance.

---

For detailed documentation on each component and interface, see **[API Reference](./ApiReference-EN.md)**.
