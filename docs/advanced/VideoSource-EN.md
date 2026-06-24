# **Multiple Video Source Support**

**Video Source** is the data foundation module of AliPlayerKit. It defines multiple video source types, supporting VidAuth, VidSts, and URL playback methods, providing unified video resource configuration and management.

---

## **1. Concept Overview**

### **1.1 What is a Video Source?**

**Video Source** is the data origin for player video playback, defining how video resources are obtained and the authorization mechanism.

AliPlayerKit encapsulates three video source types through the `VideoSource` class:

| Video Source Type | Authorization Method | Security Level | Use Case |
|-----------|---------|---------|---------|
| VidAuth | VID + Play Auth | Medium | **Recommended**, most production environments |
| VidSts | VID + STS Temporary Credentials | High | High-security scenarios |
| URL | Direct URL Address | Low | Public resources, testing and demos |

### **1.2 How to Choose a Video Source Type?**

| Requirement | Recommended Type | Description |
|-----|---------|------|
| Authorization needed with moderate security | VidAuth (Recommended) | Simple authorization mechanism, easy to integrate |
| High security with temporary access credentials | VidSts | Temporary credentials, supports fine-grained access control |
| Public video resources | URL | No authorization needed, simple to use |

### **1.3 Design Characteristics**

- **Immutable Objects**: All properties of `VideoSource` are `readonly` and cannot be modified after creation
- **Factory Method Creation**: `init` and `new` are marked as `NS_UNAVAILABLE`; instances must be created via factory class methods
- **Parameter Validation**: Factory methods check required parameters for nil and empty strings, returning `nil` on validation failure
- **Validity Verification**: Provides an `isValid` method for secondary validation before configuring the player
- **Unique Identifier**: The `uniqueId` property is automatically derived based on type (VidAuth/VidSts returns `vid`, URL returns `url`), used for instance reuse in player lifecycle strategies

---

## **2. Video Source Types in Detail**

### **2.1 VidAuth Mode (Recommended)**

Authorizes playback through a Video ID (VID) and Play Auth credential. The authorization mechanism is simple and easy to integrate, **recommended for most business scenarios**.

**Use Cases**:

- Video resources requiring authorization verification
- Video playback in most production environments
- Scenarios requiring a simple yet secure authorization method

**Parameter Description**:

| Parameter | Type | Required | Description |
|------|------|:----:|------|
| `vid` | `NSString *` | Yes | Video unique identifier (cannot be nil or empty string) |
| `playAuth` | `NSString *` | Yes | Play authorization token (should be obtained from the server, cannot be nil or empty string) |

**Usage Example**:

```objc
VideoSource *videoSource =
    [VideoSource vidAuthSourceWithVid:@"your_video_id"
                             playAuth:@"your_play_auth"];

AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
model.sceneType = SceneTypeVOD;
model.autoPlay = YES;
```

### **2.2 VidSts Mode**

Plays video through a Video ID (VID) and Alibaba Cloud STS (Security Token Service) temporary credentials, providing higher security and access control.

**Use Cases**:

- Scenarios requiring temporary access credentials
- Video resources with high security requirements
- Scenarios requiring fine-grained access control

**Parameter Description**:

| Parameter | Type | Required | Description |
|------|------|:----:|------|
| `vid` | `NSString *` | Yes | Video unique identifier (cannot be nil or empty string) |
| `accessKeyId` | `NSString *` | Yes | STS Access Key ID (cannot be nil or empty string) |
| `accessKeySecret` | `NSString *` | Yes | STS Access Key Secret (cannot be nil or empty string) |
| `securityToken` | `NSString *` | Yes | STS Security Token (cannot be nil or empty string) |
| `region` | `NSString *` | No | Region information (e.g., `@"cn-shanghai"`), uses default region when `nil` |

**Usage Example**:

```objc
VideoSource *videoSource =
    [VideoSource vidStsSourceWithVid:@"your_video_id"
                         accessKeyId:@"your_access_key_id"
                     accessKeySecret:@"your_access_key_secret"
                       securityToken:@"your_security_token"
                              region:@"cn-shanghai"];

AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
model.sceneType = SceneTypeVOD;
model.autoPlay = YES;
```

### **2.3 URL Mode**

Plays video by directly providing a video URL, suitable for publicly accessible video resources.

**Use Cases**:

- Public video resources that do not require authorization
- Testing and demo scenarios
- Live stream playback

**Parameter Description**:

| Parameter | Type | Required | Description |
|------|------|:----:|------|
| `url` | `NSString *` | Yes | Video URL address (cannot be nil or empty string) |

**Usage Example**:

```objc
VideoSource *videoSource =
    [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];

AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
```

### **2.4 Comparison of Three Video Source Types**

| Feature | VidAuth | VidSts | URL |
|-----|---------|--------|-----|
| Authorization Method | Play Auth credential | Temporary access credentials | No authorization needed |
| Required Parameters | vid, playAuth | vid, accessKeyId, accessKeySecret, securityToken | url |
| Optional Parameters | — | region | — |
| Security Level | Medium | High | Low |
| Use Cases | Most business scenarios | High-security scenarios | Public resources / Live streams |
| Recommendation | **Recommended** | Special requirements | Testing / Demos |
| `uniqueId` Source | `vid` | `vid` | `url` |

---

## **3. Usage**

### **3.1 Basic Usage — Creating with Factory Methods**

Create video sources through `VideoSource` factory class methods:

```objc
// VidAuth (Recommended)
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

> **Note**: Factory methods return `nil` when required parameters are `nil` or empty strings. Callers should check the return value.

### **3.2 Basic Usage — Validating Validity**

Call `isValid` to validate the video source configuration before configuring the player:

```objc
VideoSource *source =
    [VideoSource vidAuthSourceWithVid:vid playAuth:playAuth];

if (source && [source isValid]) {
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    [self.controller configure:model];
} else {
    NSLog(@"Invalid video source configuration: %@", source);
}
```

**`isValid` Validation Rules**:

| Type | Validation Condition |
|------|---------|
| VidAuth | `vid.length > 0 && playAuth.length > 0` |
| VidSts | `vid.length > 0 && accessKeyId.length > 0 && accessKeySecret.length > 0 && securityToken.length > 0` |
| URL | `url.length > 0` |

> **Note**: The `region` parameter for VidSts is optional and is not included in the `isValid` validation.

### **3.3 Basic Usage — Complete Playback Flow**

```objc
@interface PlayerViewController ()
@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *playerController;
@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 1. Create video source (recommend obtaining playAuth from server)
    VideoSource *videoSource =
        [VideoSource vidAuthSourceWithVid:@"your_video_id"
                                 playAuth:@"server_returned_play_auth"];

    // 2. Validate video source
    if (!videoSource || ![videoSource isValid]) {
        NSLog(@"Invalid video source configuration: %@", videoSource);
        return;
    }

    // 3. Create playback data
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
    model.sceneType = SceneTypeVOD;
    model.coverUrl = @"https://example.com/cover.jpg";
    model.autoPlay = YES;

    // 4. Create controller and configure
    self.playerController = [[AliPlayerController alloc] init];
    [self.playerController configure:model];

    // 5. Bindto player view
    [self.playerView attach:self.playerController];
}

- (void)dealloc {
    [_playerView detach];
    [_playerController destroy];
}

@end
```

### **3.4 Advanced Usage — Switching Video Sources**

To switch between different video sources on the same controller, simply call `configure:` again with a new `AliPlayerModel`:

```objc
- (void)switchToNewVideo:(NSString *)newVid playAuth:(NSString *)newPlayAuth {
    VideoSource *newSource =
        [VideoSource vidAuthSourceWithVid:newVid playAuth:newPlayAuth];

    AliPlayerModel *newModel = [[AliPlayerModel alloc] initWithVideoSource:newSource];
    newModel.videoTitle = @"New Video";

    // Reconfigure on the same controller
    [self.playerController configure:newModel];
}
```

---

## **4. Best Practices**

### **4.1 Security Recommendations**

| Recommendation | Description |
|------|------|
| Do not hardcode sensitive information | Avoid hardcoding `playAuth`, `accessKeySecret`, etc. in client code |
| Obtain authorization from server | Retrieve authorization information through server-side APIs, then pass to the client |
| Refresh credentials promptly | VidSts tokens have expiration times; refresh them promptly |
| Use HTTPS | Ensure secure data transmission |

```objc
// Recommended: Obtain authorization information from server
- (void)playVideoWithId:(NSString *)videoId {
    [self.apiService fetchPlayAuthForVideoId:videoId
                                  completion:^(NSString *playAuth, NSError *error) {
        if (error) {
            NSLog(@"Failed to obtain play auth: %@", error);
            return;
        }

        VideoSource *source =
            [VideoSource vidAuthSourceWithVid:videoId playAuth:playAuth];
        AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
        [self.playerController configure:model];
    }];
}
```

### **4.2 Common Mistakes**

#### **Mistake 1: Not Checking Factory Method Return Value**

```objc
// ✗ Wrong: Factory method returns nil when parameters are invalid, unchecked
VideoSource *source = [VideoSource vidAuthSourceWithVid:vid playAuth:playAuth];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source]; // source may be nil

// ✓ Correct: Check return value
VideoSource *source = [VideoSource vidAuthSourceWithVid:vid playAuth:playAuth];
if (source && [source isValid]) {
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    [self.playerController configure:model];
}
```

#### **Mistake 2: Hardcoding Sensitive Information in Client**

```objc
// ✗ Wrong: Hardcoded playAuth (security risk)
VideoSource *source =
    [VideoSource vidAuthSourceWithVid:@"video_id"
                             playAuth:@"hardcoded_play_auth_value"];

// ✓ Correct: Obtain from server
NSString *playAuth = [self fetchPlayAuthFromServer:videoId];
VideoSource *source =
    [VideoSource vidAuthSourceWithVid:videoId playAuth:playAuth];
```

#### **Mistake 3: Not Handling Expired STS Token**

```objc
// ✗ Wrong: Using expired token
VideoSource *source = [VideoSource vidStsSourceWithVid:vid
                                           accessKeyId:accessKeyId
                                       accessKeySecret:accessKeySecret
                                         securityToken:expiredToken
                                                region:region];

// ✓ Correct: Check and refresh token
if ([self isTokenExpired:securityToken]) {
    securityToken = [self refreshSecurityToken];
}
VideoSource *source = [VideoSource vidStsSourceWithVid:vid
                                           accessKeyId:accessKeyId
                                       accessKeySecret:accessKeySecret
                                         securityToken:securityToken
                                                region:region];
```

#### **Mistake 4: Using init to Create Instance**

```objc
// ✗ Compilation error: init and new are marked as NS_UNAVAILABLE
VideoSource *source = [[VideoSource alloc] init]; // Compilation error

// ✓ Correct: Use factory class methods
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
```

---

## **5. API Quick Reference**

### **5.1 Video Source Type Enum (VideoSourceType)**

| Enum Value | Numeric Value | Description |
|--------|------|------|
| `VideoSourceTypeVidAuth` | 0 | VID + PlayAuth credential playback source (Recommended) |
| `VideoSourceTypeVidSts` | 1 | VID + STS temporary credential playback source |
| `VideoSourceTypeUrl` | 2 | URL direct playback source |

### **5.2 VideoSource Properties**

| Property | Type | Description |
|------|------|------|
| `sourceType` | `VideoSourceType` | Video source type (`readonly`) |
| `uniqueId` | `NSString *` | Unique identifier; VidAuth/VidSts returns `vid`, URL returns `url` (`readonly`, nullable) |
| `url` | `NSString *` | Video URL address, only valid for URL type (`readonly`, nullable) |
| `vid` | `NSString *` | Video unique identifier, valid for VidAuth and VidSts types (`readonly`, nullable) |
| `playAuth` | `NSString *` | Play authorization token, only valid for VidAuth type (`readonly`, nullable) |
| `accessKeyId` | `NSString *` | STS Access Key ID, only valid for VidSts type (`readonly`, nullable) |
| `accessKeySecret` | `NSString *` | STS Access Key Secret, only valid for VidSts type (`readonly`, nullable) |
| `securityToken` | `NSString *` | STS Security Token, only valid for VidSts type (`readonly`, nullable) |
| `region` | `NSString *` | Region information, only valid for VidSts type (`readonly`, nullable) |

### **5.3 VideoSource Methods**

| Method | Return Type | Description |
|------|---------|------|
| `+vidAuthSourceWithVid:playAuth:` | `instancetype` | Creates a VidAuth source (returns `nil` when parameters are invalid) |
| `+vidStsSourceWithVid:accessKeyId:accessKeySecret:securityToken:region:` | `instancetype` | Creates a VidSts source (returns `nil` when parameters are invalid; `region` can be `nil`) |
| `+urlSourceWithUrl:` | `instancetype` | Creates a URL source (returns `nil` when parameters are invalid) |
| `-isValid` | `BOOL` | Validates whether the current video source configuration is valid |

> **Note**: `+new` and `-init` are marked as `NS_UNAVAILABLE`; instances must be created via factory class methods.

### **5.4 Related Files**

| File | Description |
|------|------|
| `PlayerKit/Source/Data/VideoSource.h` | VideoSource class and VideoSourceType enum definition |
| `PlayerKit/Source/Data/VideoSource.m` | VideoSource implementation (factory methods, isValid, uniqueId derivation) |
| `PlayerKit/Source/AliPlayerModel.h` | Playback data model (receives video source via `initWithVideoSource:`) |

> For the complete API, see [API Reference](../ApiReference-EN.md).

---

## **6. Example Reference**

> **Reference**: The `PlayerKitUsages/UsageVideoSource` module provides complete video source usage examples, including creation of all three video source types, parameter validation, and playback flows.
