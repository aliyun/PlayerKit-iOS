# Changelog

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
