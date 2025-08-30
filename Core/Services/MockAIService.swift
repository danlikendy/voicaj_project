import Foundation
import Combine

// MARK: - Mock AI Service
@preconcurrency
class MockAIService: AIServiceProtocol, ObservableObject {
    @Published var conversationHistory: [AIMessage] = []
    @Published var contextMemory: [String: Any] = [:]
    
    // MARK: - Protocol Conformance
    var nonisolatedConversationHistory: [AIMessage] {
        get async {
            await MainActor.run {
                return self.conversationHistory
            }
        }
    }
    
    var nonisolatedContextMemory: [String: Any] {
        get async {
            await MainActor.run {
                return self.contextMemory
            }
        }
    }
    
    func generateResponse(for message: String, context: [String]) async throws -> String {
        // Добавляем сообщение в историю
        let userMessage = AIMessage(role: "user", content: message)
        conversationHistory.append(userMessage)
        
        let response = generateContextualResponse(to: message)
        
        // Добавляем ответ в историю
        let aiMessage = AIMessage(role: "assistant", content: response)
        conversationHistory.append(aiMessage)
        
        return response
    }
    
    func analyzeVoiceRecording(_ transcript: String, audioURL: URL?) async throws -> VoiceAnalysisResult {
        // Простой анализ для Mock сервиса
        let extractedTasks = extractSimpleTasks(from: transcript)
        
        return VoiceAnalysisResult(
            tasks: extractedTasks,
            summary: "Mock AI анализ: Найдено \(extractedTasks.count) задач в записи",
            confidence: 0.7,
            audioURL: audioURL
        )
    }
    
    func createTaskFromMessage(_ message: String, context: [String]) async throws -> TaskCreationResult {
        if containsTaskKeywords(message) {
            let task = ExtractedTask(
                title: generateSimpleTitle(from: message),
                description: "Задача создана на основе сообщения: \(message)",
                priority: .medium,
                dueDate: nil,
                tags: ["чат"],
                confidence: 0.7
            )
            
            return TaskCreationResult(
                task: task,
                message: "Задача создана: \(task.title)",
                success: true
            )
        } else {
            return TaskCreationResult(
                task: nil,
                message: generateContextualResponse(to: message),
                success: false
            )
        }
    }
    
    func updateContextMemory(key: String, value: Any) async {
        contextMemory[key] = value
    }
    
    func getContextValue(for key: String) async -> Any? {
        return contextMemory[key]
    }
    
    func clearContextMemory() async {
        contextMemory.removeAll()
    }
    
    // MARK: - Helper Methods
    
    private func generateContextualResponse(to message: String) -> String {
        // Имитируем задержку AI
        let lowercased = message.lowercased()
        
        if lowercased.contains("привет") || lowercased.contains("здравствуй") {
            return "Привет! 👋 Я ваш AI ассистент. К сожалению, API ключ не настроен, поэтому я работаю в ограниченном режиме."
        }
        
        if lowercased.contains("помощь") || lowercased.contains("помоги") {
            return "Я готов помочь! Но для полного AI функционала нужно настроить API ключ. Сейчас я могу:\n\n• Отвечать на базовые вопросы\n• Создавать простые задачи\n• Давать советы по планированию"
        }
        
        if lowercased.contains("спасибо") || lowercased.contains("благодарю") {
            return "Рад был помочь! 😊 Если у вас появятся еще вопросы, обращайтесь!"
        }
        
        return "Интересный вопрос! 😊 К сожалению, без настройки API ключа я не могу дать полноценный AI ответ."
    }
    
    private func extractSimpleTasks(from transcript: String) -> [ExtractedTask] {
        let sentences = transcript.components(separatedBy: [".", "!", "?"])
        var tasks: [ExtractedTask] = []
        
        // Если транскрипция короткая, но содержит числа или повторения, создаем задачу
        if transcript.count < 10 && (transcript.contains("раз") || transcript.contains("два") || transcript.contains("три")) {
            let task = ExtractedTask(
                title: "Тестовая задача: \(transcript)",
                description: "Задача создана на основе короткой записи: \(transcript)",
                priority: .low,
                dueDate: nil,
                tags: ["тест", "голосовая-запись"],
                confidence: 0.5
            )
            tasks.append(task)
            return tasks
        }
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 5 && (containsTaskKeywords(trimmed) || isTaskLikePhrase(trimmed)) {
                let task = ExtractedTask(
                    title: generateSimpleTitle(from: trimmed),
                    description: trimmed,
                    priority: determinePriority(from: trimmed),
                    dueDate: extractDueDate(from: trimmed),
                    tags: generateTags(from: trimmed),
                    confidence: 0.6
                )
                tasks.append(task)
            }
        }
        
        return tasks
    }
    
    private func containsTaskKeywords(_ text: String) -> Bool {
        let keywords = ["нужно", "должен", "планирую", "хочу", "сделать", "завершить", "подготовить"]
        let lowercased = text.lowercased()
        return keywords.contains { lowercased.contains($0) }
    }
    
    private func generateSimpleTitle(from text: String) -> String {
        let words = text.components(separatedBy: " ")
        let stopWords = ["нужно", "должен", "планирую", "хочу", "сделать", "завершить", "подготовить"]
        
        let keyWords = words.filter { word in
            !stopWords.contains(word.lowercased()) && word.count > 2
        }
        
        return keyWords.prefix(5).joined(separator: " ")
    }
    
    private func isTaskLikePhrase(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let taskPatterns = [
            "завтра", "сегодня", "неделя", "месяц", "год",
            "купить", "сделать", "позвонить", "встретиться",
            "убрать", "починить", "изучить", "прочитать"
        ]
        return taskPatterns.contains { lowercased.contains($0) }
    }
    
    private func determinePriority(from text: String) -> TaskPriority {
        let lowercased = text.lowercased()
        if lowercased.contains("срочно") || lowercased.contains("важно") || lowercased.contains("критично") {
            return .high
        } else if lowercased.contains("не важно") || lowercased.contains("потом") {
            return .low
        }
        return .medium
    }
    
    private func extractDueDate(from text: String) -> Date? {
        let lowercased = text.lowercased()
        let calendar = Calendar.current
        let today = Date()
        
        if lowercased.contains("завтра") {
            return calendar.date(byAdding: .day, value: 1, to: today)
        } else if lowercased.contains("сегодня") {
            return calendar.date(bySettingHour: 23, minute: 59, second: 0, of: today)
        } else if lowercased.contains("неделя") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: today)
        }
        
        return nil
    }
    
    private func generateTags(from text: String) -> [String] {
        var tags = ["голосовая-запись"]
        let lowercased = text.lowercased()
        
        if lowercased.contains("купить") || lowercased.contains("магазин") {
            tags.append("покупки")
        }
        if lowercased.contains("звонок") || lowercased.contains("позвонить") {
            tags.append("звонки")
        }
        if lowercased.contains("встреча") || lowercased.contains("встретиться") {
            tags.append("встречи")
        }
        if lowercased.contains("уборка") || lowercased.contains("убрать") {
            tags.append("дом")
        }
        
        return tags
    }
}
