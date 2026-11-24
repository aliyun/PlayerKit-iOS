# Changelog

## [7.19.0] - 2026-11-24

### SDK Upgrade

- AliPlayerSDK_iOS: 7.16.0 → 7.19.0
- AliPlayerSDK_iOS_ARTC: 7.16.0 → 7.19.0
- RtsSDK: stays at 7.12.0 (the RTS component is not upgraded in this release)

### Added

- **Generalized chapters with lazy loading**
  - Added `AliPlayerController.chapters` as the single storage point for chapter data. It can be written at any time during the controller's lifecycle (synchronous or asynchronous loading); `configure:` seeds it from `AliPlayerModel.chapters`, and `destroy` clears it
  - Added `PlayerNotificationDelegate -playerDidUpdateChapters` and `PlayerNotificationDispatcher -dispatchDidUpdateChapters`: every write broadcasts, so progress-bar chapter markers, chapter chips and the chapter panel read the controller and show / update / hide automatically without re-configuring
  - Chapters are no longer limited to `SceneTypeAIVod`: they work in any scene except LIVE / MINIMAL when data is non-empty; in RESTRICTED scenes chapters are read-only and taps do not seek
- **Seek guard for restricted scenes**: `AliPlayerController.seekTo:` now checks the scene type; seek requests in LIVE / RESTRICTED scenes are intercepted at the command layer, logged, and no longer forwarded to the player. See [Scene Type](./advanced/SceneType-EN.md) for the capability scope of each scene
- **iPhone Duo / foldable adaptation**
  - Slots gained `avoidsOcclusion` (whether the root view also avoids occlusions such as the camera) and `contentLayoutBounds` (interactive content rect excluding safe areas, division regions and occlusions)
  - `SlotHost` gained the optional `- readableContentBoundsForSlot:` method so hosts can report the usable content rect in the slot's coordinate space
  - Built-in UI (top bar, bottom bar, settings / option panels, gestures, thumbnail preview) now lays out against the actual available space instead of branching on device posture
  - See [iPhone Duo Adaptation Best Practices](./advanced/iPhoneDuo-EN.md)
- **Panel layout APIs**: `BasePanelSlot` gained `panelLayoutBounds`, `panelContentHostView` and `panelFrameForSize:`, unifying the layout entry point, the slide-clipping container and transform-safe positioning

### Changed (integration notes)

- `SlotSafeAreaEdge` moved from `BaseSlot.h` to `SlotProtocol.h`: projects importing `BaseSlot.h` need no change; custom slots implementing `SlotProtocol` directly should import `SlotProtocol.h`
- `SlotHostLayout` no longer relies on `isKindOfClass:BaseSlot` and reads `safeAreaEdges` / `avoidsOcclusion` through optional `SlotProtocol` methods, so custom slots follow the same semantics
- `AliPlayerModel.chapters` only works as initial configuration at `configure:` time; for runtime updates write `AliPlayerController.chapters` instead
- `seekTo:` no longer takes effect in LIVE / RESTRICTED scenes (behavior change); specify the start position via `AliPlayerModel.startTime` during configuration. See [Scene Type](./advanced/SceneType-EN.md) for the capability scope of each scene
- The Example app migrated to the UIScene lifecycle (new `SceneDelegate`, `window` removed from `AppDelegate`); `project.yml` deployment target raised from 13.0 to 15.0, and the `Podfile` `post_install` raises the Pods build floor to iOS 15 while Podspec compatibility declarations remain unchanged

### Fixed

- **Fullscreen**: the fullscreen window is now created and reused per source scene and cross-scene migration is rejected; `setFullscreen:` uses a request generation guard so a transition may reject the request and only the current request syncs the actual state; the host keyWindow is restored when needed; before migrating back the placeholder frame is re-read and the original superview is re-laid out, fixing wrong behavior in multi-scene setups, rapid toggles and misplaced layout after exit
- **Bottom bar**: cancels slider touch tracking and tap recognition when bounds or fullscreen layout change, and ignores touch-up from cancelled drags, preventing seeks to stale coordinates; only effective drags commit the preview position
- **Gesture control**: ends pan / long-press and resets accumulated displacement on size change or slot detach, avoiding jumps based on stale coordinates
- **Chapter panel**: recomputes the highlighted chapter by current position after the list is replaced; validates the table's loaded row count before async scrolling, fixing out-of-bounds crashes after data changes; the panel is now hosted in `panelContentHostView` with unified layout
- **Option panel**: hosted in a scroll view constrained by the safe area, so options are no longer clipped in low-height regions
- **Settings menu**: the popup container uses autoresizing to follow window size, fixing misplacement after rotation or size changes
- **Seek thumbnail**: shrinks the image placeholder and bottom margin when height is limited, prioritizing time and chapter text
- **Top bar**: keeps compact padding in narrow fullscreen regions and re-evaluates it on size changes

### Documentation

- Added [iPhone Duo Adaptation Best Practices](./advanced/iPhoneDuo-EN.md) covering version and environment requirements, responsibility boundaries and verification
- [Scene Type](./advanced/SceneType-EN.md) gains a playback control scope matrix describing `seekTo:` interception, chapter display / seeking and start-position configuration per scene
- [AI Education Scene](./scenes/AiEducation-EN.md) now documents the chapter lazy-loading flow, integration samples and FAQ
- [Core Features](./CoreFeatures-EN.md) adds runtime chapter update notes with version thresholds and an iPhone Duo adaptation section
- [Slot System](./advanced/SlotSystem-EN.md) and [API Reference](./ApiReference-EN.md) document the `BasePanelSlot` panel layout APIs, `avoidsOcclusion` / `contentLayoutBounds`, `chapters` lazy-loading semantics and the `seekTo:` scene restriction
- [Notification System](./advanced/NotificationSystem-EN.md) documents the chapter notification `playerDidUpdateChapters` and the full convenience-dispatch list

---

## [7.16.0] - 2026-08-26

### SDK Upgrade

- AliPlayerSDK_iOS: 7.15.0 → 7.16.0

### Added

- **VID All-in-One Playback Experience**: Leveraging the collaboration between AliPlayerKit and Alibaba Cloud ApsaraVideo VOD, the business layer only needs to pass in a video VID to automatically obtain playback resources along with associated video title, cover image, and thumbnail information, reducing the need for playback URL retrieval, media info passing, and client-side parameter configuration
- **Seek Thumbnail**: Displays video thumbnails when dragging the progress bar. Thumbnails are automatically obtained when using VID playback, and manual thumbnail data input is also supported
- **Video Chapter Splitting**: Intelligently segments long videos into multiple chapter clips by content structure, with progress bar markers and a chapter panel to help users quickly locate key content
- **AI Education Scene**:
  - Added an AI-powered video education solution for online education and knowledge courses, providing intelligent chapters, content summaries, knowledge points, and graphic analysis capabilities to help users quickly locate key content and improve video learning efficiency
  - Added `SceneTypeAIVod` scene type that supports chapter segmentation, chapter navigation, and chapter information display during seek on top of standard VOD playback capabilities

### Documentation

- Added [AI Education Scene](./scenes/AiEducation-EN.md) documentation

---

## [7.15.0] - 2026-06-23

### SDK Upgrade

- AliPlayerSDK_iOS: 7.15.0 (managed via CocoaPods dependency)

### Added

- **Core Architecture**: Player UI component library based on MVC "3+1" design
  - `AliPlayerKit`: Global entry point, responsible for framework initialization and configuration management
  - `AliPlayerView`: Player UI container (UIView subclass), manages slot layout
  - `AliPlayerController`: Playback controller, manages playback state and event dispatching
  - `AliPlayerModel`: Data model, encapsulates video sources and playback configuration
- **Slot System**: 12 built-in slots with support for custom slots and element-level visibility control
  - Core Slots: PlayerSurface / GestureControl / Fullscreen
  - Control Bars: TopBar / BottomBar / SettingMenu / OptionPanel
  - Status Display: Cover / CenterDisplay / PlayState / LogPanel / LandscapeHint
  - UI Components: Brand-new player UI design, ready to use out of the box
- **Strategy System**: Strategy Manager + Strategy Registry + Global Default Strategy mechanism
  - First Frame Time Tracking (FirstFrameStrategy)
  - Stutter Detection (StutterDetectStrategy)
  - Traffic Protection (TrafficProtectionStrategy)
  - Support for custom strategy extensions
- **Player Lifecycle Strategy**: 4 built-in strategies for different business scenarios
  - Default / ReusePool / IdScopedPool / Singleton
- **Notification System**: Notification Dispatcher + Delegate protocol pattern
  - PlayerNotificationDispatcher: Core player notifications
  - GestureNotificationDispatcher: Gesture interaction notifications
  - SlotActionNotificationDispatcher: Slot action notifications
- **Log System**: Unified log center LogHub
  - Level-based output (Verbose / Debug / Info / Warn / Error)
  - LogObserver listener extension
- **Preload System**: Global preloader with support for custom implementations
- **Multiple Video Source Support**: Three access methods — VidAuth (recommended), VidSts, and URL
- **Fullscreen Mode**: Independent UIWindow rotation approach with support for custom transition animations
- **Internationalization**: Built-in Chinese and English, with support for injecting custom LocaleProvider
- **Gesture Control**: Single tap / Double tap / Long press / Horizontal swipe (progress) / Vertical swipe (brightness / volume)
- **Two-Level Custom Configuration**: Global configuration `OnGlobalInitBlock` + Instance-level configuration `onPlayerConfigBlock`
- **Scene Types**: Five scene types — VOD / Live / VideoList / Restricted / Minimal

### Documentation

- Added complete English documentation system
  - [Core Features](./CoreFeatures-EN.md)
  - [Integration Guide](./Integration-EN.md)
  - [Quick Start](./QuickStart-EN.md)
  - [API Reference](./ApiReference-EN.md)
  - [Slot System](./advanced/SlotSystem-EN.md)
  - [Strategy System](./advanced/StrategySystem-EN.md)
  - [Notification System](./advanced/NotificationSystem-EN.md)
  - [Custom Configuration](./advanced/CustomConfig-EN.md)
  - [Player Lifecycle Strategy](./advanced/PlayerLifecycleStrategy-EN.md)
  - [Log System](./advanced/LogSystem-EN.md)
  - [Internationalization](./advanced/Locale-EN.md)
  - [Scene Types](./advanced/SceneType-EN.md)
  - [Multiple Video Source Support](./advanced/VideoSource-EN.md)
