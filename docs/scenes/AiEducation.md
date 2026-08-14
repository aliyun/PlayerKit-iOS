# **AI 教育场景化解决方案**

---

## **1. 场景介绍**

**AI 教育场景**是阿里云基于 AliPlayerKit 与视频点播 VOD 打造的一体化 AI 视频解决方案，适用于**在线教育、课程培训和知识传播**等业务。

它以播放器为统一入口，由视频点播 VOD 提供视频内容与服务支撑，并融合 AI 内容理解能力，自动生成摘要、章节和知识点。用户可以快速了解内容脉络、定位重点片段并随时回看，让长视频从“从头看到尾”转变为“按需浏览、快速学习”。

无论是在线课程、职业培训、企业学习，还是知识付费和学术讲座，都可以借助该方案提升学习效率和观看体验，盘活存量视频内容，并降低播放器与 AI 功能的接入和建设成本。

![AiEducation](https://alivc-demo-cms.alicdn.com/versionProduct/resources/ai_education/ai-education-ui-preview.png)

---

## **2. 核心能力**

AI 教育场景围绕“**快速理解、精准定位和高效回看**”提供以下能力：

| 能力       | 描述 |
| ---------- | ---- |
| 智能章节   | 自动识别视频内容结构并生成章节，在进度条和章节列表中同步展示；点击章节即可跳转到对应片段 |
| 内容摘要   | 提供视频整体摘要和章节摘要，帮助用户快速了解主要内容与章节要点 |
| 知识点提炼 | 自动提取各章节的关键知识点，并以结构化方式展示，便于学习和复习 |
| 章节缩略图 | 为章节展示代表性画面，帮助用户快速识别和定位目标内容 |
| 横竖屏适配 | 根据屏幕方向自动调整交互布局：竖屏显示底部面板，横屏显示右侧面板 |

---

## **3. 前提条件**

开始集成前，请完成以下准备：

| 准备项     | 要求                                                         |
| ---------- | ------------------------------------------------------------ |
| 阿里云服务 | 已开通[视频点播 VOD](https://www.aliyun.com/product/vod) 和[智能媒体服务 IMS](https://www.aliyun.com/product/apsaravideo/ice) |
| 媒体资源   | 已准备测试视频，并完成 AI 内容分析                           |
| App Server | 已完成部署，可正常提供播放凭证和 AI 分析数据；可参考开源项目 [VodAppServer](https://github.com/MediaBox-Demos/VodAppServer) |

完成以上准备后，在 `AiContentConstants` 类中配置 App Server 地址和测试视频 ID，即可开始体验 AI 教育场景。

---

## **4. 快速接入**

### **4.1 通用集成**

AI 教育场景基于 PlayerKit 场景层构建。如尚未完成通用集成步骤，请先参阅：

- [集成准备](../Integration.md) — 场景层集成（引入 `PlayerKit` 和 `SceneAiEducation` 模块）
- [快速开始](../QuickStart.md) — 场景层接入（启动场景页面）

通用集成完成后，仅需以下额外配置即可体验 AI 教育场景：

### **4.2 配置 App Server 和测试视频**

打开 `AiContentConstants.m`，修改以下配置：

> 💡 可直接使用官方提供的 App Server 地址进行体验，但更建议部署自有服务后使用自己的地址。部署方式请参考 [VodAppServer](https://github.com/MediaBox-Demos/VodAppServer)。

```objc
NSString * const AiContentAppServerBaseURL = @"http://your-server-host:port";

NSString * const AiContentDefaultMediaId = @"your-media-id";
```

### **4.3 验证接入**

AI 教育场景对应信息：

| 项目 | 值 |
|------|------|
| ViewController | `SceneAiEducationViewController` |
| Schema | `playerkit://scenes/aieducation` |

页面启动后，视频将自动加载。播放器显示章节入口按钮，点击后可以查看章节列表和 AI 分析内容，说明接入成功。

---

## **5. 架构概览**

AI 教育场景由客户端、App Server、ICE / AI 工作流和 VOD 服务共同组成。

整体链路分为两个阶段：
- **生产阶段**：App Server 触发 AI 分析工作流，ICE 获取媒资并完成章节提取、摘要生成和知识点分析，随后将结构化结果回写至 VOD。
- **消费阶段**：客户端通过 App Server 获取播放凭证和 AI 分析结果，并由 PlayerKit 完成视频播放、章节跳转和 AI 内容展示。

### **5.1 全局业务流程**

全局业务流程描述 AI 分析结果从生产、存储到客户端消费的完整链路。

其中，VOD 负责媒资及 AI 分析结果的统一存储；ICE / AI 工作流负责内容理解和结构化分析；App Server 对服务端能力进行封装，并向客户端提供统一接口。

![ProductArchitecture](https://alivc-demo-cms.alicdn.com/versionProduct/resources/ai_education/ProductArchitecture.png)

### **5.2 客户端交互流程**

客户端交互流程描述用户进入 AI 教育播放页后，客户端、PlayerKit 与 App Server 之间的调用关系。

页面初始化时，客户端依次获取播放凭证和 AI 分析结果；数据加载完成后，用户可以通过章节内容面板查看章节、摘要和知识点，并跳转到对应的视频位置。

![CallSequence](https://alivc-demo-cms.alicdn.com/versionProduct/resources/ai_education/CallSequence.png)

当 AI 分析接口请求失败或结果为空时，客户端仍可使用播放凭证完成普通视频播放，但不展示章节和 AI 分析面板。

### **5.3 客户端分层架构**

客户端采用场景层、PlayerKit 能力层和播放器 SDK 分层设计。

场景层负责页面编排、数据加载和 AI 内容展示；PlayerKit 通过 Slot 机制提供播放器控制栏入口及面板扩展能力；底层播放器 SDK 负责媒资播放、进度控制和播放状态回调。

![LayeredArchitecture](https://alivc-demo-cms.alicdn.com/versionProduct/resources/ai_education/LayeredArchitecture-iOS.png)

**组件职责**：

| 组件 | 说明 |
| ---- | ---- |
| `SceneAiEducationViewController` | 场景入口，编排数据加载、播放器初始化和 UI 绑定 |
| `AiContentLoader` | 在后台线程依次请求播放凭证和 AI 分析结果，并在主线程回调处理结果 |
| `ChapterButtonSlot` | 在播放器控制栏中展示「章节」按钮，并触发章节内容面板展开 |
| `ChapterContentView` | 章节内容面板 UI，展示章节列表、视频摘要、章节摘要和知识点（双 Tab 设计） |
| `AiEducationMarkdownRenderer` | 将 AI 分析内容的 Markdown 文本渲染为富文本（基于 Down/cmark） |
| `AliPlayerController` | 提供视频加载、播放控制、Seek 和播放进度回调等基础能力 |

---

## **6. 服务端接口**

### **6.1 获取播放凭证**

```
GET {AppServerBaseURL}/appServer/GetVideoPlayAuth?videoId={vid}
```

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `videoId` | String | 是 | 视频 ID |

**响应示例**：

```json
{
  "code": 0,
  "success": true,
  "data": {
    "videoId": "your-video-id",
    "playAuth": "eyJ..."
  }
}
```

**响应字段说明**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | Integer | 业务返回码，0 表示成功 |
| `success` | Boolean | 请求是否成功 |
| `data.videoId` | String | 视频 ID |
| `data.playAuth` | String | Base64 编码的播放授权凭证（有时效性） |

### **6.2 获取 AI 分析内容**

```
GET {AppServerBaseURL}/GetMediaAiAnalysisByResultType?MediaId={vid}
```

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `MediaId` | String | 是 | 媒资 ID |
| `ResultType` | String | 否 | 结果类型：`Chapter`（章节）或 `Summary`（摘要）；不传则返回全部 |

**响应示例**：

```json
{
  "AiAnalysisResult": [
    {
      "ResultType": "Chapter",
      "Title": "视频标题",
      "Extra": "{\"Summary\":\"降级摘要文本\"}",
      "ChapterContentItems": [
        {
          "ChapterId": "1",
          "StartTime": 0,
          "EndTime": 120000,
          "ChapterTitle": "课程概述",
          "Summary": "本章介绍了课程整体内容...",
          "ThumbnailUrl": "https://example.com/thumb1.jpg",
          "KnowledgePoints": [
            {
              "PointId": "1",
              "Point": "核心概念",
              "PointDescription": "本章核心概念的详细描述..."
            }
          ]
        }
      ]
    },
    {
      "ResultType": "Summary",
      "Title": "视频标题",
      "SummaryContent": {
        "ParagraphSummary": "视频整体内容摘要..."
      },
      "Tags": ["教育", "技术"]
    }
  ]
}
```

> 💡 如需对接自有服务端，只需返回相同 JSON 结构即可。客户端不关心服务端的实现方式。

**章节字段说明**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `ChapterId` | String | 章节唯一标识 |
| `StartTime` | Integer | 章节起始时间（毫秒） |
| `EndTime` | Integer | 章节结束时间（毫秒） |
| `ChapterTitle` | String | 章节标题 |
| `Summary` | String | 章节摘要 |
| `ThumbnailUrl` | String | 章节缩略图 URL |
| `KnowledgePoints` | Array | 知识点列表 |
| `KnowledgePoints[].PointId` | String | 知识点 ID |
| `KnowledgePoints[].Point` | String | 知识点名称 |
| `KnowledgePoints[].PointDescription` | String | 知识点描述 |

**摘要字段说明**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `SummaryContent.ParagraphSummary` | String | 视频整体段落摘要 |
| `Tags` | Array\<String\> | 视频标签列表 |

---

## **7. 数据模型与映射**

### **7.1 三层映射**

| 服务端 JSON 字段 | 客户端 DTO | 业务模型 | 说明 |
|-----------------|-----------|---------|------|
| `ChapterId` | `ChapterContentItem.chapterId` | `ChapterInfo.chapterId` | 章节 ID |
| `StartTime` | `ChapterContentItem.startTime` | `ChapterInfo.startMs` | 毫秒 |
| `EndTime` | `ChapterContentItem.endTime` | `ChapterInfo.endMs` | 毫秒 |
| `ChapterTitle` | `ChapterContentItem.chapterTitle` | `ChapterInfo.title` | 章节标题 |
| `ThumbnailUrl` | `ChapterContentItem.thumbnailUrl` | `ChapterInfo.thumbnailUrl` | 缩略图 |
| `Summary` | `ChapterContentItem.summary` | `AiSegment.summary` | 章节摘要 |
| `KnowledgePoints[]` | `ChapterContentItem.knowledgePoints` | `AiSegment.markdown` | 拼接为 Markdown |
| `ParagraphSummary` | `SummaryContent.paragraphSummary` | `AiSummary.summaryText` | 视频全局摘要 |

### **7.2 聚合模型**

最终聚合为 `AiVideoContent`，包含：

| 字段 | 类型 | 说明 |
|------|------|------|
| `videoId` | `NSString *` | 视频 ID |
| `type` | `AiContentType` | 内容类型（决定面板渲染模式） |
| `summary` | `AiSummary *` | 视频级摘要（可为 nil） |
| `chapters` | `NSArray<ChapterInfo *> *` | 章节目录列表 |
| `segments` | `NSArray<AiSegment *> *` | 分段解析列表 |

`AiContentType` 枚举决定面板展示形态：

| 枚举值 | 含义 |
|--------|------|
| `AiContentTypeChaptersOnly` | 仅章节划分，无 AI 解析内容 |
| `AiContentTypeTextAnalysis` | 文字解析（含摘要或知识点文本） |
| `AiContentTypeGraphicAnalysis` | Markdown 图解解析 |

---

## **8. 自定义与扩展**

### **8.1 替换数据源**

当前 `SceneAiEducationViewController` 内部通过 `AiContentLoader` 加载数据。如需使用自己的数据源，可参考 ViewController 的实现流程，替换数据加载逻辑：

```objc
// 自定义加载示例
AiContentLoader *loader = [[AiContentLoader alloc] initWithBaseURL:@"http://your-server"];
[loader loadPlayAuthWithVideoId:@"your-vid"
                     completion:^(NSString * _Nullable playAuth) {
    // 获取到 playAuth 后继续加载 AI 内容...
}];
[loader loadWithMediaId:@"your-vid"
             completion:^(AiVideoContent * _Nullable content) {
    // 获取到 AiVideoContent 后配置播放器...
}];
```

### **8.2 自定义 UI**

- 替换章节内容面板样式：继承 `ChapterContentView` 自定义布局
- 扩展 Slot：通过 `SlotManager` 注册自定义插槽
- 详见 [插槽系统](../advanced/SlotSystem.md)

### **8.3 集成到已有 ViewController**

如果不想使用内置的 `SceneAiEducationViewController`，可参考其实现：

1. 初始化 `AliPlayerView` 和 `AliPlayerController`
2. 配置 `AliPlayerModel` 的 `sceneType` 为 `SceneTypeAIVod`
3. 加载播放凭证和 AI 数据
4. 设置 `AliPlayerModel` 的 `chapters`
5. 注册 `ChapterButtonSlot` 自定义插槽
6. 启动播放

```objc
// 1. 创建播放器组件
AliPlayerView *playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
[self.view addSubview:playerView];

AliPlayerController *playerController = [[AliPlayerController alloc] init];

// 2. 配置播放源（VidAuth 方式）
VideoSource *source = [VideoSource vidAuthSourceWithVid:mediaId playAuth:playAuth];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeAIVod;
model.chapters = aiContent.chapters;

// 3. 注册章节按钮自定义插槽
CustomSlotType *slotType = [CustomSlotType typeWithKey:@"chapter_button" order:85];
[playerView.slotManager registerCustomSlotType:slotType
                                      provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[ChapterButtonSlot alloc] initWithFrame:parentView.bounds];
}];

// 4. 配置并挂载（挂载后自动开始播放）
[playerController configure:model];
[playerView attach:playerController];
```

---

## **9. 集成 FAQ**

| 问题 | 解决方案 |
|------|---------|
| 播放凭证获取失败 | 检查 App Server 地址是否正确、网络是否连通、VideoId 是否有效 |
| AI 内容为空 | 确认视频已开通 AI 分析；客户端会降级为普通播放模式（无 AI 面板） |
| 如何使用自己的视频 ID | 修改 `AiContentConstants.m` 中的 `AiContentDefaultMediaId` |
| 横竖屏切换面板异常 | 面板通过 `FullscreenTransition.isInFullscreen` 判断当前状态，确认 ViewController 支持多方向 |
| 如何关闭某个 AI 能力 | 服务端接口中不返回对应 ResultType 即可 |
| SDK 版本兼容性 | 需要阿里云播放器 SDK ≥ 6.14.0 |
| Markdown 渲染异常 | 确认 Podfile 中已正确引入 Down 依赖（~> 0.11.0） |
| 章节按钮不显示 | 确认 `AiVideoContent.chapters` 非空，`ChapterButtonSlot` 依据章节数据可用性控制显隐 |
| 网络超时 | `AiContentLoader` 连接和读取超时均为 5 秒，可通过自定义 Loader 调整 |
