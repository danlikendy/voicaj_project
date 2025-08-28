import Foundation
import SwiftUI

enum TaskStatus: String, CaseIterable, Codable {
    case completed = "completed"      // Свершилось
    case important = "important"      // Важное
    case planned = "planned"          // В планах
    case stuck = "stuck"              // Застряло
    case paused = "paused"            // На паузе
    case waiting = "waiting"          // Ожидает ответа
    case delegated = "delegated"      // Делегировано
    case recurring = "recurring"      // Повторяющееся
    case idea = "idea"                // Идеи на потом
    
    var displayName: String {
        switch self {
        case .completed: return "Свершилось"
        case .important: return "Важное"
        case .planned: return "В планах"
        case .stuck: return "Застряло"
        case .paused: return "На паузе"
        case .waiting: return "Ожидает ответа"
        case .delegated: return "Делегировано"
        case .recurring: return "Повторяющееся"
        case .idea: return "Идеи на потом"
        }
    }
    
    var title: String {
        return displayName
    }
    
    var color: String {
        switch self {
        case .completed: return "mossGreen"
        case .important: return "orchidPurple"
        case .planned: return "cornflowerBlue"
        case .stuck: return "terracotta"
        case .paused: return "honeyGold"
        case .waiting: return "tealMist"
        case .delegated: return "olive"
        case .recurring: return "mint"
        case .idea: return "warmGrey"
        }
    }
    
    var colorValue: Color {
        switch self {
        case .completed: return .mossGreen
        case .important: return .orchidPurple
        case .planned: return .cornflowerBlue
        case .stuck: return .terracotta
        case .paused: return .honeyGold
        case .waiting: return .tealMist
        case .delegated: return .olive
        case .recurring: return .mint
        case .idea: return .warmGrey
        }
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Низкий"
        case .medium: return "Средний"
        case .high: return "Высокий"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "red"
        }
    }
}

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var status: TaskStatus
    var priority: TaskPriority
    var dueDate: Date?
    var tags: [String]
    var isPrivate: Bool
    var audioURL: URL?
    var transcript: String?
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var parentTaskId: UUID?
    var subtasks: [UUID]
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        status: TaskStatus = .planned,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        tags: [String] = [],
        isPrivate: Bool = false,
        audioURL: URL? = nil,
        transcript: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        parentTaskId: UUID? = nil,
        subtasks: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.tags = tags
        self.isPrivate = isPrivate
        self.audioURL = audioURL
        self.transcript = transcript
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.parentTaskId = parentTaskId
        self.subtasks = subtasks
    }
}

// MARK: - TaskItem Extensions
extension TaskItem {
    var isCompleted: Bool {
        status == .completed
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && !isCompleted
    }
    
    var formattedDueDate: String {
        guard let dueDate = dueDate else { return "Без срока" }
        
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(dueDate) {
            formatter.timeStyle = .short
            return "Сегодня, \(formatter.string(from: dueDate))"
        } else if Calendar.current.isDateInTomorrow(dueDate) {
            formatter.timeStyle = .short
            return "Завтра, \(formatter.string(from: dueDate))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: dueDate)
        }
    }
}
