import Foundation
import Combine

// MARK: - Local AI Service (Ollama)
@MainActor
@preconcurrency
class LocalAIService: AIServiceProtocol, ObservableObject {
    @Published var conversationHistory: [AIMessage] = []
    @Published var contextMemory: [String: Any] = [:]
    
    private let baseURL = "http://localhost:11434/api"
    private let modelName = "qwen2.5:7b"
    
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
    
    init() {
        loadContextMemory()
        print("🤖 Local AI Service (Ollama) инициализирован")
    }
    
    // MARK: - Chat Response Generation
    func generateResponse(for message: String, context: [String]) async throws -> String {
        let systemPrompt = await createSystemPrompt()
        
        // Добавляем сообщение в историю
        let userMessage = AIMessage(role: "user", content: message)
        conversationHistory.append(userMessage)
        
        let request = OllamaRequest(
            model: modelName,
            messages: [
                AIMessage(role: "system", content: systemPrompt),
                userMessage
            ],
            stream: false
        )
        
        let response = try await performOllamaRequest(request)
        
        // Добавляем ответ AI в историю
        let aiMessage = AIMessage(role: "assistant", content: response)
        conversationHistory.append(aiMessage)
        
        // Сохраняем контекст
        saveContextMemory()
        
        return response
    }
    
    // MARK: - Voice Recording Analysis
    func analyzeVoiceRecording(_ transcript: String, audioURL: URL?) async throws -> VoiceAnalysisResult {
        let systemPrompt = await createVoiceAnalysisPrompt()
        
        let request = OllamaRequest(
            model: modelName,
            messages: [
                AIMessage(role: "system", content: systemPrompt),
                AIMessage(role: "user", content: "Транскрипция: \(transcript)")
            ],
            stream: false
        )
        
        let response = try await performOllamaRequest(request)
        return await parseVoiceAnalysis(response, transcript: transcript)
    }
    
    // MARK: - Task Creation from Message
    func createTaskFromMessage(_ message: String, context: [String]) async throws -> TaskCreationResult {
        let systemPrompt = await createTaskCreationPrompt()
        
        let request = OllamaRequest(
            model: modelName,
            messages: [
                AIMessage(role: "system", content: systemPrompt),
                AIMessage(role: "user", content: message)
            ],
            stream: false
        )
        
        let response = try await performOllamaRequest(request)
        return await parseTaskCreation(response)
    }
    
    // MARK: - Context Memory Management
    func updateContextMemory(key: String, value: Any) async {
        contextMemory[key] = value
        saveContextMemory()
        print("🧠 Контекст обновлен: \(key) = \(value)")
    }
    
    func getContextValue(for key: String) async -> Any? {
        return contextMemory[key]
    }
    
    func clearContextMemory() async {
        contextMemory.removeAll()
        saveContextMemory()
        print("🧠 Контекст очищен")
    }
    
    // MARK: - Private Methods
    private func createSystemPrompt() async -> String {
        let address = await getContextValue(for: "user_address") as? String ?? "не указан"
        let preferences = await getContextValue(for: "user_preferences") as? [String] ?? []
        let taskCount = (await getContextValue(for: "task_history") as? [String])?.count ?? 0
        
        return """
        Ты - персональный AI ассистент для управления задачами и планирования. Твоя задача - помогать пользователю эффективно организовывать свою жизнь.
        
        КОНТЕКСТ ПОЛЬЗОВАТЕЛЯ:
        - Адрес: \(address)
        - Предпочтения: \(preferences.joined(separator: ", "))
        - Всего задач создано: \(taskCount)
        
        ИСТОРИЯ РАЗГОВОРА:
        \(conversationHistory.suffix(10).map { "\($0.role): \($0.content)" }.joined(separator: "\n"))
        
        ТВОЯ ЛИЧНОСТЬ:
        - Дружелюбный и понимающий помощник
        - Эксперт по продуктивности и тайм-менеджменту
        - Всегда готов предложить практические решения
        - Адаптируешься под стиль общения пользователя
        
        ПРАВИЛА ОБЩЕНИЯ:
        1. Отвечай естественно и разнообразно - избегай шаблонных фраз
        2. Используй контекст для персонализации каждого ответа
        3. Задавай уточняющие вопросы когда нужно
        4. Предлагай конкретные действия и решения
        5. Если нужно создать задачу, используй формат: [TASK: название|описание|приоритет|теги|срок|адрес]
        6. Помни все детали из разговора и используй их
        7. Будь проактивным - предлагай улучшения и оптимизации
        
        СТИЛЬ ОТВЕТОВ:
        - Вариативность в формулировках
        - Эмодзи для эмоциональности (но не перебор)
        - Конкретные советы и рекомендации
        - Учет индивидуальных особенностей пользователя
        """
    }
    
    private func createVoiceAnalysisPrompt() async -> String {
        let address = await getContextValue(for: "user_address") as? String ?? "не указан"
        let previousTasks = await getContextValue(for: "task_history") as? [String] ?? []
        
        return """
        Ты - эксперт по анализу голосовых записей и извлечению задач. Проанализируй транскрипцию и создай структурированные задачи.
        
        КОНТЕКСТ ПОЛЬЗОВАТЕЛЯ:
        - Адрес: \(address)
        - Предыдущие задачи: \(previousTasks.joined(separator: ", "))
        
        ЗАДАЧА:
        Извлеки ВСЕ задачи из голосовой записи и создай для каждой:
        1. КРАТКОЕ НАЗВАНИЕ (2-5 слов, понятное и конкретное)
        2. РАСШИРЕННОЕ ОПИСАНИЕ (детальное объяснение с контекстом)
        3. ПРИОРИТЕТ (высокий/средний/низкий на основе важности и срочности)
        4. ТЕГИ (релевантные категории через запятую)
        5. СРОК (если упоминается, иначе "не указан")
        6. АДРЕС (если упоминается, иначе используй контекст)
        
        ПРАВИЛА:
        - Если в записи нет четких задач, создай одну общую задачу
        - Название должно быть кратким и понятным
        - Описание должно содержать все важные детали
        - Приоритет определяй по важности и срочности
        - Теги должны отражать категорию задачи
        - Если упоминается адрес, обнови контекст
        
        ФОРМАТ ОТВЕТА (ОБЯЗАТЕЛЬНО):
        [TASK: название|описание|приоритет|теги|срок|адрес]
        [TASK: название2|описание2|приоритет2|теги2|срок2|адрес2]
        
        КОНТЕКСТНЫЕ ОБНОВЛЕНИЯ (если нужно):
        [CONTEXT: ключ=значение]
        """
    }
    
    private func createTaskCreationPrompt() async -> String {
        let address = await getContextValue(for: "user_address") as? String ?? "не указан"
        
        return """
        Создай задачу на основе сообщения пользователя.
        
        КОНТЕКСТ:
        - Адрес: \(address)
        - История разговора: \(conversationHistory.suffix(5).map { $0.content }.joined(separator: "\n"))
        
        ПРАВИЛА:
        1. Используй контекст для персонализации
        2. Если упоминается адрес, обнови контекст
        3. Создай детальное описание
        4. Определи приоритет и теги
        
        ФОРМАТ ОТВЕТА:
        [TASK: название|описание|приоритет|теги|срок|адрес]
        [CONTEXT: ключ=значение] (если нужно обновить)
        """
    }
    
    private func performOllamaRequest(_ request: OllamaRequest) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat") else {
            throw AIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIError.apiError("Ollama API error: \(httpResponse.statusCode)")
        }
        
        let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return ollamaResponse.message.content
    }
    
    private func parseVoiceAnalysis(_ response: String, transcript: String) async -> VoiceAnalysisResult {
        let tasks = extractTasksFromResponse(response)
        let contextUpdates = extractContextUpdates(response)
        
        // Применяем обновления контекста
        for update in contextUpdates {
            let components = update.components(separatedBy: "=")
            if components.count == 2 {
                await updateContextMemory(key: components[0], value: components[1])
            }
        }
        
        return VoiceAnalysisResult(
            tasks: tasks,
            summary: response,
            confidence: 0.9,
            audioURL: nil
        )
    }
    
    private func parseTaskCreation(_ response: String) async -> TaskCreationResult {
        let tasks = extractTasksFromResponse(response)
        let contextUpdates = extractContextUpdates(response)
        
        // Применяем обновления контекста
        for update in contextUpdates {
            let components = update.components(separatedBy: "=")
            if components.count == 2 {
                await updateContextMemory(key: components[0], value: components[1])
            }
        }
        
        return TaskCreationResult(
            task: tasks.first,
            message: response,
            success: !tasks.isEmpty
        )
    }
    
    private func extractTasksFromResponse(_ response: String) -> [ExtractedTask] {
        let taskPattern = "\\[TASK: ([^|]+)\\|([^|]+)\\|([^|]+)\\|([^|]+)\\|([^|]+)\\|([^\\]]+)\\]"
        let regex = try? NSRegularExpression(pattern: taskPattern)
        
        guard let regex = regex else { return [] }
        
        let range = NSRange(response.startIndex..<response.endIndex, in: response)
        let matches = regex.matches(in: response, range: range)
        
        return matches.compactMap { match in
            guard match.numberOfRanges == 7 else { return nil }
            
            let title = extractString(from: response, range: match.range(at: 1))
            let description = extractString(from: response, range: match.range(at: 2))
            let priority = extractString(from: response, range: match.range(at: 3))
            let tags = extractString(from: response, range: match.range(at: 4))
            let dueDate = extractString(from: response, range: match.range(at: 5))
            let address = extractString(from: response, range: match.range(at: 6))
            
            return ExtractedTask(
                title: title,
                description: description,
                priority: parsePriority(priority),
                dueDate: parseDueDate(dueDate),
                tags: parseTags(tags),
                confidence: 0.9,
                address: address.isEmpty ? nil : address
            )
        }
    }
    
    private func extractContextUpdates(_ response: String) -> [String] {
        let contextPattern = "\\[CONTEXT: ([^\\]]+)\\]"
        let regex = try? NSRegularExpression(pattern: contextPattern)
        
        guard let regex = regex else { return [] }
        
        let range = NSRange(response.startIndex..<response.endIndex, in: response)
        let matches = regex.matches(in: response, range: range)
        
        return matches.compactMap { match in
            guard match.numberOfRanges == 2 else { return nil }
            return extractString(from: response, range: match.range(at: 1))
        }
    }
    
    private func extractString(from text: String, range: NSRange) -> String {
        guard let range = Range(range, in: text) else { return "" }
        return String(text[range]).trimmingCharacters(in: .whitespaces)
    }
    
    private func parsePriority(_ priority: String) -> TaskPriority {
        let lowercased = priority.lowercased()
        if lowercased.contains("высок") || lowercased.contains("срочн") { return .high }
        if lowercased.contains("низк") { return .low }
        return .medium
    }
    
    private func parseDueDate(_ dueDate: String) -> Date? {
        let lowercased = dueDate.lowercased()
        let calendar = Calendar.current
        let today = Date()
        
        if lowercased.contains("сегодня") { return today }
        if lowercased.contains("завтра") { return calendar.date(byAdding: .day, value: 1, to: today) }
        if lowercased.contains("неделе") { return calendar.date(byAdding: .weekOfYear, value: 1, to: today) }
        
        return nil
    }
    
    private func parseTags(_ tags: String) -> [String] {
        return tags.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    private func saveContextMemory() {
        if let data = try? JSONSerialization.data(withJSONObject: contextMemory) {
            UserDefaults.standard.set(data, forKey: "ai_context_memory")
        }
    }
    
    private func loadContextMemory() {
        if let data = UserDefaults.standard.data(forKey: "ai_context_memory"),
           let memory = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            contextMemory = memory
        }
    }
}

// MARK: - Ollama Models
struct OllamaRequest: Codable {
    let model: String
    let messages: [AIMessage]
    let stream: Bool
}

struct OllamaResponse: Codable {
    let message: AIMessage
    let done: Bool
}
