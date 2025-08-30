import Foundation

struct VoiceRecord: Identifiable, Codable {
    let id: UUID
    let audioURL: URL?
    let transcript: String
    let duration: TimeInterval
    let createdAt: Date
    var aiAnalysis: AIAnalysis?
    
    init(transcript: String, duration: TimeInterval, audioURL: URL? = nil) {
        self.id = UUID()
        self.transcript = transcript
        self.duration = duration
        self.audioURL = audioURL
        self.createdAt = Date()
        self.aiAnalysis = nil
    }
}

struct AIAnalysis: Codable {
    let extractedTasks: [ExtractedTask]
    let summary: String
    let sentiment: String
    let priority: String
    let tags: [String]
    let createdAt: Date
    
    init(extractedTasks: [ExtractedTask], summary: String, sentiment: String, priority: String, tags: [String]) {
        self.extractedTasks = extractedTasks
        self.summary = summary
        self.sentiment = sentiment
        self.priority = priority
        self.tags = tags
        self.createdAt = Date()
    }
}

struct ExtractedTask: Codable {
    let title: String
    let description: String?
    let priority: TaskPriority
    let dueDate: Date?
    let tags: [String]
    let confidence: Double // Уверенность AI в извлечении задачи (0.0 - 1.0)
    let address: String? // Адрес для выполнения задачи
    
    init(title: String, description: String? = nil, priority: TaskPriority = .medium, dueDate: Date? = nil, tags: [String] = [], confidence: Double = 0.8, address: String? = nil) {
        self.title = title
        self.description = description
        self.priority = priority
        self.dueDate = dueDate
        self.tags = tags
        self.confidence = confidence
        self.address = address
    }
}

enum Mood: String, CaseIterable, Codable {
    case calm = "calm"           // Спокойный
    case energetic = "energetic" // Энергичный
    case stressed = "stressed"   // Напряженный
    case happy = "happy"         // Радостный
    case tired = "tired"         // Уставший
    case focused = "focused"     // Сосредоточенный
    
    var displayName: String {
        switch self {
        case .calm: return "Спокойный"
        case .energetic: return "Энергичный"
        case .stressed: return "Напряженный"
        case .happy: return "Радостный"
        case .tired: return "Уставший"
        case .focused: return "Сосредоточенный"
        }
    }
    
    var emoji: String {
        switch self {
        case .calm: return "😌"
        case .energetic: return "💪"
        case .stressed: return "😰"
        case .happy: return "😊"
        case .tired: return "😴"
        case .focused: return "🎯"
        }
    }
    
    var color: String {
        switch self {
        case .calm: return "mossGreen"
        case .energetic: return "honeyGold"
        case .stressed: return "terracotta"
        case .happy: return "mint"
        case .tired: return "warmGrey"
        case .focused: return "cornflowerBlue"
        }
    }
}

enum VoiceTemplate: String, CaseIterable, Codable {
    case dailySummary = "dailySummary"     // Итог дня
    case tomorrowPlan = "tomorrowPlan"     // План на завтра
    case weeklyPlan = "weeklyPlan"         // План недели
    case quickNote = "quickNote"           // Быстрая заметка
    case meetingNotes = "meetingNotes"     // Заметки встречи
    case projectUpdate = "projectUpdate"   // Обновление проекта
    
    var displayName: String {
        switch self {
        case .dailySummary: return "Итог дня"
        case .tomorrowPlan: return "План на завтра"
        case .weeklyPlan: return "План недели"
        case .quickNote: return "Быстрая заметка"
        case .meetingNotes: return "Заметки встречи"
        case .projectUpdate: return "Обновление проекта"
        }
    }
    
    var description: String {
        switch self {
        case .dailySummary: return "Что сделал сегодня, что не успел"
        case .tomorrowPlan: return "Планы и задачи на завтра"
        case .weeklyPlan: return "Цели и планы на неделю"
        case .quickNote: return "Быстрая запись мысли или идеи"
        case .meetingNotes: return "Заметки с встречи или совещания"
        case .projectUpdate: return "Прогресс и обновления проекта"
        }
    }
    
    var icon: String {
        switch self {
        case .dailySummary: return "sun.max.fill"
        case .tomorrowPlan: return "calendar.badge.plus"
        case .weeklyPlan: return "calendar.badge.clock"
        case .quickNote: return "note.text"
        case .meetingNotes: return "person.2.fill"
        case .projectUpdate: return "folder.fill"
        }
    }
}

// MARK: - VoiceRecord Extensions
extension VoiceRecord {
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(createdAt)
    }
}
