# FinalPilot（学呀学）

> English first. 中文版见后文。

[English](#english) | [中文](#中文)

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
