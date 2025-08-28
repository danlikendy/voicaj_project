import Foundation

struct VoiceRecord: Identifiable, Codable {
    let id: UUID
    var audioURL: URL
    var transcript: String
    var duration: TimeInterval
    var mood: Mood?
    var createdAt: Date
    var tasks: [UUID] // Ссылки на созданные задачи
    var isPrivate: Bool
    var template: VoiceTemplate?
    
    init(
        id: UUID = UUID(),
        audioURL: URL,
        transcript: String = "",
        duration: TimeInterval = 0,
        mood: Mood? = nil,
        createdAt: Date = Date(),
        tasks: [UUID] = [],
        isPrivate: Bool = false,
        template: VoiceTemplate? = nil
    ) {
        self.id = id
        self.audioURL = audioURL
        self.transcript = transcript
        self.duration = duration
        self.mood = mood
        self.createdAt = createdAt
        self.tasks = tasks
        self.isPrivate = isPrivate
        self.template = template
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
