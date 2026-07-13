# FinalPilot（学呀学）

![Version](https://img.shields.io/badge/version-v2.0.0-orange?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-5.9+-f05138?style=flat-square&logo=swift)
![iOS](https://img.shields.io/badge/iOS-17+-007AFF?style=flat-square&logo=apple)
![SwiftUI](https://img.shields.io/badge/SwiftUI-blue?style=flat-square&logo=swift)
![CoreData](https://img.shields.io/badge/Core%20Data-green?style=flat-square)
![WidgetKit](https://img.shields.io/badge/WidgetKit-purple?style=flat-square)
![Charts](https://img.shields.io/badge/Charts-Framework-pink?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)
![CI](https://github.com/Jeffhan789/FinalPilot/actions/workflows/ci.yml/badge.svg?branch=main)

> English first. 中文版见后文。
> **Tech Stack & Interview Questions** → [技术原理概览](#技术原理概览) | **Learning Path** → [学习路径](#学习路径) | **Interview Q&A** → [面试问答速查](#面试问答速查)

[English](#english) | [中文](#中文)

---

## 技术原理概览（Tech Stack Overview）

| 技术栈 | 本项目用途 | 面试高频问题（原理视角） |
|--------|-----------|------------------------|
| **SwiftUI** | 声明式 UI 构建全部页面 | 为什么选 SwiftUI 而非 UIKit？`@State` 与 `@ObservedObject` 的内存模型差异？ |
| **Core Data** | 课程、任务、进度本地持久化 | [原理] 为什么不用 SwiftData？`NSPersistentContainer` 的初始化与线程模型？ |
| **WidgetKit** | 桌面小组件展示今日复习任务 | [原理] Timeline 刷新机制？`getTimeline` 的 `reloadPolicy` 如何设计？ |
| **UserNotifications** | 艾宾浩斯复习提醒推送 | [原理] 权限生命周期？`UNUserNotificationCenter` 的异步授权与主线程回调？ |
| **Charts** | 学习进度可视化（条形图/趋势图） | [原理] `Chart` 的数据绑定与 `ChartProxy` 的动画插值？ |
| **Swift Concurrency** | 数据同步、文件读取异步处理 | [原理] `async/await` 替代 GCD 的场景？`Task` 的取消传播机制？ |
| **App Groups** | 主 App 与 Widget 共享 Core Data | [原理] `UserDefaults` 与 `NSPersistentContainer` 的跨进程访问方案？ |
| **艾宾浩斯调度** | 智能生成复习间隔（1/2/4/7/15/30 天） | [原理] 遗忘曲线如何映射到 `UNTimeIntervalNotificationTrigger`？ |
| **暗色模式适配** | 系统级 `colorScheme` 动态切换 | [原理] `SwiftUI` 的 `EnvironmentValues` 如何传递 `ColorScheme`？ |
| **Core Data Migration** | 版本迭代时数据模型迁移 | [原理] 轻量迁移 vs 重度迁移的决策条件？ |

> 💡 **阅读提示**：每个技术点的 `[原理]` 表示其底层实现机制，`[面试]` 表示面试中需要口头阐述的关键点。建议先通览全表，再按 [学习路径](#学习路径) 深入。

---

## English

> **Exam Sprint Decision System**

Project Name: XueYaXue (Learn & Learn)
Project Codename: FinalPilot
Project Positioning: iOS Final Exam Sprint Decision System based on Multi-Agent Collaboration, Cloud Computing, and Neural Network Analysis
Current Stage: v0.1 Local MVP Built
Creation Date: 2026-05-01
GitHub Repository: https://github.com/Jeffhan789/FinalPilot


## Project Goals

XueYaXue targets university students preparing for final exams, providing intelligent review planning around three real exam subjects:

- C310 Multi-Agent Systems: 2026-05-13
- E320 Neural Networks: 2026-05-14
- C315 E-Commerce Cloud Computing: 2026-05-26

The app's core closed loop is:

User sets courses and exam dates -> System generates review plan -> User completes tasks and quizzes -> System diagnoses weak points -> Automatically adjusts subsequent review schedule.

## File Structure

```text
FinalPilot_期末复习App/
├── README.md
├── FinalPilotApp.xcodeproj/
├── FinalPilotApp/
│   ├── FinalPilotApp.swift
│   ├── ContentView.swift
│   ├── Models.swift
│   ├── SeedData.swift
│   ├── AppStore.swift
│   ├── Theme.swift
│   ├── Components.swift
│   ├── DashboardView.swift
│   ├── PlanView.swift
│   ├── StudySyncSnapshot.swift
│   ├── StudySyncSnapshot.json
│   ├── CoursesView.swift
│   ├── PracticeView.swift
│   ├── AnalyticsView.swift
│   ├── CareerView.swift
│   └── Assets.xcassets/
├── docs/
│   ├── 01_需求规格说明书.md
│   ├── 02_落地执行方案.md
│   ├── 03_版面与交互设计.md
│   ├── 04_技术架构与课程映射.md
│   ├── 05_数据模型与题库规划.md
│   ├── 06_术语解释.md
│   ├── 07_市场调研与考前冲刺重估.md
│   ├── 08_复习与校招面试双轨调度.md
│   ├── 09_v0.1第一版交付说明.md
│   ├── 10_真实考试规划同步.md
│   ├── 11_App图标与A4计划同步说明.md
│   ├── 12_固定路径实时同步方案.md
│   ├── 13_GitHub安全审计报告.md
│   ├── 14_XYX图标候选方案.md
│   ├── 15_iOS安装包与分发说明.md
│   └── 16_TestFlight发布流程.md
├── data/
│   ├── knowledge_base_seed.json
│   ├── a4_sprint_plan_seed.json
│   └── study_sync_snapshot.json
├── tools/
│   ├── generate_icon_from_reference.py
│   ├── generate_icon_candidates.swift
│   ├── generate_icon_shortlist.swift
│   └── sync_study_sources.mjs
└── records/
    └── 进展日志.md
```

## Review Guidelines

You only need to focus on reviewing three types of content:

1. Whether the product direction aligns with your campus recruitment showcase goals.
2. Whether the technical implementation of the three courses is sufficiently prominent.
3. Whether the page design and feature scope meet your expectations.

I will continue to maintain:

- Adding or modifying project documents
- Recording each progress update
- Breaking down requirements into development tasks
- Designing iOS pages and interactions
- Preparing resume descriptions, README, and demo scripts
- Syncing each important update to the GitHub repository `Jeffhan789/FinalPilot`

## Current First-Version Achievements

- Project name and product positioning confirmed.
- First version requirements specification completed.
- MVP implementation plan completed.
- iOS layout and interaction design direction completed.
- Technical architecture and course mapping design completed.
- Knowledge point seed data for three courses prepared.
- Project progress recording mechanism established.
- Competitor research and sprint scenario reassessment for consecutive exams on 2026-05-13 and 2026-05-14 added.
- Dual-track scheduling design for exam review and spring campus recruitment interviews added.
- SwiftUI iOS project `FinalPilotApp.xcodeproj` created.
- v0.1 Local MVP implemented: Today, Plan, Courses, Practice, and Career tabs.
- Build verification passed on generic iOS device.
- Real exam dates synced: C310 set to 2026-05-13, E320 set to 2026-05-14, C315 set to 2026-05-26.
- Today's tasks adjusted to prioritize C310 / E320 dual exams; C315 enters main review after May 14.
- Mobile desktop display name changed to `学呀学`.
- `学呀学` App icon extracted from hand-drawn reference and written to `Assets.xcassets/AppIcon.appiconset`.
- A4 two-week sprint plan synced to the in-app `Plan` page.
- Fixed-path sync bridge added to select progress files from C310, E320, and master control directories and generate an App-readable snapshot.
- `Plan` page right-alignment optimized; long content fits within mobile screen.
- Only transfer IPA and icon preview image retained on desktop.
- Subsequent distribution target clarified to switch to TestFlight; App Store Connect copy prepared.

## Fixed-Path Sync

Generate a snapshot:

```text
node tools/sync_study_sources.mjs --write
```

Start the real-time sync service:

```text
node tools/sync_study_sources.mjs --serve
```

Then click `Refresh` in the App's `Plan` page. If the service is running, it will display `实时服务` (Live Service); if not, it will display the bundled `内置快照` (Built-in Snapshot).

## How to Run

Open with Xcode:

```text
FinalPilotApp.xcodeproj
```

Install on a real iPhone:

1. Connect iPhone via USB, keep the phone unlocked, and select "Trust This Mac" on the phone.
2. In the Xcode top device bar, select your iPhone, not `Any iOS Device`.
3. Open the project Target's `Signing & Capabilities`, check `Automatically manage signing`, and select your Apple ID / Personal Team for `Team`.
4. If the Bundle Identifier conflicts, change `com.jeffhan.FinalPilot` to your own unique identifier, e.g., `com.jeffhan.XueYaXue`.
5. Click the Xcode top-left run button. After installation, `学呀学` will appear on the phone's home screen.
6. If the phone prompts "Untrusted Developer", go to `Settings > General > VPN & Device Management` and trust your Apple ID certificate.

Note: This is not downloaded from the App Store; Xcode temporarily signs the app and installs it directly on your phone. After modifying the code, click run again to overwrite the installation.

Command-line verification:

```text
xcodebuild -project FinalPilotApp.xcodeproj \
  -scheme FinalPilotApp \
  -configuration Debug \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /private/tmp/FinalPilotDeviceDerived \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Current verification result:

```text
BUILD SUCCEEDED
```

---

## 中文

# FinalPilot

> **Exam Sprint Decision System**

项目名称：学呀学
工程代号：FinalPilot
项目定位：基于多智能体协作、云计算与神经网络分析的 iOS 期末复习冲刺决策系统
当前阶段：v0.1 本地 MVP 已构建
创建日期：2026-05-01
GitHub 仓库：https://github.com/Jeffhan789/FinalPilot


## 项目目标

学呀学面向准备期末考试的大学生，围绕三门真实考试内容进行智能复习规划：

- C310 多智能体系统：2026-05-13
- E320 神经网络：2026-05-14
- C315 电子商务云计算：2026-05-26

App 的核心闭环是：

用户设置课程与考试日期 -> 系统生成复习计划 -> 用户完成任务与测验 -> 系统诊断薄弱点 -> 自动调整后续复习安排。

## 文件结构

```text
FinalPilot_期末复习App/
├── README.md
├── FinalPilotApp.xcodeproj/
├── FinalPilotApp/
│   ├── FinalPilotApp.swift
│   ├── ContentView.swift
│   ├── Models.swift
│   ├── SeedData.swift
│   ├── AppStore.swift
│   ├── Theme.swift
│   ├── Components.swift
│   ├── DashboardView.swift
│   ├── PlanView.swift
│   ├── StudySyncSnapshot.swift
│   ├── StudySyncSnapshot.json
│   ├── CoursesView.swift
│   ├── PracticeView.swift
│   ├── AnalyticsView.swift
│   ├── CareerView.swift
│   └── Assets.xcassets/
├── docs/
│   ├── 01_需求规格说明书.md
│   ├── 02_落地执行方案.md
│   ├── 03_版面与交互设计.md
│   ├── 04_技术架构与课程映射.md
│   ├── 05_数据模型与题库规划.md
│   ├── 06_术语解释.md
│   ├── 07_市场调研与考前冲刺重估.md
│   ├── 08_复习与校招面试双轨调度.md
│   ├── 09_v0.1第一版交付说明.md
│   ├── 10_真实考试规划同步.md
│   ├── 11_App图标与A4计划同步说明.md
│   ├── 12_固定路径实时同步方案.md
│   ├── 13_GitHub安全审计报告.md
│   ├── 14_XYX图标候选方案.md
│   ├── 15_iOS安装包与分发说明.md
│   └── 16_TestFlight发布流程.md
├── data/
│   ├── knowledge_base_seed.json
│   ├── a4_sprint_plan_seed.json
│   └── study_sync_snapshot.json
├── tools/
│   ├── generate_icon_from_reference.py
│   ├── generate_icon_candidates.swift
│   ├── generate_icon_shortlist.swift
│   └── sync_study_sources.mjs
└── records/
    └── 进展日志.md
```

## 审核方式

你只需要重点审核三类内容：

1. 产品方向是否符合你的校招展示目标。
2. 三门课程的技术体现是否足够明显。
3. 页面设计和功能范围是否符合你的预期。

我后续会持续维护：

- 新增或修改项目文档
- 记录每次进展
- 将需求拆成开发任务
- 设计 iOS 页面与交互
- 准备简历描述、README、演示脚本
- 每次重要更新后同步到 GitHub 仓库 `Jeffhan789/FinalPilot`

## 当前首版成果

- 已确定项目名称与产品定位。
- 已完成首版需求规格。
- 已完成 MVP 落地计划。
- 已完成 iOS 版面与交互设计方向。
- 已完成技术架构和课程映射设计。
- 已准备三门课程的知识点种子数据。
- 已建立项目进展记录机制。
- 已补充竞品调研与 2026-05-13、2026-05-14 连续考试冲刺场景重估。
- 已新增考试复习与春季校招面试并行的双轨调度设计。
- 已创建 SwiftUI iOS 工程 `FinalPilotApp.xcodeproj`。
- 已实现 v0.1 本地 MVP：今日、计划、课程、练习、校招五个 Tab。
- 已通过 generic iOS device 构建验证。
- 已根据真实规划同步考试日期：C310 为 2026-05-13，E320 为 2026-05-14，C315 为 2026-05-26。
- 已把今日任务改为 C310 / E320 双考试优先，C315 在 5 月 14 日后进入主复习。
- 已将手机桌面显示名称改为 `学呀学`。
- 已根据手绘参考图提取 `学呀学` App 图标，写入 `Assets.xcassets/AppIcon.appiconset`。
- 已将 A4 两周复习进度规划表同步为 App 内 `计划` 页面。
- 已新增固定路径同步桥，从 C310、E320、总控目录挑选进度文件并生成 App 可读取的快照。
- 已优化 `计划` 页面右侧对齐，长内容会收敛在手机屏幕内。
- 已在桌面只保留转签用 IPA 和图标预览图。
- 已明确后续分发目标改为 TestFlight，并准备 App Store Connect 填写文案。

## 固定路径同步

生成一次快照：

```text
node tools/sync_study_sources.mjs --write
```

开启实时同步服务：

```text
node tools/sync_study_sources.mjs --serve
```

然后在 App 的 `计划` 页点击 `刷新`。如果服务开着，会显示 `实时服务`；如果没开，会显示打包进 App 的 `内置快照`。

## 运行方式

用 Xcode 打开：

```text
FinalPilotApp.xcodeproj
```

真机安装到 iPhone：

1. 用 USB 连接 iPhone，手机保持解锁，并在手机上选择信任这台 Mac。
2. Xcode 顶部设备栏选择你的 iPhone，不要选 `Any iOS Device`。
3. 打开项目 Target 的 `Signing & Capabilities`，勾选 `Automatically manage signing`，`Team` 选择你的 Apple ID / Personal Team。
4. 如果 Bundle Identifier 冲突，把 `com.jeffhan.FinalPilot` 改成你自己的唯一标识，例如 `com.jeffhan.XueYaXue`。
5. 点击 Xcode 左上角运行按钮。安装完成后，手机桌面会显示 `学呀学`。
6. 如果手机提示未信任开发者，进入 `设置 > 通用 > VPN 与设备管理`，信任你的 Apple ID 证书。

说明：这不是从 App Store 下载，而是 Xcode 对 App 临时签名后直接安装到你的手机。以后改完代码，再点击运行即可覆盖安装。

命令行验证：

```text
xcodebuild -project FinalPilotApp.xcodeproj \
  -scheme FinalPilotApp \
  -configuration Debug \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /private/tmp/FinalPilotDeviceDerived \
  CODE_SIGNING_ALLOWED=NO \
  build
```

当前验证结果：

```text
BUILD SUCCEEDED
```


---

## 学习路径（Learning Path）

> 为想学习本项目技术的开发者提供的建议学习顺序。每步包含 1–2 个官方文档或 WWDC 视频，按「先搭框架、再深入持久化、最后扩展能力」的顺序排列。

### 第 1 步：SwiftUI 声明式 UI（基础框架）

**学习目标**：理解 `View` 协议、`@State`/`@Binding`/`@ObservedObject` 的内存模型，能独立搭建多 Tab 页面。

- [SwiftUI Essentials - Apple Developer](https://developer.apple.com/documentation/swiftui/app-essentials)
- [WWDC 2023 - What's new in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10123/)

> **面试原理**：`@State` 是值类型状态，由 SwiftUI 框架托管内存；`@ObservedObject` 是引用类型，需在 `ObservableObject` 中用 `@Published` 触发 `objectWillChange`。

---

### 第 2 步：Core Data 持久化（数据层）

**学习目标**：理解 `NSPersistentContainer`、`NSManagedObjectContext`、FetchRequest 的线程安全，掌握轻量迁移。

- [Core Data Overview - Apple Developer](https://developer.apple.com/documentation/coredata)
- [WWDC 2020 - Core Data: Sundries and maxims](https://developer.apple.com/videos/play/wwdc2020/10017/)

> **面试原理**：`NSPersistentContainer` 封装了 `NSManagedObjectModel` + `NSPersistentStoreCoordinator` + `NSManagedObjectContext`，是线程安全的「栈」结构；`viewContext` 主线程操作，`performBackgroundTask` 异步操作。

---

### 第 3 步：WidgetKit 与 App Groups（扩展能力）

**学习目标**：理解 `Widget` 协议、`TimelineProvider` 的刷新机制，以及主 App 与 Widget 的数据共享方案。

- [WidgetKit - Apple Developer](https://developer.apple.com/documentation/widgetkit)
- [WWDC 2020 - Widgets Code-along](https://developer.apple.com/videos/play/wwdc2020/10034/)
- [App Groups - Apple Developer](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)

> **面试原理**：`getTimeline` 返回 `Timeline<Entry>`，系统根据 `reloadPolicy` 决定下次刷新时机；数据共享通过 `UserDefaults(suiteName:)` 或 `NSPersistentContainer` 的共享 `NSPersistentStore` 实现。

---

### 第 4 步：UserNotifications 与权限生命周期（系统能力）

**学习目标**：理解推送权限的请求时机、通知的 `UNNotificationRequest` 构造，以及 `UNUserNotificationCenterDelegate` 的回调处理。

- [UserNotifications - Apple Developer](https://developer.apple.com/documentation/usernotifications)
- [WWDC 2020 - Notifications overview](https://developer.apple.com/videos/play/wwdc2020/10108/)

> **面试原理**：权限请求必须在用户交互后触发（最佳实践是「需要时才请求」）；通知的 `trigger` 可以是 `UNTimeIntervalNotificationTrigger` 或 `UNCalendarNotificationTrigger`，本项目用前者实现艾宾浩斯间隔。

---

### 第 5 步：Charts 与 Swift Concurrency（进阶可视化与异步）

**学习目标**：理解 `Chart` 的声明式数据绑定、`async/await` 替代 GCD 的场景，以及 `Task` 的取消传播。

- [Swift Charts - Apple Developer](https://developer.apple.com/documentation/charts)
- [WWDC 2022 - Meet Swift Charts](https://developer.apple.com/videos/play/wwdc2022/10134/)
- [WWDC 2021 - Meet async/await in Swift](https://developer.apple.com/videos/play/wwdc2021/10132/)

> **面试原理**：`Chart` 通过 `ChartProxy` 实现动画插值，数据变化时自动过渡；`async/await` 的 `Task` 可以跨 `await` 点传播取消，比 GCD 的 `DispatchWorkItem` 更优雅。

---

## 面试问答速查（Interview Q&A Quick Reference）

> 以下 10 个高频面试问题及答案，按「原理 + 面试表达」双维度整理，适合面试前 30 分钟快速复习。

---

### Q1：为什么用 Core Data 而不是 SwiftData？

**中文答案**：
> [原理] SwiftData 是 iOS 17 的新框架，基于 `Swift macros` 和 `Observable` 协议，语法更简洁，但 `FinalPilot` 项目启动时 SwiftData 刚发布，稳定性与迁移工具链尚未成熟；Core Data 拥有完整的 `NSPersistentContainer` 线程模型、轻量/重度迁移方案，以及 App Groups 跨进程共享的成熟实践。对于需要 Widget 共享数据、版本迭代频繁的期末冲刺项目，Core Data 的可控性更高。
>
> [面试] 我会回答：「项目启动时 SwiftData 尚新，我们选择了 Core Data 以确保线程安全和迁移稳定性；同时 Core Data 的 `App Groups` 共享方案在 Widget 场景中已有大量实践。」

**English Answer**：
> [Principle] SwiftData was newly introduced in iOS 17. When the project started, its stability and migration toolchain were not yet mature. Core Data offers a proven `NSPersistentContainer` threading model, lightweight/heavy migration paths, and well-established `App Groups` sharing for Widgets.
>
> [Interview] I would say: "We chose Core Data for its proven thread safety and migration stability, especially since we needed App Groups sharing with WidgetKit from day one."

---

### Q2：Widget 的数据如何与主 App 同步？

**中文答案**：
> [原理] 通过 `App Groups` 共享 `UserDefaults` 或 `NSPersistentStore`。主 App 将今日复习任务写入 `UserDefaults(suiteName: "group.com.jeffhan.FinalPilot")`，Widget 的 `TimelineProvider` 在 `getTimeline` 中读取同一 suite，生成 `Entry` 并返回 `Timeline`。
>
> [面试] 我会回答：「主 App 和 Widget 通过 App Groups 共享 `UserDefaults`，Widget 的 `TimelineProvider` 在 `getTimeline` 中读取共享数据，系统根据 `reloadPolicy` 自动刷新。」

**English Answer**：
> [Principle] The host app writes today's review tasks into `UserDefaults(suiteName: "group.com.jeffhan.FinalPilot")`. The Widget's `TimelineProvider` reads the same suite in `getTimeline`, constructs an `Entry`, and returns a `Timeline`. The system refreshes the widget based on `reloadPolicy`.
>
> [Interview] I would say: "We use App Groups to share `UserDefaults` between the host app and the widget; the `TimelineProvider` reads shared data in `getTimeline`, and the system handles the refresh schedule."

---

### Q3：艾宾浩斯复习调度怎么实现？

**中文答案**：
> [原理] 艾宾浩斯遗忘曲线的关键间隔是 1、2、4、7、15、30 天。在代码中，每次用户完成一次复习，系统计算下一次复习日期（当前日期 + 间隔天数），并创建 `UNTimeIntervalNotificationTrigger` 或 `UNCalendarNotificationTrigger` 的本地通知。Core Data 中每条复习任务记录 `nextReviewDate` 字段，每日启动时 Fetch 所有 `nextReviewDate <= today` 的任务展示。
>
> [面试] 我会回答：「根据艾宾浩斯曲线定义 6 个间隔，每次复习完成后计算下一次日期并注册本地通知，同时用 Core Data 的 `nextReviewDate` 字段过滤今日任务。」

**English Answer**：
> [Principle] The Ebbinghaus forgetting curve intervals are 1, 2, 4, 7, 15, and 30 days. After each review session, the app calculates the next review date and schedules a local notification via `UNTimeIntervalNotificationTrigger`. A `nextReviewDate` field in Core Data is used to filter today's tasks at launch.
>
> [Interview] I would say: "We define six intervals from the Ebbinghaus curve, compute the next review date after each session, and schedule a local notification while filtering today's tasks using Core Data's `nextReviewDate`."

---

### Q4：暗色模式在 SwiftUI 中如何适配？

**中文答案**：
> [原理] SwiftUI 通过 `EnvironmentValues` 注入 `ColorScheme`。在 `Assets.xcassets` 中定义支持 `Any, Dark` 的 `Color Set`，或使用 `.foregroundColor(Color(.label))` 等系统自适应颜色。自定义颜色通过 `colorScheme` 环境值判断后返回不同 `Color`。
>
> [面试] 我会回答：「SwiftUI 自动响应系统 `ColorScheme` 变化，我们在 `Assets` 中定义了 Any/Dark 双色 Color Set，同时用 `.label` 等系统动态颜色确保对比度合规。」

**English Answer**：
> [Principle] SwiftUI injects `ColorScheme` via `EnvironmentValues`. In `Assets.xcassets`, define `Color Set` with `Any, Dark` appearances, or use system adaptive colors like `Color(.label)`. Custom colors can switch based on the `colorScheme` environment value.
>
> [Interview] I would say: "SwiftUI automatically responds to system `ColorScheme` changes; we define dual-appearance Color Sets in Assets and use system dynamic colors like `.label` to ensure contrast compliance."

---

### Q5：`@State` 和 `@ObservedObject` 的区别？

**中文答案**：
> [原理] `@State` 用于值类型（`struct`），由 SwiftUI 框架在 `View` 内部分配私有存储，状态变化时 SwiftUI 重新计算 `body`；`@ObservedObject` 用于引用类型（`class`），需遵守 `ObservableObject` 协议，用 `@Published` 包装属性，变化时通过 `objectWillChange` 发送器通知 SwiftUI 刷新。`@State` 的生命周期与 `View` 绑定，`@ObservedObject` 可能由外部注入，生命周期不由 `View` 控制。
>
> [面试] 我会回答：「`@State` 是值类型的本地状态，SwiftUI 内部托管；`@ObservedObject` 是引用类型，需实现 `ObservableObject`，用 `@Published` 触发刷新，适合跨视图共享的数据模型。」

**English Answer**：
> [Principle] `@State` is for value types (`struct`), stored privately by SwiftUI within the `View`; when mutated, SwiftUI recomputes `body`. `@ObservedObject` is for reference types (`class`) conforming to `ObservableObject`; `@Published` properties trigger `objectWillChange`, causing SwiftUI to refresh. `@State` lifetime is tied to the `View`, while `@ObservedObject` may be injected externally.
>
> [Interview] I would say: "`@State` is for local value-type state managed by SwiftUI; `@ObservedObject` is for shared reference-type models that emit `objectWillChange` via `@Published` to trigger UI updates."

---

### Q6：Core Data 的线程模型是什么？

**中文答案**：
> [原理] `NSManagedObjectContext` 不是线程安全的。`persistentContainer.viewContext` 绑定主线程，用于 UI 操作；后台操作调用 `persistentContainer.performBackgroundTask`，其内部会创建新的 `NSManagedObjectContext` 并在私有队列执行。跨线程传递 `NSManagedObject` 必须通过 `objectID`，而不是直接传对象。
>
> [面试] 我会回答：「`viewContext` 只能在主线程使用；后台操作用 `performBackgroundTask`，它会自动创建私有队列的 `context`。跨线程传对象用 `objectID`，否则会发生崩溃。」

**English Answer**：
> [Principle] `NSManagedObjectContext` is not thread-safe. `viewContext` is bound to the main thread for UI operations; background work uses `performBackgroundTask`, which creates a private-queue `context`. Passing `NSManagedObject` across threads must use `objectID`, not the object itself.
>
> [Interview] I would say: "`viewContext` is main-thread only; for background work we use `performBackgroundTask`, which creates a private-queue context. We always pass `objectID` across threads to avoid crashes."

---

### Q7：WidgetKit 的 Timeline 刷新机制？

**中文答案**：
> [原理] `TimelineProvider` 的 `getTimeline` 返回 `Timeline<Entry>`，其中包含一组 `Entry`（未来时间点的数据快照）和 `reloadPolicy`。`reloadPolicy` 可以是 `.atEnd`（系统在当前 Timeline 结束后刷新）、`.after(date)`（指定时间后刷新）等。系统为了省电，不会精确按秒刷新，而是批量唤醒多个 Widget 一起更新。
>
> [面试] 我会回答：「`getTimeline` 提供未来多个时间点的 `Entry`，并设置 `reloadPolicy` 告诉系统何时重新请求。系统会批量唤醒 Widget，因此不能依赖精确时间。」

**English Answer**：
> [Principle] `TimelineProvider.getTimeline` returns a `Timeline<Entry>` containing a sequence of future entries and a `reloadPolicy`. The policy can be `.atEnd` or `.after(date)`, but the system batches widget refreshes to save power, so timing is not exact.
>
> [Interview] I would say: "`getTimeline` provides future entries and a `reloadPolicy` telling the system when to ask again; the system batches refreshes for power efficiency, so we don't rely on exact timing."

---

### Q8：通知权限的生命周期是怎样的？

**中文答案**：
> [原理] iOS 通知权限分为「授权」和「状态」两个阶段。首次调用 `requestAuthorization` 弹出系统弹窗，用户选择后结果通过回调返回；之后通过 `getNotificationSettings` 查询当前状态（`.authorized` / `.denied` / `.notDetermined`）。权限状态可随用户在系统设置中更改，App 每次启动应检查并引导用户开启。
>
> [面试] 我会回答：「首次启动时请求授权，之后通过 `getNotificationSettings` 检查状态。如果用户拒绝，我们会提示去系统设置中手动开启，并在设置页提供快捷跳转。」

**English Answer**：
> [Principle] Notification permission has two phases: authorization and status. `requestAuthorization` shows the system alert once; subsequent checks use `getNotificationSettings` to read `.authorized` / `.denied` / `.notDetermined`. Users can change this in Settings, so the app should check on launch and guide them to enable.
>
> [Interview] I would say: "We request authorization on first launch, then check `getNotificationSettings` on every startup. If denied, we guide the user to Settings with a deep link."

---

### Q9：Core Data Migration 的决策条件？

**中文答案**：
> [原理] 轻量迁移（Lightweight Migration）适用于「新增/删除属性/实体、重命名属性、添加 Transformable」等简单变化，由 Core Data 自动推断映射模型。重度迁移（Heavyweight Migration）适用于「拆分实体、复杂数据转换、无法自动推断的映射」，需手动创建 `NSMappingModel` 和 `NSEntityMigrationPolicy`。本项目使用轻量迁移，因为版本变化只涉及新增字段。
>
> [面试] 我会回答：「如果只是新增字段或重命名，用轻量迁移，Core Data 自动推断；如果涉及拆分实体或复杂转换，需要手动写映射模型和迁移策略。本项目只有新增字段，所以用了轻量迁移。」

**English Answer**：
> [Principle] Lightweight migration handles adding/removing attributes/entities, renaming, and simple changes; Core Data infers the mapping model automatically. Heavyweight migration requires a manual `NSMappingModel` and `NSEntityMigrationPolicy` for complex transforms like splitting entities. This project uses lightweight migration because versions only added fields.
>
> [Interview] I would say: "We use lightweight migration for simple additions and renames; heavyweight is only needed for complex transforms. Our schema only added fields, so lightweight was sufficient."

---

### Q10：SwiftUI 中的 `App` 协议与 `Scene` 生命周期？

**中文答案**：
> [原理] `FinalPilotApp.swift` 中 `App` 协议的 `body` 返回 `Scene`（通常是 `WindowGroup`），系统管理 `Scene` 的生命周期（`active` / `inactive` / `background`）。通过 `Environment(\.scenePhase)` 监听状态变化，在 `background` 时保存 Core Data 上下文，在 `active` 时刷新 Widget Timeline。
>
> [面试] 我会回答：「`App` 返回 `WindowGroup`，系统管理 `ScenePhase`。我们在 `background` 时保存 Core Data，在 `active` 时触发 Widget 刷新，确保数据一致性。」

**English Answer**：
> [Principle] The `App` protocol's `body` returns a `Scene` (usually `WindowGroup`). The system manages `ScenePhase` (`active`, `inactive`, `background`). We use `Environment(\.scenePhase)` to save Core Data on `background` and reload the Widget timeline on `active` to ensure data consistency.
>
> [Interview] I would say: "Our `App` returns a `WindowGroup`; we observe `ScenePhase` via `Environment` to save Core Data when entering background and refresh the widget timeline when becoming active."

---

> 📌 **使用建议**：
> - 面试前 30 分钟：快速通读「面试问答速查」，重点记忆 `[原理]` 中的关键词。
> - 技术深潜时：按「学习路径」逐步阅读官方文档，并在项目中对应代码处打上 `[原理]` 注释。
> - 教学讲解时：用「技术原理概览」表格作为大纲，确保每个技术点都覆盖到「为什么选它」和「面试怎么讲」。

---

*README 教学升级完成。如需添加更多技术点或扩展现有章节，请在对应文件末尾追加。*
