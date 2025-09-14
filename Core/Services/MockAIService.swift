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
        // Имитируем задержку AI анализа
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 секунды
        
        let extractedTasks = extractAdvancedTasks(from: transcript)
        
        return VoiceAnalysisResult(
            tasks: extractedTasks,
            summary: "🤖 AI анализ завершен! Найдено \(extractedTasks.count) задач из голосовой записи.",
            confidence: 0.85,
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
        let lowercased = message.lowercased()
        
        // Приветствие
        if lowercased.contains("привет") || lowercased.contains("здравствуй") || lowercased.contains("hi") || lowercased.contains("hello") {
            let responses = [
                "Привет! 👋 Я ваш AI ассистент. Готов помочь с задачами и планированием!",
                "Здравствуйте! 🤖 Я здесь, чтобы помочь вам организовать дела.",
                "Привет! 😊 Давайте вместе разберем ваши задачи и планы."
            ]
            return responses.randomElement() ?? responses[0]
        }
        
        // Помощь
        if lowercased.contains("помощь") || lowercased.contains("помоги") || lowercased.contains("help") {
            let helpResponses = [
                "Конечно помогу! 🚀 Я могу:\n\n• Создавать задачи из ваших сообщений\n• Анализировать голосовые записи\n• Давать советы по планированию\n• Помогать с организацией дел",
                "Рад помочь! 💡 Вот что я умею:\n\n• Превращать ваши идеи в структурированные задачи\n• Анализировать приоритеты\n• Предлагать оптимальные сроки выполнения\n• Создавать релевантные теги",
                "Помогу с удовольствием! 🤝 Я специализируюсь на:\n\n• Управлении задачами\n• Планировании времени\n• Анализе приоритетов\n• Организации рабочего процесса"
            ]
            return helpResponses.randomElement() ?? helpResponses[0]
        }
        
        // Благодарность
        if lowercased.contains("спасибо") || lowercased.contains("благодарю") || lowercased.contains("thanks") {
            let thanksResponses = [
                "Рад был помочь! 😊 Если у вас появятся еще вопросы, обращайтесь!",
                "Пожалуйста! 🤝 Всегда готов помочь с задачами и планированием.",
                "Не за что! 😄 Обращайтесь, если понадобится еще помощь."
            ]
            return thanksResponses.randomElement() ?? thanksResponses[0]
        }
        
        // Задачи
        if lowercased.contains("задача") || lowercased.contains("task") || lowercased.contains("дела") {
            let taskResponses = [
                "Отлично! 📝 Расскажите подробнее о вашей задаче, и я помогу ее структурировать.",
                "Понял! 🎯 Опишите задачу, и я создам для нее план с приоритетами и сроками.",
                "Хорошо! ✅ Давайте разберем вашу задачу по пунктам и определим оптимальный подход."
            ]
            return taskResponses.randomElement() ?? taskResponses[0]
        }
        
        // Время и планирование
        if lowercased.contains("время") || lowercased.contains("план") || lowercased.contains("расписание") {
            let timeResponses = [
                "Время - наш главный ресурс! ⏰ Давайте составим эффективный план действий.",
                "Планирование - ключ к успеху! 📅 Расскажите, что нужно организовать.",
                "Отличная идея заняться планированием! 🗓️ Я помогу структурировать ваши дела."
            ]
            return timeResponses.randomElement() ?? timeResponses[0]
        }
        
        // Общие ответы
        let defaultResponses = [
            "Интересно! 😊 Расскажите подробнее, и я помогу разобраться с вашим вопросом.",
            "Понял ваш запрос! 🤔 Давайте обсудим это детальнее.",
            "Хороший вопрос! 💭 Я готов помочь вам найти решение.",
            "Отлично! 🎯 Давайте разберем это пошагово.",
            "Понятно! 👍 Расскажите больше деталей, и я дам рекомендации."
        ]
        return defaultResponses.randomElement() ?? defaultResponses[0]
    }
    
    private func extractAdvancedTasks(from transcript: String) -> [ExtractedTask] {
        var tasks: [ExtractedTask] = []
        let lowercased = transcript.lowercased()
        
        // Проверяем, есть ли несколько задач в одной записи
        if lowercased.contains("также") || lowercased.contains("вторую") || lowercased.contains("вторая") {
            // Создаем несколько задач из одной записи
            
            // Задача 1: Покупки
            if lowercased.contains("продукт") || lowercased.contains("магазин") || lowercased.contains("купить") {
                let task1 = ExtractedTask(
                    title: "Купить продукты",
                    description: "Сходить в магазин и купить продукты до конца рабочего дня",
                    priority: .low,
                    dueDate: extractAdvancedDueDate(from: transcript),
                    tags: ["покупки", "магазин", "завтра"],
                    confidence: 0.9
                )
                tasks.append(task1)
            }
            
            // Задача 2: Работа
            if lowercased.contains("работа") || lowercased.contains("важную задачу") {
                let task2 = ExtractedTask(
                    title: "Важная рабочая задача",
                    description: "Выполнить важную задачу по работе",
                    priority: .high,
                    dueDate: extractAdvancedDueDateForSecondTask(from: transcript),
                    tags: ["работа", "важно", "послезавтра"],
                    confidence: 0.9
                )
                tasks.append(task2)
            }
        } else {
            // Обычная обработка одной задачи
            let sentences = transcript.components(separatedBy: [".", "!", "?"])
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            // Если транскрипция короткая, создаем одну задачу
            if transcript.count < 20 {
                let task = ExtractedTask(
                    title: generateAdvancedTitle(from: transcript),
                    description: generateAdvancedDescription(from: transcript),
                    priority: determineAdvancedPriority(from: transcript),
                    dueDate: extractAdvancedDueDate(from: transcript),
                    tags: generateAdvancedTags(from: transcript),
                    confidence: 0.8
                )
                tasks.append(task)
                return tasks
            }
            
            // Анализируем каждое предложение на предмет задач
            for sentence in sentences {
                if isTaskSentence(sentence) {
                    let task = ExtractedTask(
                        title: generateAdvancedTitle(from: sentence),
                        description: generateAdvancedDescription(from: sentence),
                        priority: determineAdvancedPriority(from: sentence),
                        dueDate: extractAdvancedDueDate(from: sentence),
                        tags: generateAdvancedTags(from: sentence),
                        confidence: 0.9
                    )
                    tasks.append(task)
                }
            }
            
            // Если не нашли задач, создаем общую
            if tasks.isEmpty {
                let task = ExtractedTask(
                    title: generateAdvancedTitle(from: transcript),
                    description: generateAdvancedDescription(from: transcript),
                    priority: .medium,
                    dueDate: extractAdvancedDueDate(from: transcript),
                    tags: generateAdvancedTags(from: transcript),
                    confidence: 0.7
                )
                tasks.append(task)
            }
        }
        
        return tasks
    }
    
    private func extractSimpleTasks(from transcript: String) -> [ExtractedTask] {
        let sentences = transcript.components(separatedBy: [".", "!", "?"])
        var tasks: [ExtractedTask] = []
        
        // Если транскрипция короткая, создаем общую задачу
        if transcript.count < 15 {
            let task = ExtractedTask(
                title: generateSimpleTitle(from: transcript),
                description: "Голосовая запись: \(transcript)",
                priority: .medium,
                dueDate: nil,
                tags: ["голосовая-запись", "быстрая-задача"],
                confidence: 0.7
            )
            tasks.append(task)
            return tasks
        }
        
        // Анализируем каждое предложение
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 5 {
                let task = ExtractedTask(
                    title: generateSimpleTitle(from: trimmed),
                    description: trimmed,
                    priority: determinePriority(from: trimmed),
                    dueDate: extractDueDate(from: trimmed),
                    tags: generateTags(from: trimmed),
                    confidence: 0.8
                )
                tasks.append(task)
            }
        }
        
        // Если не нашли задач, создаем общую
        if tasks.isEmpty {
            let task = ExtractedTask(
                title: "Запись от \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))",
                description: transcript,
                priority: .medium,
                dueDate: nil,
                tags: ["голосовая-запись", "заметка"],
                confidence: 0.6
            )
            tasks.append(task)
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
        let stopWords = ["нужно", "должен", "планирую", "хочу", "сделать", "завершить", "подготовить", "что", "как", "где", "когда", "зачем", "почему"]
        
        let keyWords = words.filter { word in
            let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            return !stopWords.contains(cleanWord) && cleanWord.count > 2
        }
        
        let title = keyWords.prefix(4).joined(separator: " ")
        return title.isEmpty ? "Голосовая заметка" : title
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
    
    // MARK: - Advanced Analysis Methods
    
    private func isTaskSentence(_ sentence: String) -> Bool {
        let lowercased = sentence.lowercased()
        let taskKeywords = [
            "нужно", "должен", "планирую", "хочу", "сделать", "завершить", "подготовить",
            "завтра", "сегодня", "неделя", "месяц", "купить", "позвонить", "встретиться",
            "убрать", "починить", "изучить", "прочитать", "написать", "отправить"
        ]
        return taskKeywords.contains { lowercased.contains($0) }
    }
    
    private func generateAdvancedTitle(from text: String) -> String {
        let lowercased = text.lowercased()
        
        // Специальные случаи для деканата/учебы
        if lowercased.contains("деканат") {
            return "Сходить в деканат"
        }
        if lowercased.contains("вуз") || lowercased.contains("университет") {
            return "Дела в университете"
        }
        if lowercased.contains("учеба") {
            return "Учебные дела"
        }
        
        // Специальные случаи для покупок
        if lowercased.contains("магазин") && lowercased.contains("купить") {
            return "Покупки в магазине"
        }
        if lowercased.contains("купить") && lowercased.contains("продукт") {
            return "Купить продукты"
        }
        if lowercased.contains("сходить") && lowercased.contains("магазин") {
            return "Сходить в магазин"
        }
        
        // Специальные случаи для работы
        if lowercased.contains("рабочего дня") || lowercased.contains("работа") {
            return "Рабочие задачи"
        }
        
        // Специальные случаи для звонков
        if lowercased.contains("позвонить") || lowercased.contains("звонок") {
            return "Сделать звонок"
        }
        
        // Специальные случаи для времени
        if lowercased.contains("2 часов дня") || lowercased.contains("до 2 часов") {
            return "Задача на 14:00"
        }
        if lowercased.contains("часов дня") {
            return "Задача на дневное время"
        }
        
        // Общая обработка - ищем ключевые слова
        if lowercased.contains("сходил") || lowercased.contains("сходить") {
            return "Сходить по делам"
        }
        if lowercased.contains("завтра") {
            return "Задача на завтра"
        }
        
        // Если ничего не подошло, создаем осмысленное название
        return "Важная задача"
    }
    
    private func generateAdvancedDescription(from text: String) -> String {
        // Создаем более детальное описание на основе контекста
        let lowercased = text.lowercased()
        
        // Специальные случаи для деканата
        if lowercased.contains("деканат") {
            return "Посетить деканат университета для решения учебных вопросов"
        }
        
        // Специальные случаи для покупок
        if lowercased.contains("магазин") && lowercased.contains("продукт") {
            return "Сходить в магазин и купить необходимые продукты"
        }
        
        // Специальные случаи для работы
        if lowercased.contains("работа") && lowercased.contains("важн") {
            return "Выполнить важную рабочую задачу"
        }
        
        // Специальные случаи для времени
        if lowercased.contains("2 часов дня") || lowercased.contains("до 2 часов") {
            return "Важная задача, которую необходимо выполнить до 14:00 завтра. Требует срочного внимания и планирования времени."
        }
        
        // Общие случаи с детальным описанием
        if lowercased.contains("завтра") && lowercased.contains("сходил") {
            return "Запланированная задача на завтра, требующая выхода из дома. Необходимо заранее спланировать маршрут и время выполнения."
        } else if lowercased.contains("завтра") {
            return "Важная задача на завтра, требующая внимания и планирования. Рекомендуется выполнить в первой половине дня."
        } else if lowercased.contains("сегодня") {
            return "Срочная задача на сегодня, требующая немедленного выполнения. Приоритет - высокий."
        } else if lowercased.contains("неделя") {
            return "Задача на эту неделю, требующая планирования и регулярного контроля выполнения."
        } else if lowercased.contains("важно") || lowercased.contains("срочно") {
            return "Критически важная задача, требующая максимального внимания и быстрого выполнения."
        } else {
            return "Планируемая задача, требующая внимания и своевременного выполнения."
        }
    }
    
    private func determineAdvancedPriority(from text: String) -> TaskPriority {
        let lowercased = text.lowercased()
        
        if lowercased.contains("срочно") || lowercased.contains("критично") || lowercased.contains("сегодня") {
            return .high
        } else if lowercased.contains("важно") || lowercased.contains("важн") || lowercased.contains("деканат") {
            // Деканат и важные дела - высокий приоритет
            return .high
        } else if lowercased.contains("2 часов дня") || lowercased.contains("до 2 часов") {
            // Задачи с конкретным временем - высокий приоритет
            return .high
        } else if lowercased.contains("завтра") && lowercased.contains("сходил") {
            // Задачи на завтра с выходом - высокий приоритет
            return .high
        } else if lowercased.contains("не важно") || lowercased.contains("потом") || lowercased.contains("когда-нибудь") {
            return .low
        } else if lowercased.contains("рабочего дня") {
            // Рабочие задачи обычно средний приоритет
            return .medium
        } else if lowercased.contains("магазин") || lowercased.contains("покупки") {
            // Покупки обычно низкий приоритет
            return .low
        }
        
        return .high // По умолчанию высокий приоритет для важных задач
    }
    
    private func extractAdvancedDueDate(from text: String) -> Date? {
        let lowercased = text.lowercased()
        let calendar = Calendar.current
        let today = Date()
        
        if lowercased.contains("сегодня") {
            return today
        } else if lowercased.contains("завтра") || lowercased.contains("завтрашнего") {
            // Если упоминается "2 часов дня" или "до 2 часов", ставим на 14:00 завтра
            if lowercased.contains("2 часов дня") || lowercased.contains("до 2 часов") {
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                components.hour = 14
                components.minute = 0
                return calendar.date(from: components)
            }
            // Если упоминается "рабочего дня" или "конца дня", ставим на 18:00 завтра
            else if lowercased.contains("рабочего дня") || lowercased.contains("конца рабочего дня") || 
               lowercased.contains("конца дня") || lowercased.contains("до конца") {
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                components.hour = 18
                components.minute = 0
                return calendar.date(from: components)
            }
            // Иначе обычный завтра
            return calendar.date(byAdding: .day, value: 1, to: today)
        } else if lowercased.contains("неделе") || lowercased.contains("на этой неделе") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: today)
        } else if lowercased.contains("следующей неделе") {
            return calendar.date(byAdding: .weekOfYear, value: 2, to: today)
        }
        
        return nil
    }
    
    private func extractAdvancedDueDateForSecondTask(from text: String) -> Date? {
        let lowercased = text.lowercased()
        let calendar = Calendar.current
        let today = Date()
        
        if lowercased.contains("послезавтра") || lowercased.contains("через день") {
            return calendar.date(byAdding: .day, value: 2, to: today)
        } else if lowercased.contains("через неделю") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: today)
        }
        
        // По умолчанию через 2 дня
        return calendar.date(byAdding: .day, value: 2, to: today)
    }
    
    private func generateAdvancedTags(from text: String) -> [String] {
        let lowercased = text.lowercased()
        var tags: [String] = []
        
        // Категории задач
        if lowercased.contains("покуп") || lowercased.contains("магазин") || lowercased.contains("купить") {
            tags.append("покупки")
        }
        if lowercased.contains("работа") || lowercased.contains("офис") || lowercased.contains("собеседование") {
            tags.append("работа")
        }
        if lowercased.contains("здоровье") || lowercased.contains("врач") || lowercased.contains("записаться") {
            tags.append("здоровье")
        }
        if lowercased.contains("семья") || lowercased.contains("мама") || lowercased.contains("папа") || lowercased.contains("позвонить") {
            tags.append("семья")
        }
        if lowercased.contains("учеба") || lowercased.contains("изучить") || lowercased.contains("прочитать") {
            tags.append("учеба")
        }
        if lowercased.contains("дом") || lowercased.contains("убрать") || lowercased.contains("починить") {
            tags.append("дом")
        }
        
        // Временные теги
        if lowercased.contains("завтра") {
            tags.append("завтра")
        }
        if lowercased.contains("сегодня") {
            tags.append("сегодня")
        }
        if lowercased.contains("неделя") {
            tags.append("неделя")
        }
        
        // Приоритетные теги
        if lowercased.contains("важно") || lowercased.contains("срочно") {
            tags.append("важно")
        }
        
        return tags.isEmpty ? ["голосовая-запись", "задача"] : tags
    }
}
