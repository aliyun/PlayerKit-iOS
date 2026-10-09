Language: [中文简体](README.md) | English

![alibaba_cloud_logo](./docs/_media/AlibabaCloud.svg)

# **AliPlayerKit iOS**

[![Release](https://img.shields.io/github/v/release/aliyun/PlayerKit-iOS?logo=github)](https://github.com/aliyun/PlayerKit-iOS/releases) [![Platform](https://img.shields.io/badge/Platform-iOS%209.0%2B-blue.svg)](https://developer.apple.com/ios/) [![Language](https://img.shields.io/badge/Language-Objective--C-orange.svg)](https://developer.apple.com/documentation/objectivec) [![CocoaPods](https://img.shields.io/badge/CocoaPods-compatible-green.svg)](https://cocoapods.org/) [![website](https://img.shields.io/badge/Product-VOD-FF6A00)](https://www.alibabacloud.com/en/product/apsaravideo-for-vod)

---

## **1. Project Introduction**

**AliPlayerKit** is Alibaba Cloud's **player UI integration solution** for video applications, offering **low-code, extensible player UI components** and **scenario-based solutions**. 

<p align="center">
  <img
    src="./docs/_media/playerkit-ui-preview.png"
    alt="AliPlayerKit UI preview"
    width="100%"
  />
</p>

<p align="center">
  <sub>Ready-to-use player UI components for multiple playback scenarios</sub>
</p>

By encapsulating player capabilities and UI interactions, it enables rapid development of app playback features with minimal integration effort — no need to call underlying player APIs directly or build complex player UIs from scratch.

---

## **2. Core Features**

- **Low-Code Integration** — Minimalist API design; integrate the player in just a few lines of code.
- **Ready-to-Use UI Components** — Configurable player UI components covering essential playback and common interactions, with support for on-demand customization.
- **All-in-One Playback Experience** — Simply pass a video VID to automatically display cover images, video titles, seek thumbnails, and other complete playback information for a one-stop playback experience.
- **Scenario-Based Solutions** — Built-in support for typical business scenarios such as mid/long-form video, short video, live streaming, playlist, and AI Education to quickly build complete playback experiences.
- **Highly Extensible Architecture** — A slot system for flexible UI composition and a strategy system for extensible business logic.
- **Cross-Platform Unified Architecture** — All platforms share the same design philosophy and API semantics, reducing multi-platform integration and maintenance costs.

| Platform | Description | Source | Docs |
|----------|-------------|--------|------|
| **Android** | Native Android player UI components & scenario solutions | [PlayerKit-Android](https://github.com/aliyun/PlayerKit-Android) | [Online Docs](https://aliyun.github.io/PlayerKit-Android/) |
| **iOS** | Native iOS player UI components & scenario solutions | [PlayerKit-iOS](https://github.com/aliyun/PlayerKit-iOS) | [Online Docs](https://aliyun.github.io/PlayerKit-iOS/) |
| **Flutter** | Cross-platform Flutter player widget | [player_widget](https://github.com/aliyun/player_widget) | [Online Docs](https://aliyun.github.io/player_widget/) |

---

## **3. Project Structure**

In terms of architecture, **AliPlayerKit sits on top of the player core**, providing a unified UI component system and playback scenario abstraction to host the common capabilities of various playback businesses:

![ProductArchitecture](./docs/_media/ProductArchitecture-EN.png)

The project module structure is as follows:

```
PlayerKit-iOS/
├── PlayerKit/                  # Core Module: Player UI components
├── PlayerKitScenes/            # Scenes Module: Business scenario solutions
├── PlayerKitUsages/            # Examples Module: Feature demonstrations
├── App/                        # Demo App: Full feature demonstration
├── Example/                    # Xcode project configuration
└── docs/                       # Documentation: Architecture, integration guides, and API docs
```

---

## **4. Quick Start**

### **4.1 Online Reading**

**[🌐 Click here to start reading online](https://aliyun.github.io/PlayerKit-iOS/)**

### **4.2 Local Reading**

If you prefer to read the documentation locally, refer to the [**Documentation Index**](./docs/README-EN.md).

This index provides a clear documentation structure with step-by-step instructions, making it easy for **both AI and developers to understand and execute**. In the future, we will also provide dedicated **Skills support** for a more complete and convenient integration experience.

---

## **5. Quick Integration**

AliPlayerKit adopts a **layered architecture design** and provides two integration approaches that you can choose from flexibly based on your business needs:

| Layer | Module | Description | Use Cases |
|-----|------|------|---------|
| **Component Layer** | `PlayerKit` | Core UI components, providing player views, controllers, and data models | When custom UI or flexible playback control is needed |
| **Scene Layer** | `PlayerKitScenes` | Complete scenario solutions, including UI and business logic | Quickly implement standard playback scenarios |

> **Note**: The Scene Layer depends on the Component Layer. If you choose Scene Layer integration, you must complete Component Layer integration first.

> **Swift Projects**: PlayerKit is developed in Objective-C. For Swift projects, refer to the [Swift-Call-OC-Example](https://github.com/MediaBox-Demos/AliPlayer-iOS/tree/master/Swift-Call-OC-Example) for integration guidance.

> **Detailed Steps**: See [Integration](./docs/Integration-EN.md). For more information, refer to the [Documentation Index](./docs/README-EN.md).

---

## **6. Quick Onboarding**

In just a few steps, you can easily implement video playback. The diagram below shows the **component layer integration** flow:

![QuickStart](./docs/_media/QuickStart-EN.png)

> **Detailed Steps**: See [Quick Start](./docs/QuickStart-EN.md). For more information, refer to the [Documentation Index](./docs/README-EN.md).

---

## **7. Demo Showcase**

### **7.1 Run the Project**

#### **Prerequisites**

Before running the project, ensure the following requirements are met:

| Requirement | Description |
|-----|------|
| Xcode | 15.0+, latest stable version recommended |
| iOS | Minimum 9.0, real device recommended |
| CocoaPods | 1.13.0+ |
| License | Player License certificate and License Key obtained. See [Obtain an ApsaraVideo Player SDK license](https://www.alibabacloud.com/help/en/vod/developer-reference/obtain-the-player-sdk-license) |

#### **Running Steps**

**Step 1: Install Dependencies**

```bash
cd Example
pod install
```

**Step 2: Open the Project**

Open `Example/Example.xcworkspace` with Xcode (use `.xcworkspace`, not `.xcodeproj`).

**Step 3: Configure License**

The player SDK requires a valid License to function properly. See [Integrate a license](https://www.alibabacloud.com/help/en/vod/developer-reference/access-to-license) for License acquisition and configuration.

**Step 4: Run the Project**

Select the target device and click Run (`Cmd + R`).

#### **FAQ**

**License Issues**: The License is bound to the application Bundle ID. Without proper configuration, the player will not work. See [License FAQ](https://www.alibabacloud.com/help/en/vod/developer-reference/faqs-for-sdk-license) for details.

### **7.2 Demo App**

To help developers quickly experience the features of AliPlayerKit, we have built a demo package based on this project. The demo can be installed directly on a device, with no development environment required.

**How to obtain:**

Scan the following QR code with your phone to quickly download and install the demo:

![Demo QR Code](./docs/_media/demo-qr-code_en.png)

> **Note**: The QR code points to the latest version of the demo. Please ensure that your device allows the installation of third-party applications.

---

## **8. Device-Cloud Synergy**

AliPlayerKit is built on top of Alibaba Cloud's audio and video capabilities. We recommend combining it with cloud products to take full advantage of device-cloud synergy and further improve playback capabilities and video experience.

| Cloud Product                                                | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [ApsaraVideo for VOD](https://www.alibabacloud.com/en/product/apsaravideo-for-vod) | An all-in-one VOD service covering video upload, storage, transcoding, distribution, and playback |
| [ApsaraVideo for Live](https://www.alibabacloud.com/en/product/apsaravideo-for-live) | An end-to-end live streaming service covering stream ingest, transcoding, distribution, and playback |

---

## **9. Contact Us**

- 📘 **Official Documentation**: [Player UI Integration Solution](https://www.alibabacloud.com/help/en/vod/developer-reference/playerkit-ios-project-introduction)
- 🔍 **Console**: [ApsaraVideo for VOD Console](https://vod.console.alibabacloud.com)
- 📝 **Submit a Ticket**: [Alibaba Cloud Official Technical Support](https://smartservice.console.alibabacloud.com/service/create-ticket)
- 💬 **GitHub Issues**: [Feedback and suggestions are welcome](https://github.com/aliyun/PlayerKit-iOS/issues)

For more FAQs and fixes about using the Alibaba Cloud Player, see [FAQ about ApsaraVideo Player](https://www.alibabacloud.com/help/en/vod/support/faq-about-apsaravideo-player/).
