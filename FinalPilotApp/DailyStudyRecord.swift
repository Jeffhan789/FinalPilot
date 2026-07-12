import Foundation

// MARK: - DailyStudyRecord
/// 每日学习记录结构体，用于统计学习数据。
/// 当前作为纯 Swift 结构体在内存中使用；接入 Core Data 后，可映射为 DailyStudyRecordEntity。
struct DailyStudyRecord: Identifiable {
    let id: String
    var date: Date
    var courseID: String?
    var courseName: String?
    var studyMinutes: Int
    var completedTasks: Int
    var totalQuestions: Int
    var correctQuestions: Int
    var weakPointChanges: [WeakPointChange]

    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctQuestions) / Double(totalQuestions)
    }

    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    var weekdayIndex: Int {
        Calendar.current.component(.weekday, from: date)
    }

    var weekdayLabel: String {
        switch weekdayIndex {
        case 1: return "周日"
        case 2: return "周一"
        case 3: return "周二"
        case 4: return "周三"
        case 5: return "周四"
        case 6: return "周五"
        case 7: return "周六"
        default: return ""
        }
    }
}

// MARK: - WeakPointChange
/// 薄弱知识点变化记录，用于追踪每日知识掌握度变化。
struct WeakPointChange: Identifiable, Codable {
    let id: String
    var knowledgePointID: String
    var knowledgePointTitle: String
    var previousMastery: Double
    var currentMastery: Double

    var delta: Double {
        currentMastery - previousMastery
    }

    var isImproved: Bool {
        delta > 0
    }
}

// MARK: - Core Data 迁移说明
/*
 接入 Core Data 时，请按以下步骤创建数据模型：

 1. 创建 .xcdatamodeld 文件（如 FinalPilot.xcdatamodeld）
 2. 添加 Entity: DailyStudyRecordEntity
    - id: String (Attribute)
    - date: Date (Attribute)
    - courseID: String? (Optional Attribute)
    - courseName: String? (Optional Attribute)
    - studyMinutes: Int32 (Attribute)
    - completedTasks: Int32 (Attribute)
    - totalQuestions: Int32 (Attribute)
    - correctQuestions: Int32 (Attribute)
    - weakPointChangesData: Binary Data (Attribute, Transformable)

 3. 添加 Entity: WeakPointChangeEntity
    - id: String (Attribute)
    - knowledgePointID: String (Attribute)
    - knowledgePointTitle: String (Attribute)
    - previousMastery: Double (Attribute)
    - currentMastery: Double (Attribute)

 4. 创建 NSManagedObject 子类或使用 @objc(NSManagedObject) 扩展。

 5. 在 AppStore.swift 的 FinalPilotStore 中注入 NSPersistentContainer，
    并将 @Published 属性改为从 Core Data 读取/写入。

 示例映射代码（供参考）：

 ```swift
 extension DailyStudyRecordEntity {
     func toRecord() -> DailyStudyRecord {
         DailyStudyRecord(
             id: id ?? UUID().uuidString,
             date: date ?? Date(),
             courseID: courseID,
             courseName: courseName,
             studyMinutes: Int(studyMinutes),
             completedTasks: Int(completedTasks),
             totalQuestions: Int(totalQuestions),
             correctQuestions: Int(correctQuestions),
             weakPointChanges: []
         )
     }
 }
 ```
*/
