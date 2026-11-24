# 更新日志

## [7.19.0] - 2026-11-24

### SDK 升级

- AliPlayerSDK_iOS: 7.16.0 → 7.19.0
- AliPlayerSDK_iOS_ARTC: 7.16.0 → 7.19.0
- RtsSDK: 保持 7.12.0（低延时直播组件本次不升级）

### 新增

- **章节能力通用化与懒加载**
  - 新增 `AliPlayerController.chapters`，作为章节数据的唯一存储点。可在控制器生命周期内任意时刻写入（同步或异步加载均可），`configure:` 时以 `AliPlayerModel.chapters` 写入初始值，`destroy` 后清空
  - 新增 `PlayerNotificationDelegate -playerDidUpdateChapters` 与 `PlayerNotificationDispatcher -dispatchDidUpdateChapters`：章节写入即广播，进度条章节标记、章节 Chip、章节面板等 UI 收到通知后读取控制器数据自动显示 / 更新 / 隐藏，无需重新 `configure`
  - 章节由「仅 `SceneTypeAIVod` 可用」扩展为通用能力：非 LIVE / MINIMAL 场景且数据非空时生效；RESTRICTED 场景下仅只读展示，点击不发起跳转
- **受限场景 Seek 门禁**：`AliPlayerController.seekTo:` 增加场景判断，LIVE / RESTRICTED 场景的跳转请求在命令层被拦截并记录日志，不再透传至播放器。各场景的播放控制能力范围详见 [场景类型](./advanced/SceneType.md)
- **iPhone Duo / 折叠屏适配**
  - 插槽新增 `avoidsOcclusion`（是否额外避让摄像头等内部遮挡）与 `contentLayoutBounds`（避让安全区、折叠分区与遮挡后的交互内容区域）
  - `SlotHost` 新增可选方法 `- readableContentBoundsForSlot:`，宿主可返回插槽坐标系内的可用内容区域
  - 内置 UI（顶栏、底栏、设置 / 选项面板、手势、缩略图预览）按实际可用空间动态调整布局，不再按设备形态分支
  - 详见 [iPhone Duo 播放器适配最佳实践](./advanced/iPhoneDuo.md)
- **面板布局接口**：`BasePanelSlot` 新增 `panelLayoutBounds`、`panelContentHostView`、`panelFrameForSize:`，统一面板布局入口、滑动裁剪容器与 transform 安全的显示位置计算

### 变更（接入层需关注）

- `SlotSafeAreaEdge` 枚举定义从 `BaseSlot.h` 移至 `SlotProtocol.h`：通过 `BaseSlot.h` 引入的工程无需改动，直接实现 `SlotProtocol` 的插槽请改为引入 `SlotProtocol.h`
- `SlotHostLayout` 不再依赖 `isKindOfClass:BaseSlot` 判断，改为通过 `SlotProtocol` 可选方法读取 `safeAreaEdges` / `avoidsOcclusion`，自定义实现该协议的插槽遵循同一语义
- `AliPlayerModel.chapters` 仅在 `configure:` 时作为初始配置生效，运行期增删改请直接写 `AliPlayerController.chapters`
- `seekTo:` 在 LIVE / RESTRICTED 场景不再生效（行为变更），起播位置请在配置阶段通过 `AliPlayerModel.startTime` 指定；各场景能力范围见 [场景类型](./advanced/SceneType.md)
- Example 迁移至 UIScene 生命周期（新增 `SceneDelegate`，`AppDelegate` 移除 `window` 属性）；`project.yml` 部署版本 13.0 → 15.0，`Podfile` 的 `post_install` 将 Pods 构建下限提升至 iOS 15，Podspec 兼容声明不变

### 修复

- **全屏切换**：全屏窗口按来源窗口的 scene 归属创建与复用，拒绝跨 scene 迁移；`setFullscreen:` 增加请求代际校验，过渡实现可拒绝请求且仅由当前请求同步实际状态；退出时按需恢复宿主 keyWindow；迁回原父视图前重新读取占位视图 frame 并请求重新布局，修复多 scene、快速切换全屏与退出后位置错乱
- **底部控制栏**：尺寸或全屏布局切换时取消滑块触摸跟踪与点击识别，忽略已取消拖动的松手回调，避免按新坐标误跳转；松手只在有效拖动时提交预览位置
- **手势控制**：尺寸变化或插槽解绑时结束拖动 / 长按并重置累计位移，避免沿用旧坐标产生跳变
- **章节面板**：章节列表整体替换后按当前位置重算高亮；异步滚动前校验表格已加载行数，修复数据变化时的越界崩溃；面板改用 `panelContentHostView` 承载并统一布局
- **选项面板**：改用滚动容器承载并按安全区约束，低高度区域不再裁切选项
- **设置菜单**：弹层容器改为 autoresizing 跟随窗口尺寸，修复旋转 / 尺寸变化后的错位
- **Seek 缩略图**：高度不足时收缩图片占位与底距，优先保留时间与章节文本
- **顶栏**：窄全屏区域沿用紧凑边距，尺寸变化时重新评估间距

### 文档

- 新增 [iPhone Duo 播放器适配最佳实践](./advanced/iPhoneDuo.md)，说明版本与环境要求、职责边界及验证方法
- [场景类型](./advanced/SceneType.md) 新增播放控制能力范围矩阵，逐场景说明 `seekTo:` 拦截、章节展示 / 跳转与起播位置配置
- [AI 教育场景](./scenes/AiEducation.md) 补充章节懒加载流程、集成示例与常见问题
- [核心能力](./CoreFeatures.md) 补充章节运行期更新与版本门槛说明、iPhone Duo 适配章节
- [插槽系统](./advanced/SlotSystem.md) 与 [API 参考](./ApiReference.md) 补充 `BasePanelSlot` 面板布局接口、`avoidsOcclusion` / `contentLayoutBounds`、`chapters` 懒加载语义与 `seekTo:` 场景限制
- [通知系统](./advanced/NotificationSystem.md) 补充章节通知 `playerDidUpdateChapters` 及便捷分发方法清单

---

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
