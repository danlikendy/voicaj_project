import Foundation
import Combine

class AIAnalysisService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var error: String?
    
    // MARK: - AI Analysis Pipeline
    
    func analyzeVoiceRecording(transcript: String, template: VoiceTemplate?) async -> AIAnalysisResult {
        await MainActor.run {
            isAnalyzing = true
            analysisProgress = 0.0
        }
        
        // Имитация AI анализа с прогрессом
        await simulateAnalysisProgress()
        
        let result = await performAnalysis(transcript: transcript, template: template)
        
        await MainActor.run {
            isAnalyzing = false
            analysisProgress = 1.0
        }
        
        return result
    }
    
    private func performAnalysis(transcript: String, template: VoiceTemplate?) async -> AIAnalysisResult {
        // Разбиваем транскрипт на предложения
        let sentences = transcript.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var tasks: [TaskItem] = []
        var mood: Mood = .calm
        
        for sentence in sentences {
            if let task = await extractTaskFromSentence(sentence, template: template) {
                tasks.append(task)
            }
        }
        
        // Анализируем настроение по общему тону
        mood = await analyzeMood(from: transcript)
        
        // Если задач не найдено, создаем заметку
        if tasks.isEmpty {
            let ideaTask = TaskItem(
                title: "Заметка",
                description: transcript,
                status: .idea,
                priority: .low,
                tags: ["заметка"]
            )
            tasks.append(ideaTask)
        }
        
        return AIAnalysisResult(
            tasks: tasks,
            mood: mood,
            transcript: transcript,
            confidence: calculateConfidence(for: tasks, transcript: transcript)
        )
    }
    
    private func extractTaskFromSentence(_ sentence: String, template: VoiceTemplate?) async -> TaskItem? {
        let lowercased = sentence.lowercased()
        
        // Определяем статус задачи на основе шаблона и контекста
        let status: TaskStatus
        let priority: TaskPriority
        
        // Анализируем по шаблону
        if let template = template {
            switch template {
            case .dailySummary:
                if lowercased.contains("сделал") || lowercased.contains("выполнил") || lowercased.contains("закончил") {
                    status = .completed
                    priority = .medium
                } else if lowercased.contains("не успел") || lowercased.contains("не смог") {
                    status = .stuck
                    priority = .high
                } else {
                    status = .idea
                    priority = .low
                }
            case .tomorrowPlan:
                status = .planned
                priority = lowercased.contains("важно") || lowercased.contains("срочно") ? .high : .medium
            case .weeklyPlan:
                status = .planned
                priority = .medium
            case .quickNote:
                status = .idea
                priority = .low
            case .meetingNotes:
                status = .planned
                priority = lowercased.contains("важно") || lowercased.contains("срочно") ? .high : .medium
            case .projectUpdate:
                if lowercased.contains("завершил") || lowercased.contains("сделал") {
                    status = .completed
                    priority = .medium
                } else if lowercased.contains("проблема") || lowercased.contains("застрял") {
                    status = .stuck
                    priority = .high
                } else {
                    status = .planned
                    priority = .medium
                }
            }
        } else {
            // Анализируем по контексту без шаблона
            if lowercased.contains("сделал") || lowercased.contains("выполнил") || lowercased.contains("закончил") {
                status = .completed
                priority = .medium
            } else if lowercased.contains("важно") || lowercased.contains("срочно") || lowercased.contains("критично") {
                status = .important
                priority = .high
            } else if lowercased.contains("завтра") || lowercased.contains("потом") || lowercased.contains("позже") {
                status = .planned
                priority = .medium
            } else if lowercased.contains("не успел") || lowercased.contains("не смог") || lowercased.contains("проблема") {
                status = .stuck
                priority = .high
            } else if lowercased.contains("идея") || lowercased.contains("мысль") || lowercased.contains("план") {
                status = .idea
                priority = .low
            } else {
                // По умолчанию - план
                status = .planned
                priority = .medium
            }
        }
        
        // Извлекаем дату
        let dueDate = extractDate(from: sentence)
        
        // Извлекаем теги
        let tags = extractTags(from: sentence)
        
        // Генерируем название задачи
        let title = generateTaskTitle(from: sentence, status: status)
        
        // Генерируем описание
        let description = generateTaskDescription(from: sentence, title: title)
        
        return TaskItem(
            title: title,
            description: description,
            status: status,
            priority: priority,
            dueDate: dueDate,
            tags: tags
        )
    }
    
    private func extractDate(from sentence: String) -> Date? {
        let lowercased = sentence.lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        if lowercased.contains("сегодня") {
            return calendar.startOfDay(for: now)
        } else if lowercased.contains("завтра") {
            return calendar.date(byAdding: .day, value: 1, to: now)
        } else if lowercased.contains("послезавтра") {
            return calendar.date(byAdding: .day, value: 2, to: now)
        } else if lowercased.contains("в понедельник") || lowercased.contains("в пн") {
            return getNextWeekday(2)
        } else if lowercased.contains("во вторник") || lowercased.contains("в вт") {
            return getNextWeekday(3)
        } else if lowercased.contains("в среду") || lowercased.contains("в ср") {
            return getNextWeekday(4)
        } else if lowercased.contains("в четверг") || lowercased.contains("в чт") {
            return getNextWeekday(5)
        } else if lowercased.contains("в пятницу") || lowercased.contains("в пт") {
            return getNextWeekday(6)
        } else if lowercased.contains("в субботу") || lowercased.contains("в сб") {
            return getNextWeekday(7)
        } else if lowercased.contains("в воскресенье") || lowercased.contains("в вс") {
            return getNextWeekday(1)
        }
        
        return nil
    }
    
    private func getNextWeekday(_ weekday: Int) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        
        var daysToAdd = weekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: now)
    }
    
    private func extractTags(from sentence: String) -> [String] {
        var tags: [String] = []
        let lowercased = sentence.lowercased()
        
        // Предопределенные категории
        let categories = [
            "работа": ["работа", "проект", "встреча", "звонок", "письмо"],
            "дом": ["дом", "уборка", "ремонт", "покупки", "быт"],
            "здоровье": ["здоровье", "врач", "спорт", "тренировка", "диета"],
            "семья": ["семья", "дети", "родители", "муж", "жена"],
            "обучение": ["обучение", "курс", "книга", "изучение", "практика"],
            "финансы": ["финансы", "деньги", "счет", "оплата", "бюджет"]
        ]
        
        for (category, keywords) in categories {
            if keywords.contains(where: { lowercased.contains($0) }) {
                tags.append(category)
            }
        }
        
        return tags
    }
    
    private func generateTaskTitle(from sentence: String, status: TaskStatus) -> String {
        // Упрощенная логика генерации названия
        let words = sentence.components(separatedBy: .whitespaces)
        let maxWords = status == .completed ? 3 : 4
        
        let titleWords = Array(words.prefix(maxWords))
        let title = titleWords.joined(separator: " ")
        
        // Ограничиваем длину
        return title.count > 60 ? String(title.prefix(57)) + "..." : title
    }
    
    private func generateTaskDescription(from sentence: String, title: String) -> String {
        // Если название совпадает с предложением, возвращаем пустое описание
        if sentence.lowercased().contains(title.lowercased()) && sentence.count < 100 {
            return ""
        }
        
        // Иначе возвращаем предложение как описание
        return sentence.count > 200 ? String(sentence.prefix(197)) + "..." : sentence
    }
    
    private func analyzeMood(from transcript: String) async -> Mood {
        let lowercased = transcript.lowercased()
        
        if lowercased.contains("отлично") || lowercased.contains("хорошо") || lowercased.contains("рад") {
            return .happy
        } else if lowercased.contains("устал") || lowercased.contains("утомлен") || lowercased.contains("нет сил") {
            return .tired
        } else if lowercased.contains("стресс") || lowercased.contains("нервы") || lowercased.contains("проблема") {
            return .stressed
        } else if lowercased.contains("энергия") || lowercased.contains("сила") || lowercased.contains("готов") {
            return .energetic
        } else if lowercased.contains("фокус") || lowercased.contains("концентрация") || lowercased.contains("внимание") {
            return .focused
        } else {
            return .calm
        }
    }
    
    private func calculateConfidence(for tasks: [TaskItem], transcript: String) -> Double {
        var confidence = 0.8 // Базовая уверенность
        
        // Увеличиваем уверенность за четкие указания
        if transcript.contains("завтра") || transcript.contains("сегодня") {
            confidence += 0.1
        }
        
        if transcript.contains("важно") || transcript.contains("срочно") {
            confidence += 0.1
        }
        
        // Уменьшаем уверенность за неопределенность
        if transcript.contains("может быть") || transcript.contains("возможно") {
            confidence -= 0.2
        }
        
        return min(max(confidence, 0.0), 1.0)
    }
    
    private func simulateAnalysisProgress() async {
        for i in 1...10 {
            // Простая задержка вместо Task.sleep
            await MainActor.run {
                analysisProgress = Double(i) / 10.0
            }
        }
    }
}

// MARK: - AI Analysis Result

struct AIAnalysisResult {
    let tasks: [TaskItem]
    let mood: Mood
    let transcript: String
    let confidence: Double
    
    var hasHighConfidence: Bool {
        confidence >= 0.7
    }
    
    var needsClarification: Bool {
        confidence < 0.5
    }
}
