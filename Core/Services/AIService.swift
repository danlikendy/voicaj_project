import Foundation
import Combine

// MARK: - AI Service Protocol
@preconcurrency
protocol AIServiceProtocol: ObservableObject {
    var conversationHistory: [AIMessage] { get async }
    var contextMemory: [String: Any] { get async }
    
    func generateResponse(for message: String, context: [String]) async throws -> String
    func analyzeVoiceRecording(_ transcript: String, audioURL: URL?) async throws -> VoiceAnalysisResult
    func createTaskFromMessage(_ message: String, context: [String]) async throws -> TaskCreationResult
    func updateContextMemory(key: String, value: Any) async
    func getContextValue(for key: String) async -> Any?
    func clearContextMemory() async
}

// MARK: - AI Service Implementation
@MainActor
@preconcurrency
class AIService: AIServiceProtocol, ObservableObject {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    // MARK: - Published Properties
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
    
    // MARK: - Models
    private let defaultModel = "gpt-4o-mini" // GPT-4o mini для баланса цена/качество
    private let advancedModel = "gpt-4o" // GPT-4o для сложных задач
    
    // MARK: - Context Keys
    private let userAddressKey = "user_address"
    private let userPreferencesKey = "user_preferences"
    private let taskHistoryKey = "task_history"
    private let voiceRecordingsKey = "voice_recordings"
    
    init(apiKey: String) {
        self.apiKey = apiKey
        loadContextMemory()
        print("🤖 AI Service инициализирован с контекстной памятью")
    }
    
    // MARK: - Chat Response Generation
    func generateResponse(for message: String, context: [String]) async throws -> String {
        let systemPrompt = await createSystemPrompt()
        
        // Добавляем сообщение в историю
        let userMessage = AIMessage(role: "user", content: message)
        conversationHistory.append(userMessage)
        
        let request = ChatRequest(
            model: defaultModel,
            messages: [
                AIMessage(role: "system", content: systemPrompt),
                userMessage
            ],
            max_tokens: 1500,
            temperature: 0.7
        )
        
        let response = try await performRequest(request)
        
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
        
        // Сохраняем запись в контекст
        if let audioURL = audioURL {
            await updateContextMemory(key: voiceRecordingsKey, value: audioURL)
        }
        
        let request = ChatRequest(
            model: advancedModel,
            messages: [
                AIMessage(role: "system", content: systemPrompt),
                AIMessage(role: "user", content: "Транскрипция: \(transcript)")
            ],
            max_tokens: 2000,
            temperature: 0.3
        )
        
        let response = try await performRequest(request)
        return await parseVoiceAnalysis(response, transcript: transcript)
    }
    
    // MARK: - Task Creation from Message
    func createTaskFromMessage(_ message: String, context: [String]) async throws -> TaskCreationResult {
        let systemPrompt = await createTaskCreationPrompt()
        
        let request = ChatRequest(
            model: defaultModel,
            messages: [
                AIMessage(role: "system", content: systemPrompt),
                AIMessage(role: "user", content: message)
            ],
            max_tokens: 1500,
            temperature: 0.5
        )
        
        let response = try await performRequest(request)
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
        let address = await getContextValue(for: userAddressKey) as? String ?? "не указан"
        let preferences = await getContextValue(for: userPreferencesKey) as? [String] ?? []
        let taskCount = (await getContextValue(for: taskHistoryKey) as? [String])?.count ?? 0
        
        return """
        Ты - умный AI ассистент для управления задачами и планирования. 
        
        КОНТЕКСТ ПОЛЬЗОВАТЕЛЯ:
        - Адрес: \(address)
        - Предпочтения: \(preferences.joined(separator: ", "))
        - Всего задач создано: \(taskCount)
        
        ИСТОРИЯ РАЗГОВОРА:
        \(conversationHistory.suffix(10).map { "\($0.role): \($0.content)" }.joined(separator: "\n"))
        
        ПРАВИЛА:
        1. Отвечай естественно, как настоящий помощник
        2. Используй контекст для персонализации ответов
        3. Если нужно создать задачу, используй формат: [TASK: название|описание|приоритет|теги|срок|адрес]
        4. Помни все детали из разговора
        5. Будь проактивным и предлагай решения
        """
    }
    
    private func createVoiceAnalysisPrompt() async -> String {
        let address = await getContextValue(for: userAddressKey) as? String ?? "не указан"
        let previousTasks = await getContextValue(for: taskHistoryKey) as? [String] ?? []
        
        return """
        Проанализируй голосовую запись и извлеки из неё задачи.
        
        КОНТЕКСТ:
        - Адрес пользователя: \(address)
        - Предыдущие задачи: \(previousTasks.joined(separator: ", "))
        
        ПРАВИЛА АНАЛИЗА:
        1. Определи ВСЕ упомянутые задачи
        2. Для каждой задачи сгенерируй:
           - Название (краткое и понятное)
           - Описание (детальное, с контекстом)
           - Приоритет (высокий/средний/низкий)
           - Теги (релевантные категории)
           - Срок (если упоминается)
           - Адрес (если не указан, используй контекст)
        3. Используй контекст для уточнения деталей
        4. Если упоминается адрес, обнови контекст
        
        ФОРМАТ ОТВЕТА:
        [TASK: название|описание|приоритет|теги|срок|адрес]
        [TASK: название2|описание2|приоритет2|теги2|срок2|адрес2]
        ...
        
        КОНТЕКСТНЫЕ ОБНОВЛЕНИЯ:
        [CONTEXT: ключ=значение]
        """
    }
    
    private func createTaskCreationPrompt() async -> String {
        let address = await getContextValue(for: userAddressKey) as? String ?? "не указан"
        
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
    
    private func performRequest(_ request: ChatRequest) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw AIError.apiError(errorResponse?.error?.message ?? "Unknown error")
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        return chatResponse.choices.first?.message.content ?? ""
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
            confidence: 0.95,
            audioURL: await getContextValue(for: voiceRecordingsKey) as? URL
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
                confidence: 0.95,
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
        
        // Можно добавить более сложный парсинг дат
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

// MARK: - Models
struct ChatRequest: Codable {
    let model: String
    let messages: [AIMessage]
    let max_tokens: Int
    let temperature: Double
}

struct AIMessage: Codable {
    let role: String
    let content: String
}

struct ChatResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: AIMessage
}

struct ErrorResponse: Codable {
    let error: APIError?
}

struct APIError: Codable {
    let message: String
}

// MARK: - Result Models
struct VoiceAnalysisResult {
    let tasks: [ExtractedTask]
    let summary: String
    let confidence: Double
    let audioURL: URL?
}

struct TaskCreationResult {
    let task: ExtractedTask?
    let message: String
    let success: Bool
}

// MARK: - Errors
enum AIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}
