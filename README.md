# FinalPilot 期末复习 App 项目资料

项目名称：FinalPilot  
项目定位：基于多智能体协作、云计算与神经网络分析的 iOS 期末复习助手  
当前阶段：v0.1 本地 MVP 已构建  
创建日期：2026-05-01
GitHub 仓库：https://github.com/Jeffhan789/FinalPilot_App

## 项目目标

FinalPilot 面向准备期末考试的大学生，围绕三门真实考试内容进行智能复习规划：

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
│   └── 14_XYX图标候选方案.md
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
- 每次重要更新后同步到 GitHub 仓库 `Jeffhan789/FinalPilot_App`

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
- 已根据手绘参考图提取 FinalPilot App 图标，写入 `Assets.xcassets/AppIcon.appiconset`。
- 已将 A4 两周复习进度规划表同步为 App 内 `计划` 页面。
- 已新增固定路径同步桥，从 C310、E320、总控目录挑选进度文件并生成 App 可读取的快照。

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
