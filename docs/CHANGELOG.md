# 更新日志

## [7.16.0] - 2026-08-26

### SDK 升级

- AliPlayerSDK_iOS: 7.15.0 → 7.16.0

### 新增

- **VID All-in-One 播放体验**：依托 AliPlayerKit 与阿里云视频点播 VOD 的协同能力，业务侧仅需传入视频 VID，即可自动获取播放资源，以及关联的视频标题、封面图和缩略图等媒资信息，减少播放地址获取、媒资信息传递及端侧参数配置，简化播放接入
- **Seek 缩略图**：拖动进度条时显示视频缩略图。使用 VID 播放时会自动获取缩略图，也支持手动传入缩略图数据
- **视频拆条**：将长视频按内容结构智能拆分为多个章节片段，通过进度条标记和章节面板帮助用户快速定位重点内容
- **AI 教育场景**：
  - 新增面向在线教育、知识课程等场景的 AI 教育视频解决方案，提供智能章节、内容摘要、知识点及图文解析能力，帮助用户快速定位重点内容，提升视频学习与内容理解效率
  - 新增 `SceneTypeAIVod` 场景类型，在标准 VOD 播放能力基础上，支持章节拆条、章节导航及 Seek 过程中的章节信息展示

### 文档

- 新增 [AI 教育场景](./scenes/AiEducation.md) 场景方案文档

---

## [7.15.0] - 2026-06-23

### SDK 升级

- AliPlayerSDK_iOS: 7.15.0（通过 CocoaPods 依赖管理）

### 新增

- **核心架构**：基于 MVC「3+1」设计的播放器 UI 组件库
  - `AliPlayerKit`：全局入口，负责框架初始化与配置管理
  - `AliPlayerView`：播放器 UI 容器（UIView 子类），管理插槽布局
  - `AliPlayerController`：播放控制器，管理播放状态与事件分发
  - `AliPlayerModel`：数据模型，封装视频源与播放配置
- **插槽系统**：12 种内置插槽，支持自定义插槽与元素级可见性控制
  - 核心插槽：PlayerSurface / GestureControl / Fullscreen
  - 控制栏：TopBar / BottomBar / SettingMenu / OptionPanel
  - 状态展示：Cover / CenterDisplay / PlayState / LogPanel / LandscapeHint
  - UI 组件：全新播放器 UI 设计，可直接使用
- **策略系统**：策略管理器 + 策略注册表 + 全局默认策略机制
  - 首帧耗时统计（FirstFrameStrategy）
  - 卡顿检测（StutterDetectStrategy）
  - 流量保护（TrafficProtectionStrategy）
  - 支持自定义策略扩展
- **播放器生命周期策略**：4 种内置策略适配不同业务场景
  - Default / ReusePool / IdScopedPool / Singleton
- **通知系统**：Notification Dispatcher + Delegate 协议模式
  - PlayerNotificationDispatcher：播放器核心通知
  - GestureNotificationDispatcher：手势交互通知
  - SlotActionNotificationDispatcher：插槽操作通知
- **日志系统**：统一日志中心 LogHub
  - 分级输出（Verbose / Debug / Info / Warn / Error）
  - LogObserver 监听器扩展
- **预加载系统**：全局预加载器，支持自定义实现
- **多视频源支持**：VidAuth（推荐）、VidSts、URL 三种接入方式
- **全屏模式**：独立 UIWindow 旋转方案，支持自定义过渡动画
- **国际化**：中英文内置，支持注入自定义 LocaleProvider
- **手势控制**：单击 / 双击 / 长按 / 水平拖动（进度）/ 垂直拖动（亮度 / 音量）
- **双层级自定义配置**：全局配置 `OnGlobalInitBlock` + 实例级配置 `onPlayerConfigBlock`
- **场景类型**：VOD / Live / VideoList / Restricted / Minimal 五种场景

### 文档

- 新增完整中文文档体系
  - [核心能力](./CoreFeatures.md)
  - [集成准备](./Integration.md)
  - [快速开始](./QuickStart.md)
  - [API 参考](./ApiReference.md)
  - [插槽系统](./advanced/SlotSystem.md)
  - [策略系统](./advanced/StrategySystem.md)
  - [通知系统](./advanced/NotificationSystem.md)
  - [自定义配置](./advanced/CustomConfig.md)
  - [播放器生命周期策略](./advanced/PlayerLifecycleStrategy.md)
  - [日志系统](./advanced/LogSystem.md)
  - [多语言](./advanced/Locale.md)
  - [场景类型](./advanced/SceneType.md)
  - [多视频源支持](./advanced/VideoSource.md)
