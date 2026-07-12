import CoreData
import Foundation

// MARK: - CoreDataMigrationHelper

/// 负责将 SeedData 中的硬编码数据一次性迁移到 Core Data 持久化存储。
/// 仅在首次启动时执行，后续启动会直接跳过。
final class CoreDataMigrationHelper {
    /// 检查 Core Data 是否已有数据，若无则执行迁移。
    static func migrateSeedDataIfNeeded(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<CourseEntity> = CourseEntity.fetchRequest()
        fetchRequest.fetchLimit = 1

        let count = (try? context.count(for: fetchRequest)) ?? 0
        guard count == 0 else { return }

        // 迁移 Courses（包含 KnowledgePoints 和 Questions）
        for course in SeedData.courses {
            _ = CourseEntity.fromCourse(course, context: context)
        }

        // 迁移 StudyTasks
        for task in SeedData.tasks {
            _ = StudyTaskEntity.fromStudyTask(task, context: context)
        }

        // 迁移 CareerEvents
        for event in SeedData.careerEvents {
            _ = CareerEventEntity.fromCareerEvent(event, context: context)
        }

        // 迁移 SprintPlanDays
        for day in SeedData.sprintPlanDays {
            _ = SprintPlanDayEntity.fromSprintPlanDay(day, context: context)
        }

        // 迁移 KnowledgeFlashcards
        for card in SeedData.flashcards {
            _ = KnowledgeFlashcardEntity.fromKnowledgeFlashcard(card, context: context)
        }

        // 尝试迁移 QuizAttempts（如果 SeedData 中有定义）
        // 如果 SeedData 没有 attempts 字段，请删除下面的循环
        // for attempt in SeedData.attempts {
        //     _ = QuizAttemptEntity.fromQuizAttempt(attempt, context: context)
        // }

        do {
            try context.save()
        } catch {
            print("Migration save error: \(error.localizedDescription)")
        }
    }
}
