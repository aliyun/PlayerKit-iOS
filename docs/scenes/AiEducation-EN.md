# **AI Education Scene Solution**

---

## **1. Scene Overview**

The **AI Education scene** is an integrated AI video solution built on AliPlayerKit and ApsaraVideo VOD, designed for **online education, professional training, and knowledge sharing**.

It uses the player as a unified entry point, with ApsaraVideo VOD providing video content and service support, combined with AI content understanding capabilities to automatically generate summaries, chapters, and knowledge points. Users can quickly grasp the content structure, locate key segments, and review at any time — transforming long videos from "watch start to finish" into "browse on demand, learn efficiently."

Whether for online courses, professional training, corporate learning, knowledge-based subscriptions, or academic lectures, this solution improves learning efficiency and viewing experience, revitalizes existing video content, and reduces the cost of integrating player and AI capabilities.

![AiEducation](https://alivc-demo-cms.alicdn.com/versionProduct/resources/ai_education/ai-education-ui-preview.png)

---

## **2. Core Capabilities**

The AI Education scene provides the following capabilities centered around "**quick understanding, precise navigation, and efficient review**":

| Capability | Description |
| ---------- | ----------- |
| Smart Chapters | Automatically identifies video content structure and generates chapters, displayed synchronously in the progress bar and chapter list; tap a chapter to jump to the corresponding segment |
| Content Summary | Provides video-level and chapter-level summaries, helping users quickly understand the main content and chapter key points |
| Knowledge Points | Automatically extracts key knowledge points from each chapter, displayed in a structured format for easy learning and review |
| Chapter Thumbnails | Displays representative frames for chapters, helping users quickly identify and locate target content |
| Orientation Adaptation | Automatically adjusts the interaction layout based on screen orientation: bottom panel in portrait, right-side panel in landscape |

---

## **3. Prerequisites**

Before integration, complete the following preparations:

| Item | Requirement |
| ---- | ----------- |
| Alibaba Cloud Services | [ApsaraVideo VOD](https://www.aliyun.com/product/vod) and [Intelligent Media Services (IMS)](https://www.aliyun.com/product/apsaravideo/ice) activated |
| Media Resources | Test videos prepared with AI content analysis completed |
| App Server | Deployed and able to provide play credentials and AI analysis data; refer to the open-source project [VodAppServer](https://github.com/MediaBox-Demos/VodAppServer) |

After completing the above, configure the App Server address and test video ID in `AiContentConstants` to start experiencing the AI Education scene.

---

## **4. Quick Start**

### **4.1 General Integration**

The AI Education scene is built on the PlayerKit scene layer. If you haven't completed the general integration steps, please refer to:

- [Integration Guide](../Integration-EN.md) — Scene layer integration (import `PlayerKit` and `SceneAiEducation` modules)
- [Quick Start](../QuickStart-EN.md) — Scene layer usage (launch scene pages)

After completing the general integration, only the following additional configuration is needed to experience the AI Education scene:

### **4.2 Configure App Server and Test Video**

Open `AiContentConstants.m` and modify the following configuration:

> 💡 You can use the official App Server address for a quick trial, but it is recommended to deploy your own server and use your own address. For deployment instructions, refer to [VodAppServer](https://github.com/MediaBox-Demos/VodAppServer).

```objc
NSString * const AiContentAppServerBaseURL = @"http://your-server-host:port";

NSString * const AiContentDefaultMediaId = @"your-media-id";
```

### **4.3 Verify Integration**

AI Education scene information:

| Item | Value |
|------|-------|
| ViewController | `SceneAiEducationViewController` |
| Schema | `playerkit://scenes/aieducation` |

After the page launches, the video will load automatically. The player displays a chapter entry button — tap it to view the chapter list and AI analysis content, confirming successful integration.

---

## **5. Architecture Overview**

The AI Education scene consists of the client, App Server, ICE/AI workflow, and VOD services.

The overall pipeline is divided into two phases:
- **Production Phase**: App Server triggers the AI analysis workflow; ICE fetches media assets and performs chapter extraction, summary generation, and knowledge point analysis, then writes structured results back to VOD.
- **Consumption Phase**: The client obtains play credentials and AI analysis results from App Server; PlayerKit handles video playback, chapter navigation, and AI content display.

### **5.1 Global Business Flow**

The global business flow describes the complete pipeline from AI analysis result production and storage to client consumption.

VOD is responsible for unified storage of media assets and AI analysis results; ICE/AI workflow handles content understanding and structured analysis; App Server encapsulates server-side capabilities and provides unified interfaces to the client.

![ProductArchitecture](https://alivc-demo-cms.alicdn.com/versionProduct/resources/ai_education/ProductArchitecture.png)

### **5.2 Client Interaction Flow**

The client interaction flow describes the calling relationships between the client, PlayerKit, and App Server after the user enters the AI Education playback page.

During page initialization, the client sequentially obtains play credentials and AI analysis results; after data loading completes, users can view chapters, summaries, and knowledge points through the chapter content panel and jump to corresponding video positions.

![CallSequence](https://alivc-demo-cms.alicdn.com/versionProduct/resources/ai_education/CallSequence.png)

When the AI analysis request fails or returns empty results, the client can still use play credentials for normal video playback without displaying the chapter and AI analysis panel.

### **5.3 Client Layered Architecture**

The client adopts a layered design with the Scene layer, PlayerKit capability layer, and Player SDK.

The Scene layer handles page orchestration, data loading, and AI content display; PlayerKit provides player control bar entry and panel extension capabilities through the Slot mechanism; the underlying Player SDK handles media playback, progress control, and playback state callbacks.

![LayeredArchitecture](https://alivc-demo-cms.alicdn.com/versionProduct/resources/ai_education/LayeredArchitecture-iOS-EN.png)

**Component Responsibilities**:

| Component | Description |
| --------- | ----------- |
| `SceneAiEducationViewController` | Scene entry point; orchestrates data loading, player initialization, and UI binding |
| `AiContentLoader` | Sequentially requests play credentials and AI analysis results on a background thread, with results dispatched back to the main thread |
| `ChapterButtonSlot` | Displays the "Chapter" button in the player control bar and triggers the chapter content panel |
| `ChapterContentView` | Chapter content panel UI; displays chapter list, video summary, chapter summaries, and knowledge points (dual-tab design) |
| `AiEducationMarkdownRenderer` | Renders AI analysis Markdown text as rich text (based on Down/cmark) |
| `AliPlayerController` | Provides video loading, playback control, seek, and playback progress callbacks |

---

## **6. Server-Side APIs**

### **6.1 Get Play Credentials**

```
GET {AppServerBaseURL}/appServer/GetVideoPlayAuth?videoId={vid}
```

**Request Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `videoId` | String | Yes | Video ID |

**Response Example**:

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

**Response Field Description**:

| Field | Type | Description |
|-------|------|-------------|
| `code` | Integer | Business return code, 0 indicates success |
| `success` | Boolean | Whether the request succeeded |
| `data.videoId` | String | Video ID |
| `data.playAuth` | String | Base64-encoded play authorization credential (time-limited) |

### **6.2 Get AI Analysis Content**

```
GET {AppServerBaseURL}/GetMediaAiAnalysisByResultType?MediaId={vid}
```

**Request Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `MediaId` | String | Yes | Media ID |
| `ResultType` | String | No | Result type: `Chapter` or `Summary`; returns all types if omitted |

**Response Example**:

```json
{
  "AiAnalysisResult": [
    {
      "ResultType": "Chapter",
      "Title": "Video Title",
      "Extra": "{\"Summary\":\"Fallback summary text\"}",
      "ChapterContentItems": [
        {
          "ChapterId": "1",
          "StartTime": 0,
          "EndTime": 120000,
          "ChapterTitle": "Course Overview",
          "Summary": "This chapter introduces the overall course content...",
          "ThumbnailUrl": "https://example.com/thumb1.jpg",
          "KnowledgePoints": [
            {
              "PointId": "1",
              "Point": "Core Concept",
              "PointDescription": "Detailed description of the core concept..."
            }
          ]
        }
      ]
    },
    {
      "ResultType": "Summary",
      "Title": "Video Title",
      "SummaryContent": {
        "ParagraphSummary": "Overall video content summary..."
      },
      "Tags": ["Education", "Technology"]
    }
  ]
}
```

> 💡 To integrate with your own server, simply return the same JSON structure. The client does not depend on the server-side implementation.

**Chapter Field Description**:

| Field | Type | Description |
|-------|------|-------------|
| `ChapterId` | String | Unique chapter identifier |
| `StartTime` | Integer | Chapter start time (milliseconds) |
| `EndTime` | Integer | Chapter end time (milliseconds) |
| `ChapterTitle` | String | Chapter title |
| `Summary` | String | Chapter summary |
| `ThumbnailUrl` | String | Chapter thumbnail URL |
| `KnowledgePoints` | Array | Knowledge point list |
| `KnowledgePoints[].PointId` | String | Knowledge point ID |
| `KnowledgePoints[].Point` | String | Knowledge point name |
| `KnowledgePoints[].PointDescription` | String | Knowledge point description |

**Summary Field Description**:

| Field | Type | Description |
|-------|------|-------------|
| `SummaryContent.ParagraphSummary` | String | Overall video paragraph summary |
| `Tags` | Array\<String\> | Video tag list |

---

## **7. Data Models and Mapping**

### **7.1 Three-Layer Mapping**

| Server JSON Field | Client DTO | Business Model | Description |
|-----------------|-----------|---------|------|
| `ChapterId` | `ChapterContentItem.chapterId` | `ChapterInfo.chapterId` | Chapter ID |
| `StartTime` | `ChapterContentItem.startTime` | `ChapterInfo.startMs` | Milliseconds |
| `EndTime` | `ChapterContentItem.endTime` | `ChapterInfo.endMs` | Milliseconds |
| `ChapterTitle` | `ChapterContentItem.chapterTitle` | `ChapterInfo.title` | Chapter title |
| `ThumbnailUrl` | `ChapterContentItem.thumbnailUrl` | `ChapterInfo.thumbnailUrl` | Thumbnail |
| `Summary` | `ChapterContentItem.summary` | `AiSegment.summary` | Chapter summary |
| `KnowledgePoints[]` | `ChapterContentItem.knowledgePoints` | `AiSegment.markdown` | Joined as Markdown |
| `ParagraphSummary` | `SummaryContent.paragraphSummary` | `AiSummary.summaryText` | Video-level summary |

### **7.2 Aggregated Model**

The final aggregation is `AiVideoContent`, containing:

| Field | Type | Description |
|-------|------|-------------|
| `videoId` | `NSString *` | Video ID |
| `type` | `AiContentType` | Content type (determines panel rendering mode) |
| `summary` | `AiSummary *` | Video-level summary (may be nil) |
| `chapters` | `NSArray<ChapterInfo *> *` | Chapter directory list |
| `segments` | `NSArray<AiSegment *> *` | Segment analysis list |

`AiContentType` enum determines the panel display style:

| Enum Value | Meaning |
|--------|------|
| `AiContentTypeChaptersOnly` | Chapters only, no AI analysis content |
| `AiContentTypeTextAnalysis` | Text analysis (with summary or knowledge point text) |
| `AiContentTypeGraphicAnalysis` | Markdown graphic analysis |

---

## **8. Customization and Extension**

### **8.1 Replacing the Data Source**

The built-in `SceneAiEducationViewController` loads data internally through `AiContentLoader`. To use your own data source, refer to the ViewController's implementation flow and replace the data loading logic:

```objc
// Custom loading example
AiContentLoader *loader = [[AiContentLoader alloc] initWithBaseURL:@"http://your-server"];
[loader loadPlayAuthWithVideoId:@"your-vid"
                     completion:^(NSString * _Nullable playAuth) {
    // After obtaining playAuth, continue loading AI content...
}];
[loader loadWithMediaId:@"your-vid"
             completion:^(AiVideoContent * _Nullable content) {
    // After obtaining AiVideoContent, configure the player...
}];
```

### **8.2 Customizing the UI**

- Replace chapter content panel style: Subclass `ChapterContentView` for custom layout
- Extend Slots: Register custom slots via `SlotManager`
- See [Slot System](../advanced/SlotSystem-EN.md) for details

### **8.3 Integrating into an Existing ViewController**

If you prefer not to use the built-in `SceneAiEducationViewController`, refer to its implementation:

1. Initialize `AliPlayerView` and `AliPlayerController`
2. Set `AliPlayerModel`'s `sceneType` to `SceneTypeAIVod`
3. Load play credentials and AI data
4. Set `AliPlayerModel`'s `chapters`
5. Register `ChapterButtonSlot` custom slot
6. Start playback

```objc
// 1. Create player components
AliPlayerView *playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
[self.view addSubview:playerView];

AliPlayerController *playerController = [[AliPlayerController alloc] init];

// 2. Configure video source (VidAuth method)
VideoSource *source = [VideoSource vidAuthSourceWithVid:mediaId playAuth:playAuth];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeAIVod;
model.chapters = aiContent.chapters;

// 3. Register chapter button custom slot
CustomSlotType *slotType = [CustomSlotType typeWithKey:@"chapter_button" order:85];
[playerView.slotManager registerCustomSlotType:slotType
                                      provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[ChapterButtonSlot alloc] initWithFrame:parentView.bounds];
}];

// 4. Configure and attach (playback starts automatically after attach)
[playerController configure:model];
[playerView attach:playerController];
```

---

## **9. Integration FAQ**

| Problem | Solution |
|---------|----------|
| Play credential fetch failed | Check that the App Server address is correct, network is connected, and VideoId is valid |
| AI content is empty | Confirm that AI analysis is enabled for the video; the client degrades to normal playback mode (no AI panel) |
| How to use my own video ID | Modify `AiContentDefaultMediaId` in `AiContentConstants.m` |
| Panel anomaly on orientation change | The panel uses `FullscreenTransition.isInFullscreen` to determine current state; ensure the ViewController supports multiple orientations |
| How to disable a specific AI capability | Simply don't return the corresponding ResultType from the server-side API |
| SDK version compatibility | Requires Alibaba Cloud Player SDK ≥ 6.14.0 |
| Markdown rendering issues | Confirm that the Down dependency (~> 0.11.0) is correctly included in the Podfile |
| Chapter button not showing | Confirm that `AiVideoContent.chapters` is non-empty; `ChapterButtonSlot` controls visibility based on chapter data availability |
| Network timeout | `AiContentLoader` has a 5-second timeout for both connection and reading; customize by creating your own Loader |
